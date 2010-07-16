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

declare namespace hs="http://marklogic.com/xdmp/status/host"
;

import module namespace sem="http://marklogic.com/semantic"
 at "semantic.xqy";

declare variable $FORESTS as xs:unsignedLong+ := (
  (: use local forests only :)
  let $forest-key := 'http://marklogic.com/semantic/forests'
  let $cached-forests as xs:unsignedLong* := xdmp:get-server-field($forest-key)
  return (
    if (exists($cached-forests)) then $cached-forests
    else (
      xdmp:log(text { 'determining local forests' }),
      let $db-forests as xs:unsignedLong+ := xdmp:database-forests(
        xdmp:database())
      let $host-forests as xs:unsignedLong+ := xdmp:host-status(
        xdmp:host())/hs:assignments/hs:assignment/hs:forest-id
      return xdmp:set-server-field(
        $forest-key, $db-forests[ . = $host-forests ])
    )
  )
);

declare variable $FOREST-COUNT := count($FORESTS)
;

(: map key is forest id, chosen from the local forests.
 : map value is a list of the documents to be inserted.
 :)
declare variable $MAP as map:map := (
  let $m := map:map()
  let $build := (
    for $n in xdmp:unquote(
      xdmp:get-request-field('xml') )/t
    let $forest := local:forest(
      xdmp:hex-to-integer(
        sem:uri-for-tuple($n/s, $n/p, $n/o, $n/c) ) )
    let $key := xs:string($forest)
    return map:put($m, $key, (map:get($m, $key), $n))
  )
  return $m
);

declare function local:forest(
  $uri-key as xs:unsignedLong )
as xs:integer
{
  (: mimic server builtin assignment placing :)
  subsequence(
    $FORESTS,
    1 + (
      let $v := (2047 + $FOREST-COUNT) idiv $FOREST-COUNT
      let $u := xdmp:xor64(0, xdmp:and64(xdmp:lshift64($uri-key, 2), 2047))
      let $u := xdmp:xor64($u, xdmp:and64(xdmp:rshift64($uri-key, 9), 2047))
      let $u := xdmp:xor64($u, xdmp:and64(xdmp:rshift64($uri-key, 20), 2047))
      let $u := xdmp:xor64($u, xdmp:and64(xdmp:rshift64($uri-key, 31), 2047))
      let $u := xdmp:xor64($u, xdmp:and64(xdmp:rshift64($uri-key, 42), 2047))
      let $u := xdmp:xor64($u, xdmp:and64(xdmp:rshift64($uri-key, 53), 2047))
      return $u idiv $v
    ),
    1
  )
};

(: NB - in-forest eval per tuple :)
for $key in map:keys($MAP)
let $forest := xs:unsignedLong($key)
return xdmp:invoke(
  'insert-tuples.xqy',
  (xs:QName('FOREST'), $forest,
    xs:QName('MAP'), $MAP),
    <options xmlns="xdmp:eval">{
      element database { $forest } }</options> )

(: semantic insert.xqy :)
