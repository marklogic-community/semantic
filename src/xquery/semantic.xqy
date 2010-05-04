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
 : library module of semantic functions: FOAF etc
 :
 : @author Michael Blakeley, Mark Logic Corporation
 :)
module namespace sem = "http://marklogic.com/semantic";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare default collation 'http://marklogic.com/collation/codepoint';

declare variable $DEBUG := true()
;

declare variable $SINDICE-FRIEND := 'http://xmlns.com/foaf/0.1/knows'
;

declare variable $SINDICE-FRIEND-HASH := xdmp:hash64($SINDICE-FRIEND)
;

declare private function sem:evq($ln as xs:string+, $v as xs:string+)
  as cts:query
{
   cts:element-value-query(xs:QName($ln), $v, 'exact')
};

declare private function sem:erq($ln as xs:string+, $v as xs:string+)
  as cts:query
{
   cts:element-range-query(xs:QName($ln), '=', $v)
};

declare private function sem:hvq($ln as xs:string+, $v as xs:unsignedLong+)
  as cts:query
{
   cts:element-value-query(xs:QName($ln), xs:QName('h'), $v, 'exact')
};

declare private function sem:hrq($ln as xs:string+, $v as xs:unsignedLong+)
  as cts:query
{
   cts:element-attribute-range-query(xs:QName($ln), xs:QName('h'), '=', $v)
};

declare private function sem:so4sop(
   $s as xs:string+, $p as xs:string+)
  as xs:string*
{
   cts:element-values(
     (xs:QName('o'), xs:QName('s')),
     (),
     (),
   cts:and-query((
     sem:erq(('o', 's'), $s),
     sem:erq('p', $p) ))
  )
};

declare private function sem:o4sp(
   $s as xs:string+, $p as xs:string+)
  as xs:string*
{
   cts:element-values(
     xs:QName('o'),
     (),
     (),
   cts:and-query((
     sem:erq('s', $s),
     sem:erq('p', $p) ))
  )
};

declare private function sem:s4op(
   $s as xs:string+, $p as xs:string+)
  as xs:string*
{
  cts:element-values(
    xs:QName('s'),
    (),
    (),
    cts:and-query((
        sem:erq('o', $s),
        sem:erq('p', $p) ))
  )
};

declare private function sem:s4sp(
   $s as xs:string+, $p as xs:string+)
  as xs:string*
{
  cts:element-values(
    xs:QName('s'),
    (),
    (),
    cts:and-query((
        sem:erq('s', $s),
        sem:erq('p', $p) ))
  )
};

declare private function sem:o4sp-hash(
   $s as xs:unsignedLong+, $p as xs:unsignedLong+)
  as xs:unsignedLong*
{
  cts:element-attribute-values(
    xs:QName('o'),
    xs:QName('h'),
    (),
    (),
   cts:and-query((
        sem:hrq('s', $s),
        sem:hrq('p', $p) ))
  )
};

declare private function sem:so4sop-hash(
   $s as xs:unsignedLong+, $p as xs:unsignedLong+)
 as xs:unsignedLong*
{
  cts:element-attribute-values(
    (xs:QName('o'), xs:QName('s')),
    xs:QName('h'),
    (),
    (),
    cts:and-query((
        sem:hrq(('o', 's'), $s),
        sem:hrq('p', $p) ))
  )
};

declare private function sem:s4sp-hash(
  $s as xs:unsignedLong+, $p as xs:unsignedLong+)
 as xs:unsignedLong*
{
  cts:element-attribute-values(
    xs:QName('s'),
    xs:QName('h'),
    (),
    (),
    cts:and-query((
        sem:hrq('s', $s),
        sem:hrq('p', $p) ))
  )
};

declare function sem:foaf-filter(
  $m as map:map, $candidates as xs:string*,
  $filters as xs:string*, $gen as xs:integer)
 as xs:string*
{
  (: use lexicons to filter :)
  (: are we done yet? :)
  if (empty($candidates)) then ()
  else if (empty($filters)) then (
    if (not($DEBUG)) then ()
    else xdmp:log(text { 'foaf-filter put', $gen, count($candidates) }),
    (: update the map :)
    for $c in $candidates
    where empty(map:get($m, $c))
    return (
      map:put($m, $c, $gen),
      (: yields sequence of filtered candidates from this generation :)
      $c
    )
  )
  else (
    let $this := $filters[1]
    let $rest := subsequence($filters, 2)
    let $next := sem:s4sp($candidates, $this)
    let $d := (
      if (not($DEBUG)) then ()
      else xdmp:log(text {
          'foaf-filter gen', $gen, count($candidates), count($filters) })
    )
    where exists($next)
    return sem:foaf-filter($m, $next, $rest, $gen)
  )
};

declare function sem:foaf(
  $m as map:map, $seeds as xs:string*, $gen as xs:integer,
  $filters as xs:string*)
 as empty-sequence()
{
  if (not($DEBUG)) then ()
  else xdmp:log(text {
      'foaf start of gen', $gen, count($seeds), count(map:keys($m)) }),
  (: apply dummy empty filter, on bootstrap generation only :)
  if (exists(map:keys($m))) then () else (
    let $do := sem:foaf-filter($m, $seeds, (), $gen)
    return ()
  ),
  (: are we done yet? :)
  if ($gen lt 1 or empty($seeds)) then (
    if (not($DEBUG)) then ()
    else xdmp:log(text {
        'foaf end at gen', $gen, count($seeds), count(map:keys($m)) })
  )
  else (
    (: get the next generation of friends :)
    let $new-friends := sem:o4sp($seeds, $SINDICE-FRIEND)
    let $d := (
      if (not($DEBUG)) then ()
      else xdmp:log(text {
        'foaf gen', $gen, count($seeds), 'new', count($new-friends) })
    )
    let $next-gen := $gen - 1
    (: foaf-filter does the map:put, so always call it :)
    let $new-friends := sem:foaf-filter($m, $new-friends, $filters, $next-gen)
    let $d := (
      if (not($DEBUG)) then ()
      else xdmp:log(text {
        'foaf gen', $gen, count($seeds), 'filtered', count($new-friends) })
    )
    where exists($new-friends) and $next-gen gt 0
    return sem:foaf($m, $new-friends, $next-gen, $filters)
  )
};

declare function sem:serialize(
  $m as map:map, $max-gen as xs:integer)
 as item()+
{
  let $keys := map:keys($m)
  let $keys-count := count($keys)
  let $d := (
    if (not($DEBUG)) then ()
    else xdmp:log(text { 'serialize', $max-gen, $keys-count })
  )
  return (
    $keys-count,
    for $k in $keys
    let $gen := $max-gen - map:get($m, $k)
    order by $gen descending, $k
    return text { $gen, $k }
  ),
  if (not($DEBUG)) then ()
  else xdmp:log(text { 'serialize end', $max-gen })
};

declare function sem:hash-decode(
  $ln as xs:string+, $hashes as xs:unsignedLong+)
 as xs:string+
{
  cts:element-values(
    xs:QName($ln),
    (),
    (),
    sem:hrq($ln, $hashes)
  )
};

declare function sem:serialize-hash-simple(
  $m as map:map, $max-gen as xs:integer)
 as item()*
{
  let $keys := map:keys($m)
  let $keys-count := count($keys)
  let $d := (
    if (not($DEBUG)) then ()
    else xdmp:log(text { 'serialize-hash-simple', $keys-count })
  )
  return (
    $keys-count,
    sem:hash-decode('s', xs:unsignedLong($keys))
  ),
  if (not($DEBUG)) then ()
  else xdmp:log(text { 'serialize-hash-simple end', $max-gen })
};

declare function sem:serialize-hash(
  $m as map:map, $max-gen as xs:integer)
 as item()*
{
  let $keys := map:keys($m)
  let $keys-count := count($keys)
  let $d := (
    if (not($DEBUG)) then ()
    else xdmp:log(text { 'serialize-hash', $max-gen, $keys-count })
  )
  return (
    $keys-count,
    let $values := sem:hash-decode('s', xs:unsignedLong($keys))
    for $v in $values
    let $gen := $max-gen - map:get($m, xs:string(xdmp:hash64($v)))
    order by $gen descending, $v
    return text { $gen, $v }
  ),
  if (not($DEBUG)) then ()
  else xdmp:log(text { 'serialize-hash end', $max-gen })
};

declare function sem:foaf-filter-hash(
  $m as map:map, $candidates as xs:unsignedLong*,
  $filters as xs:unsignedLong*, $gen as xs:integer)
 as xs:unsignedLong*
{
  (: use lexicons to filter :)
  (: are we done yet? :)
  if (empty($candidates)) then ()
  else if (empty($filters)) then (
    if (not($DEBUG)) then ()
    else xdmp:log(text { 'foaf-filter put', $gen, count($candidates) }),
    (: update the map :)
    for $c in $candidates
    let $key := string($c)
    where empty(map:get($m, $key))
    return (
      map:put($m, $key, $gen),
      (: yields sequence of filtered candidates from this generation :)
      $c
    )
  )
  else (
    let $this := $filters[1]
    let $rest := subsequence($filters, 2)
    let $next := sem:s4sp-hash($candidates, $this)
    let $d := (
      if (not($DEBUG)) then ()
      else xdmp:log(text {
          'foaf-filter gen', $gen, count($candidates), count($filters) })
    )
    where exists($next)
    return sem:foaf-filter-hash($m, $next, $rest, $gen)
  )
};

declare function sem:foaf-hash(
  $m as map:map, $seeds as xs:unsignedLong*, $gen as xs:integer,
  $filters as xs:unsignedLong*)
 as empty-sequence()
{
  if (not($DEBUG)) then ()
  else xdmp:log(text {
      'foaf start of gen', $gen, count($seeds), count(map:keys($m)) }),
  (: apply dummy empty filter, on bootstrap generation only :)
  if (exists(map:keys($m))) then () else (
    let $do := sem:foaf-filter-hash($m, $seeds, (), $gen)
    return ()
  ),
  (: are we done yet? :)
  if ($gen lt 1 or empty($seeds)) then (
    if (not($DEBUG)) then ()
    else xdmp:log(text {
        'foaf end at gen', $gen, count($seeds), count(map:keys($m)) })
  )
  else (
    (: get the next generation of friends :)
    let $new-friends := sem:o4sp-hash($seeds, $SINDICE-FRIEND-HASH)
    let $d := (
      if (not($DEBUG)) then ()
      else xdmp:log(text {
        'foaf gen', $gen, count($seeds), 'new', count($new-friends) })
    )
    let $next-gen := $gen - 1
    (: foaf-filter does the map:put, so always call it :)
    let $new-friends := sem:foaf-filter-hash(
      $m, $new-friends, $filters, $next-gen)
    let $d := (
      if (not($DEBUG)) then ()
      else xdmp:log(text {
        'foaf gen', $gen, count($seeds), 'filtered', count($new-friends) })
    )
    where exists($new-friends) and $next-gen gt 0
    return sem:foaf-hash($m, $new-friends, $next-gen, $filters)
  )
};

declare function sem:join($p as xs:string+)
 as xs:string*
{
  sem:join(
    for $i in $p
    order by xdmp:hash64($i)
    return $i,
    count($p)
  )
};

declare function sem:join(
  $p as xs:string+, $x as xs:integer)
 as xs:string*
{
  let $this := $p[$x]
  let $d := if (not($DEBUG)) then () else xdmp:log(
    text { $x, $this, count($p), 0 })
  let $matches := cts:element-values(
    (xs:QName('s')),
    (),
    (),
    sem:erq('p', $this)
  )
  return sem:join($p, $x - 1, $matches)
};

declare function sem:join(
  $p as xs:string+, $x as xs:integer, $matches as xs:string*)
 as xs:string*
{
  if ($x lt 1) then $matches
  else if (empty($matches)) then $matches
  else (
    let $this := $p[$x]
    let $d := if (not($DEBUG)) then () else xdmp:log(
      text { $x, $this, count($p), count($matches) } )
    let $matches := cts:element-values(
      (xs:QName('s')),
      (),
      (),
      cts:and-query((
        sem:erq('p', $this),
        sem:erq(('s'), $matches)
      ))
    )
    return sem:join($p, $x - 1, $matches)
  )
};

declare function sem:join-hash($p as xs:string+)
 as xs:string*
{
  sem:join-hash(
    for $i in $p
    order by xdmp:hash64($i)
    return xdmp:hash64($i),
    count($p)
  )
};

declare function sem:join-hash(
  $p as xs:unsignedLong+, $x as xs:integer)
 as xs:string*
{
  let $this := $p[$x]
  let $d := if (not($DEBUG)) then () else xdmp:log(
    text { $x, $this, count($p), 0 })
  let $matches := cts:element-attribute-values(
    xs:QName('s'),
    xs:QName('h'),
    (),
    ('type=unsignedLong'),
    sem:hrq('p', $this)
  )
  let $hashes := sem:join-hash($p, $x - 1, $matches)
  return sem:hash-decode('s', $hashes)
};

declare function sem:join-hash(
  $p as xs:unsignedLong+, $x as xs:integer, $matches as xs:unsignedLong*)
 as xs:unsignedLong*
{
  if ($x lt 1) then $matches
  else if (empty($matches)) then $matches
  else (
    let $this := $p[$x]
    let $d := if (not($DEBUG)) then () else xdmp:log(
      text { $x, $this, count($p), count($matches) } )
    let $matches := cts:element-attribute-values(
      xs:QName('s'),
      xs:QName('h'),
      (),
      ('type=unsignedLong'),
      cts:and-query((
        sem:hrq('p', $this),
        sem:hrq(('s'), $matches)
      ))
    )
    return sem:join-hash($p, $x - 1, $matches)
  )
};

(: semantic.xqy :)