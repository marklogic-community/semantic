/**
 * Copyright (c)2009-2010 Mark Logic Corporation
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * The use of the Apache License does not indicate that this project is
 * affiliated with the Apache Software Foundation.
 */
package com.marklogic.semantic;

import java.io.BufferedReader;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.UnsupportedEncodingException;
import java.math.BigDecimal;
import java.net.Authenticator;
import java.net.ConnectException;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.PasswordAuthentication;
import java.net.ProtocolException;
import java.net.URI;
import java.net.URL;
import java.net.URLEncoder;
import java.util.Arrays;
import java.util.regex.Pattern;

import org.semanticweb.yars.nx.Node;
import org.semanticweb.yars.nx.parser.NxParser;

import com.marklogic.ps.Utilities;
import com.marklogic.ps.timing.TimedEvent;
import com.marklogic.recordloader.AbstractLoader;
import com.marklogic.recordloader.Configuration;
import com.marklogic.recordloader.FatalException;
import com.marklogic.recordloader.LoaderException;

/**
 * Copyright (c) 2009 Mark Logic Corporation. All rights reserved.
 */

/**
 * @author Michael Blakeley, Mark Logic Corporation
 *
 */
public class NQuadLoader extends AbstractLoader {

    /*
     * An EBNF grammar for N-Quads documents can be derived from the N-Triples
     * grammar by replacing the triple production with a new contextTriple
     * production
     */
    // contextTriple ::= subject predicate object context?
    // context ::= uriref | nodeID | literal

    /**
     *
     */
    private static final int OBJECT = 2;

    private boolean detectDecimal = false;

    static String[] names = new String[] { "s", "p", "o", "c" };

    boolean authenticatorIsIntialized = false;

    private Pattern decimalPattern;

    private long count = 0;

    public void process() throws LoaderException {
        super.process();

        // TODO: should come from config
        int batchSize = 10;
        String[] tuples = new String[batchSize];
        int tupleCount = 0;

        decimalPattern = Pattern.compile("^\\d*\\.?\\d+$");
        NxParser nxp;
        try {
            nxp = new NxParser(input, false);
            TimedEvent te = null;
            while (nxp.hasNext()) {
                te = new TimedEvent();
                tuples[tupleCount] = processNext(nxp.next());
                tupleCount++;
                if (tupleCount >= tuples.length) {
                    logger.fine("batch complete");
                    // send these tuples to the database
                    try {
                        count += tupleCount;
                        insert(tuples, te);
                    } catch (UnsupportedEncodingException e) {
                        if (config.isFatalErrors()) {
                            throw e;
                        }
                        logger.logException("non-fatal", e);
                    } catch (LoaderException e) {
                        if (config.isFatalErrors()) {
                            throw e;
                        }
                        logger.logException("non-fatal", e);
                    }

                    // and create a new array
                    tupleCount = 0;
                    tuples = new String[tuples.length];
                }
            }

            // insert any pending tuples
            if (tupleCount > 0) {
                logger.info("cleaning up " + tupleCount);
                tuples = Arrays.copyOf(tuples, tupleCount);
                count += tupleCount;
                // no try-catch, because we're done anyhow
                insert(tuples, (null == te ? new TimedEvent() : te));
            }

        } catch (IOException e) {
            throw new LoaderException(e);
        }

    }

    /**
     * @param ns
     * @return
     */
    private String processNext(Node[] ns) {
        Node n;
        String name;
        String value = null;
        boolean isDecimal = false;

        // optionally detect range values in the object
        if (detectDecimal) {
            value = ns[OBJECT].toString();
            isDecimal = decimalPattern.matcher(value).matches();
        }

        StringBuilder xml = new StringBuilder("<q>");
        for (int i = 0; i < ns.length; i++) {
            n = ns[i];
            name = names[i];
            xml.append("<").append(name);
            if (detectDecimal && isDecimal && OBJECT == i) {
                xml.append(" dec=\"1\"");
            }
            xml.append(">").append(Utilities.escapeXml(n.toString()))
                    .append("</").append(name).append(">");
        }

        if (detectDecimal && isDecimal) {
            // name the new element after the predicate
            name = ns[1].toString();
            xml.append("<dec xmlns=\"").append(name).append("\">")
                    .append(new BigDecimal(value).toPlainString())
                    .append("</dec>");
        }
        xml.append("</q>\n");

        return xml.toString();
    }

    /**
     * @param urlString
     * @param body
     * @return
     * @throws ActionException
     */
    protected void doRequest(String urlString, String body)
            throws LoaderException {
        URL url;
        HttpURLConnection conn = null;
        logger.fine("url " + urlString);
        try {
            url = new URL(urlString);
            initializeAuthenticator(url);
            conn = (HttpURLConnection) url.openConnection();
            doRequest(body, conn);
            return;
        } catch (FileNotFoundException e) {
            // HTTP error
            try {
                if (null != conn) {
                    StringBuilder sb = new StringBuilder();
                    Utilities.read(new InputStreamReader(conn
                            .getErrorStream()), sb);
                    logger.warning("server responded with: "
                            + sb.toString());
                }
                throw new LoaderException(urlString
                        + ": "
                        + ((null == conn) ? "null" : conn
                                .getResponseMessage()), e);
            } catch (IOException e1) {
                // now we are really in trouble
                throw new FatalException(e1);
            }
        } catch (MalformedURLException e) {
            throw new FatalException(urlString, e);
        } catch (IOException e) {
            throw new LoaderException(e + ": " + urlString, e);
        } finally {
            if (null != conn) {
                conn.disconnect();
            }
        }
    }

    /**
     * @param body
     * @param conn
     * @return
     * @throws ProtocolException
     * @throws IOException
     */
    private void doRequest(String body, HttpURLConnection conn)
            throws ProtocolException, IOException {
        OutputStreamWriter osw = null;
        try {
            conn.setUseCaches(false);
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type",
                    "application/x-www-form-urlencoded");
            // use keep-alive to reduce open sockets
            conn.setRequestProperty("Connection", "keep-alive");
            conn.setDoOutput(true);
            osw = new OutputStreamWriter(conn.getOutputStream());
            osw.write(body);
            osw.flush();

            BufferedReader in = new BufferedReader(new InputStreamReader(
                    conn.getInputStream()));
            String line;
            while ((line = in.readLine()) != null) {
                System.out.println(line);
            }
            in.close();
        } finally {
            if (null != osw) {
                try {
                    osw.close();
                } catch (IOException e) {
                    logger.logException(e);
                }
            }
        }
    }

    /**
     * @param url
     */
    private void initializeAuthenticator(URL url) {
        if (authenticatorIsIntialized) {
            return;
        }
        final String[] auth = url.getAuthority().split("@")[0].split(":");
        Authenticator.setDefault(new Authenticator() {
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(auth[0], auth[1]
                        .toCharArray());
            }
        });
        authenticatorIsIntialized = true;
    }

    /**
     * @param tuples
     * @param _event
     * @throws LoaderException
     * @throws UnsupportedEncodingException
     */
    private void insert(String[] tuples, TimedEvent _event)
            throws LoaderException, UnsupportedEncodingException {
        StringBuilder body = new StringBuilder();
        for (int i = 0; i < tuples.length; i++) {
            body.append((0 == i) ? "" : "&").append("xml=").append(
                    URLEncoder.encode(tuples[i], "UTF-8"));
        }
        // TODO: move into Content subclass with body bytes?
        _event.increment(body.length());
        // if multiple connString are available, we round-robin
        URI[] connectionStrings = config.getConnectionStrings();
        // retry loop
        int tries = 0;
        int maxTries = 10;
        long sleepMillis = Configuration.SLEEP_TIME;
        String label = Thread.currentThread().getName() + "=" + count;
        while (tries < maxTries) {
            // retry will get a different server, if available
            // count will generally be an even multiple of batchSize, so...
            int x = (int) (((tries + count) / connectionStrings.length)
                           % connectionStrings.length);
            try {
                doRequest(connectionStrings[x].toString(), body
                        .toString());
                break;
            } catch (LoaderException e) {
                if (tries < maxTries
                        && e.getCause() instanceof ConnectException) {
                    logger.warning("retry " + tries);
                    Thread.yield();
                    try {
                        Thread.sleep(sleepMillis);
                    } catch (InterruptedException e1) {
                        logger.warning("interrupted: " + e1.getMessage());
                    }
                    tries++;
                    sleepMillis = 2 * sleepMillis;
                    continue;
                }
                // no retries left, or the error wasn't a connection error
                _event.setError(true);
                monitor.add(label, _event);
                logger.warning("failed to insert tuples (" + label + "):"
                        + e.getMessage() + "; " + body.toString());
                throw e;
            }
        }
        monitor.add(label, _event);
        Thread.yield();
    }
}
