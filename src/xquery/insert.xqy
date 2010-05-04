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
 : semantic insert.xqy
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :)

let $skip-existing := true()
let $map := map:map()
let $build := (
  for $xml in xdmp:get-request-field('xml')
  let $n as element(quad) := xdmp:unquote($xml)/quad
  let $key := string(
    xdmp:hash64(
      string-join(
        (: I want these elements to be in order, for deterministic uris :)
        ($n/subject, $n/predicate, $n/object, $n/context), '|')))
  where empty(map:get($map, $key))
  return map:put($map, $key, $n)
)
let $keys := map:keys($map)
let $forests := xdmp:database-forests(xdmp:database())
let $index := 1 + xs:unsignedLong($keys[1]) mod count($forests)
let $forest := subsequence($forests, $index, 1)
for $key in $keys
let $uri := xdmp:integer-to-hex(xs:unsignedLong($key))
where not($skip-existing) or empty(doc($uri))
return xdmp:document-insert(
  $uri,
  map:get($map, $key),
  xdmp:default-permissions(),
  xdmp:default-collections(),
  0,
  $forest
)

(: semantic insert.xqy :)
