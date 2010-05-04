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
 : foaf example module
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :)
import module namespace sem="http://marklogic.com/semantic"
 at "semantic.xqy";

let $seeds as xs:string+ := xdmp:get-request-field('seed')
let $filters as xs:string* := xdmp:get-request-field('filter')
let $use-hash as xs:boolean := xs:boolean(
  xdmp:get-request-field('hash', '1') )
let $gen as xs:integer := xs:integer(
  xdmp:get-request-field('gen', '6'))
let $m := map:map()
let $do := (
  if (not($use-hash)) then sem:foaf($m, $seeds, $gen, $filters)
  else sem:foaf-hash(
    $m,
    for $i in xdmp:hash64($seeds)
    order by $i
    return $i,
    $gen,
    for $i in xdmp:hash64($filters)
    order by $i
    return $i
  )
)
return count(map:keys($m))