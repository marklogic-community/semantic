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

import java.net.URI;

import com.marklogic.recordloader.Configuration;
import com.marklogic.recordloader.ContentInterface;
import com.marklogic.recordloader.LoaderException;

/**
 * @author Michael Blakeley, Mark Logic Corporation
 * 
 *         This is a dummy class - NQuadLoader doesn't use it.
 * 
 */
public class ContentFactory implements
        com.marklogic.recordloader.ContentFactory {

    /*
     * (non-Javadoc)
     * 
     * @see com.marklogic.recordloader.ContentFactory#close()
     */
    public void close() {
        // unused
    }

    /*
     * (non-Javadoc)
     * 
     * @see com.marklogic.recordloader.ContentFactory#getVersionString()
     */
    public String getVersionString() {
        return "n/a";
    }

    /*
     * (non-Javadoc)
     * 
     * @see
     * com.marklogic.recordloader.ContentFactory#newContent(java.lang.String)
     */
    @SuppressWarnings("unused")
    public ContentInterface newContent(String uri) throws LoaderException {
        // unused
        return null;
    }

    /*
     * (non-Javadoc)
     * 
     * @see
     * com.marklogic.recordloader.ContentFactory#setConfiguration(com.marklogic
     * .recordloader.Configuration)
     */
    @SuppressWarnings("unused")
    public void setConfiguration(Configuration configuration)
            throws LoaderException {
        // unused
    }

    /*
     * (non-Javadoc)
     * 
     * @see
     * com.marklogic.recordloader.ContentFactory#setConnectionUri(java.net.URI)
     */
    @SuppressWarnings("unused")
    public void setConnectionUri(URI uri) throws LoaderException {
        // unused
    }

    /*
     * (non-Javadoc)
     * 
     * @see
     * com.marklogic.recordloader.ContentFactory#setFileBasename(java.lang.String
     * )
     */
    @SuppressWarnings("unused")
    public void setFileBasename(String name) throws LoaderException {
        // unused
    }

}
