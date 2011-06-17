xquery version "1.0-ml";

(:
 : Copyright (c)2009-2011 Mark Logic Corporation
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
 : foaf example module
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :)
import module namespace sem="http://marklogic.com/semantic"
 at "semantic.xqy";

declare variable $SINDICE-FRIEND := 'http://xmlns.com/foaf/0.1/knows'
;

declare variable $SINDICE-FRIEND-HASH := xdmp:hash64($SINDICE-FRIEND)
;

let $seeds as xs:string+ := xdmp:get-request-field('seed')
let $filters as xs:string* := xdmp:get-request-field('filter')
let $gen as xs:integer := xs:integer(
  xdmp:get-request-field('gen', '6'))
let $m := map:map()
let $do := sem:transitive-closure(
  $m, $seeds, $gen, $SINDICE-FRIEND, true(), $filters)
return count(map:keys($m))
