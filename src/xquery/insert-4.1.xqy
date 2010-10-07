xquery version "1.0-ml";
(:
 : Copyright (c)2009-2010 Mark Logic Corporation
 :
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 : http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :
 : The use of the Apache License does not indicate that this project is
 : affiliated with the Apache Software Foundation.
 :
 : semantic insert-4.1.xqy
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :)

declare namespace hs="http://marklogic.com/xdmp/status/host"
;

import module namespace sem="http://marklogic.com/semantic"
 at "semantic.xqy";

sem:tuple-insert(
  xdmp:unquote(
    xdmp:get-request-field('xml') )/t )

(: semantic insert-4.1.xqy :)
