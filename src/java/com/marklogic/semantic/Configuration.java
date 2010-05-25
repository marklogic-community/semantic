/**
 * Copyright (c) 2010 Mark Logic Corporation. All rights reserved.
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

/**
 * @author Michael Blakeley, Mark Logic Corporation
 * 
 */
public class Configuration extends
        com.marklogic.recordloader.Configuration {

    public static final String BATCH_SIZE_KEY = "BATCH_SIZE";

    public static final String BATCH_SIZE_DEFAULT = "" + 1;

    public static final String DUPLICATE_FILTER_LIMIT_KEY = "DUPLICATE_FILTER_LIMIT";

    /**
     * limit the memory utilization for duplicate filtering to 500,000 entries,
     * or roughly 128-MB.
     */
    public static final String DUPLICATE_FILTER_LIMIT_DEFAULT = "" + 500 * 1000;

    @Override
    public void configure() {
        super.configure();

        // subclass-specific options
        logger.info("configuring semantic-specific options");
        properties.setProperty(CONTENT_FACTORY_CLASSNAME_KEY,
                ContentFactory.class.getCanonicalName());
        properties.setProperty(LOADER_CLASSNAME_KEY, NQuadLoader.class
                .getCanonicalName());
    }

    /**
     * @return
     */
    public int getDuplicateFilterLimit() {
        return Integer.parseInt(properties
                .getProperty(DUPLICATE_FILTER_LIMIT_KEY));
    }

    /**
     * @return
     */
    public int getBatchSize() {
        return Integer.parseInt(properties.getProperty(BATCH_SIZE_KEY));
    }
}
