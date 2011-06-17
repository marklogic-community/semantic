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
 : semantic insert-property.xqy
 :
 : This variant uses so-called "naked" properties, rather than documents.
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :)

let $skip-existing := true()
let $map := map:map()
let $build := (
  for $xml in xdmp:get-request-field('xml')
  let $n as element(t) := xdmp:unquote($xml)/t
  let $uri := xdmp:integer-to-hex(
    xdmp:hash64(
      string-join(
        (: keep these elements to be in order, for deterministic uris :)
        ($n/s, $n/p, $n/o, $n/c), '|')))
  where empty(map:get($map, $uri)) and (
    not($skip-existing) or empty(xdmp:document-properties($uri)) )
  return map:put(
    $map, $uri, element t {
      $n/@*,
      for $n in $n/node()
      return typeswitch($n)
      case element() return element { node-name($n) } {
        attribute h { xdmp:hash64($n) },
        $n/node() }
      default return $n
      } )
)
for $uri in map:keys($map)
return xdmp:document-set-properties(
  $uri,
  map:get($map, $uri)/*
)

(: semantic insert-property.xqy :)
