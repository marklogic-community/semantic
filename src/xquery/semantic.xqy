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
 : library module of semantic functions
 :
 : @author Michael Blakeley, Mark Logic Corporation
 : @author Hsiao Su, Mark Logic Corporation
 : @author Li Ding 
 :)

module namespace sem = "http://marklogic.com/semantic";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare default collation 'http://marklogic.com/collation/codepoint';

declare variable $sem:DEBUG := false()
;

declare variable $sem:LEXICON-OPTIONS := (
  'any'
);

declare variable $sem:QN-S := xs:QName('s')
;

declare variable $sem:QN-O := xs:QName('o')
;

declare variable $sem:QN-P := xs:QName('p')
;

declare variable $sem:QN-C := xs:QName('c')
;

declare variable $sem:O-OWL-CLASS :=
'http://www.w3.org/2002/07/owl#Class'
;

declare variable $sem:O-OWL-OBJECT-PROPERTY :=
'http://www.w3.org/2002/07/owl#ObjectProperty'
;

declare variable $sem:O-RDF-NIL :=
'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil'
;

declare variable $sem:P-OWL-INTERSECTION :=
'http://www.w3.org/2002/07/owl#intersectionOf'
;

declare variable $sem:P-OWL-ON-PROPERTY :=
'http://www.w3.org/2002/07/owl#onProperty'
;

declare variable $sem:P-RDF-FIRST :=
'http://www.w3.org/1999/02/22-rdf-syntax-ns#first'
;

declare variable $sem:P-RDF-LABEL :=
'http://www.w3.org/2000/01/rdf-schema#label'
;

declare variable $sem:P-RDF-REST :=
'http://www.w3.org/1999/02/22-rdf-syntax-ns#rest'
;

declare variable $sem:P-RDF-SUBCLASS :=
'http://www.w3.org/2000/01/rdf-schema#subClassOf'
;

declare variable $sem:P-RDF-SUBPROPERTY :=
'http://www.w3.org/2000/01/rdf-schema#subPropertyOf'
;

declare variable $sem:P-RDF-TYPE :=
'http://www.w3.org/1999/02/22-rdf-syntax-ns#type'
;

(: RangeQuery - returns a cts:element-range-query with the equal operator between $qn and $v :)
declare private function sem:rq(
  $qn as xs:QName+, $v as xs:string+)
as cts:query
{
  cts:element-range-query($qn, '=', $v)
};

(: EValuate - evaluates $query using cts:element-values and return qualified names specified in $qn from matching documents :)
declare private function sem:ev(
  $qn as xs:QName+, $query as cts:query)
as xs:string*
{
  if (not($sem:DEBUG)) then ()
  else xdmp:log(text { 'sem:ev', xdmp:describe($qn), xdmp:quote($query) })
  ,
  cts:element-values(
    $qn, (), $sem:LEXICON-OPTIONS, $query)
};

(: PredicateQuery - returns a cts:query that matches predicates in $p :)
declare private function sem:pq(
  $p as xs:string+)
 as cts:query
{
  sem:rq($sem:QN-P, $p)
};

(: ObjectQuery - returns a cts:query that matches objects in $o :)
declare private function sem:oq(
  $o as xs:string+)
 as cts:query
{
  sem:rq($sem:QN-O, $o)
};

(: SubjectQuery - returns a cts:query that matches subjects in $s :)
declare private function sem:sq(
  $s as xs:string+)
 as cts:query
{
  sem:rq($sem:QN-S, $s)
};

(: ObjectPredicateQuery - returns a cts:query that matches objects in $o and predicates in $p:)
declare private function sem:opq(
  $o as xs:string+, $p as xs:string+)
 as cts:query
{
  cts:and-query((sem:rq($sem:QN-O, $o), sem:pq($p)))
};

(: SubjectPredicateQuery - returns a cts:query that matches subjects in $s and predicates in $p:)
declare private function sem:spq(
  $s as xs:string+, $p as xs:string+)
 as cts:query
{
  cts:and-query((sem:rq($sem:QN-S, $s), sem:pq($p)))
};

(: SubjectObjectPredicateQuery - returns a cts:query that matches subjects in $s, objects in $o, and predicates in $p:)
declare private function sem:sopq(
  $s as xs:string+, $o as xs:string+, $p as xs:string+)
 as cts:query
{
  cts:and-query((sem:rq($sem:QN-S, $s), sem:rq($sem:QN-O, $o), sem:pq($p)))
};

(: returns objects that matches predicates in $p :) 
declare function sem:object-for-predicate(
  $p as xs:string+)
as xs:string*
{
  if (empty($p)) then ()
  else sem:ev($sem:QN-O, sem:pq($p))
};

(: returns subjects that matches predicates in $p :) 
declare function sem:subject-for-predicate(
  $p as xs:string+)
as xs:string*
{
  if (empty($p)) then ()
  else sem:ev($sem:QN-S, sem:pq($p))
};

(: returns objects that matches subjects in $s, and predicates in $p :) 
declare function sem:object-for-object-predicate(
  $s as xs:string*, $p as xs:string+)
as xs:string*
{
  if (empty($s)) then ()
  else sem:ev($sem:QN-O, sem:opq($s, $p))
};

(: returns objects that matches subjects in $s and predicates in $p :)
declare function sem:object-for-subject-predicate(
  $s as xs:string*, $p as xs:string+)
as xs:string*
{
  if (empty($s)) then ()
  else sem:ev($sem:QN-O, sem:spq($s, $p))
};

(: returns subjects that matches objects in $o and predicates in $p :)
declare function sem:subject-for-object-predicate(
   $o as xs:string*, $p as xs:string+)
as xs:string*
{
  if (not($sem:DEBUG)) then ()
  else xdmp:log(text { 'sem:subject-for-object-predicate', $o, $p })
  ,
  if (empty($o)) then ()
  else sem:ev($sem:QN-S, sem:opq($o, $p))
};

(: returns subjects that matches subjects in $s and predicates in $p :)
declare function sem:subject-for-subject-predicate(
   $s as xs:string*, $p as xs:string+)
as xs:string*
{
  if (empty($s)) then ()
  else sem:ev($sem:QN-S, sem:spq($s, $p))
};

(: returns objects that matches subjects in $s, objects in $o, and predicates in $p :)
declare function sem:object-by-subject-object-predicate(
  $s as xs:string+,
  $o as xs:string+,
  $p as xs:string+)
as xs:string*
{
  sem:ev($sem:QN-O, sem:sopq($s, $o, $p))
};

(: returns subjects that matches subjects in $s, objects in $o, and predicates in $p :)
declare function sem:subject-by-subject-object-predicate(
  $s as xs:string+,
  $o as xs:string+,
  $p as xs:string+)
as xs:string*
{
  sem:ev($sem:QN-S, sem:sopq($s, $o, $p))
};

(:
Take the list of $candidates, and filter them through $filters
(predicates).  Filters are applied as AND-conditions.  Candidates that
pass all filters are stored inside the map $m, with the key =
candidate, and value = $gen.
:)
declare private function sem:transitive-closure-filter(
  $m as map:map, $candidates as xs:string*,
  $filters as xs:string*, $gen as xs:integer)
 as xs:string*
{
  (: use lexicons to filter :)
  (: are we done yet? :)
  if (empty($candidates)) then ()
  else if (empty($filters)) then (
    if (not($sem:DEBUG)) then ()
    else xdmp:log(text {
        'transitive-closure-filter put', $gen, count($candidates) }),
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
    let $next := sem:subject-for-subject-predicate($candidates, $this)
    let $d := (
      if (not($sem:DEBUG)) then ()
      else xdmp:log(text {
          'transitive-closure-filter gen',
          $gen, count($candidates), count($filters) })
    )
    where exists($next)
    return sem:transitive-closure-filter($m, $next, $rest, $gen)
  )
};

(:
 Find the transitive-closure, starting from $seeds, using $relation as the predicate for traversing edges.  
 $m - This is used to store filtered results, where key = name, value = generation count
 $seeds     - This stores unfiltered results, and it's used recursively for finding the next generation of friends
 $gen       - An integer for counting generations
 $relation  - the predicate used for finding relationships
 $direction - If true, we traverse from subject to object.  If false, we traverse from object to subject
 $filter    - Used to filter out results.  Note that filter only essentially apply to the end result.  
              Friends that match the filter is still used to find the next generation of friends.
:)
declare function sem:transitive-closure(
  $m as map:map, $seeds as xs:string*, $gen as xs:integer,
  $relation as xs:string, $direction as xs:boolean, $filters as xs:string*)
 as empty-sequence()
{
  if (not($sem:DEBUG)) then ()
  else xdmp:log(text {
      'transitive-closure start of gen',
      $gen, count($seeds), count(map:keys($m)) }),
  (: apply dummy empty filter, on bootstrap generation only :)
  if (exists(map:keys($m))) then () else (
    let $do := sem:transitive-closure-filter($m, $seeds, (), $gen)
    return ()
  ),
  (: are we done yet? :)
  if ($gen lt 1 or empty($seeds)) then (
    if (not($sem:DEBUG)) then ()
    else xdmp:log(text {
        'transitive-closure end at gen',
        $gen, count($seeds), count(map:keys($m)) })
  )
  else (
    (: get the next generation of friends :)
    let $new-friends := (
      if ($direction) then sem:object-for-subject-predicate($seeds, $relation)
      else sem:subject-for-object-predicate($seeds, $relation)
    )
    let $d := (
      if (not($sem:DEBUG)) then ()
      else xdmp:log(text {
        'transitive-closure gen',
          $gen, count($seeds), 'new', count($new-friends) })
    )
    let $next-gen := $gen - 1
    (: transitive-closure-filter does the map:put, so always call it :)
    let $new-friends := sem:transitive-closure-filter(
      $m, $new-friends, $filters, $next-gen)
    let $d := (
      if (not($sem:DEBUG)) then ()
      else xdmp:log(text {
          'transitive-closure gen',
          $gen, count($seeds), 'filtered', count($new-friends) })
    )
    where exists($new-friends) and $next-gen gt 0
    return sem:transitive-closure(
      $m, $new-friends, $next-gen, $relation, $direction, $filters)
  )
};

declare function sem:serialize(
  $m as map:map, $max-gen as xs:integer)
 as item()+
{
  let $keys := map:keys($m)
  let $keys-count := count($keys)
  let $d := (
    if (not($sem:DEBUG)) then ()
    else xdmp:log(text { 'serialize', $max-gen, $keys-count })
  )
  return (
    $keys-count,
    for $k in $keys
    let $gen := $max-gen - map:get($m, $k)
    order by $gen descending, $k
    return text { $gen, $k }
  ),
  if (not($sem:DEBUG)) then ()
  else xdmp:log(text { 'serialize end', $max-gen })
};

(: 
returns a sem:join element that joins objects in $o and predicates in
$p, sem:join is used in *-for-join functions
:)
declare function sem:object-predicate-join(
  $o as xs:string*,
  $p as xs:string* )
 as element(sem:join)?
{
  if (empty($p) and empty($o)) then ()
  else element sem:join {
    for $i in $p return element sem:p { $i },
    for $i in $o return element sem:o { $i } }
};

(: 
returns a sem:join element that joins predicates in $p, sem:join is
used in *-for-join functions
:)
declare function sem:predicate-join(
  $p as xs:string* )
 as element(sem:join)?
{
  if (empty($p)) then ()
  else element sem:join {
    for $i in $p return element sem:p { $i } }
};

(: 
returns a sem:join element that joins subjects in $s and predicates in
$p, sem:join is used in *-for-join functions
:)
declare function sem:subject-predicate-join(
  $s as xs:string*,
  $p as xs:string* )
 as element(sem:join)?
{
  if (empty($s) and empty($p)) then ()
  else element sem:join {
    for $i in $s return element sem:s { $i },
    for $i in $p return element sem:p { $i } }
};

(: 
returns a sem:join element that joins objects in $type and predicates
in $sem:P-RDF-TYPE
:)
declare function sem:type-join(
  $type as xs:string+)
as element(sem:join)
{
  sem:object-predicate-join($type, $sem:P-RDF-TYPE)
};

(: returns objects that matches the sem:join conditions in $joins :)
(: substitute function calls for flwor, to maintain streaming :)
declare function sem:object-for-join(
  $joins as element(sem:join)+)
 as xs:string*
{
  if (not($sem:DEBUG)) then ()
  else xdmp:log(text { 'sem:object-for-join', count($joins) })
  ,
  if (count($joins, 2) gt 1) then sem:object-for-join(
    sem:object-for-join($joins[1]),
    subsequence($joins, 2) )
  (: single join :)
  else if ($joins/sem:o) then sem:object-for-object-predicate(
      $joins/sem:o, $joins/sem:p)
  else if ($joins/sem:s) then sem:object-for-subject-predicate(
      $joins/sem:s, $joins/sem:p)
  else if ($joins/sem:select) then (
    if ($joins/sem:select/@type
      eq 'subject') then sem:object-for-subject-predicate(
      sem:select($joins/sem:select), $joins/sem:p)
    else if ($joins/sem:select/@type
      eq 'object') then sem:object-for-object-predicate(
      sem:select($joins/sem:select), $joins/sem:p)
    else error(
      (), 'SEM-UNEXPECTED', text {
        'select type must be subject or object' })
  )
  (: TODO handle other join cases? :)
  else error(
    (), 'SEM-UNEXPECTED',
    text { 'cannot join without object-predicate or subject-predicate' })
};

(: returns objects that matches the sem:join conditions in $joins, search is limited to triples that match elements in $seeds :)
(: substitute function calls for flwor, to maintain streaming :)
declare function sem:object-for-join(
  $seeds as xs:string*,
  $joins as element(sem:join)* )
 as xs:string*
{
  if (not($sem:DEBUG)) then ()
  else xdmp:log(text {
      'sem:object-for-join', count($seeds), count($joins) })
  ,
  if (empty($seeds) or empty($joins)) then $seeds
  else sem:object-for-join($seeds, $joins[1], subsequence($joins, 2))
};


(: 
returns objects that matches the sem:join conditions in $first, and
then $joins, search is limited to triples that match elements in
$seeds
:)
declare private function sem:object-for-join(
  $seeds as xs:string*,
  $first as element(sem:join),
  $joins as element(sem:join)* )
 as xs:string*
{
  sem:object-for-join(
    $seeds, $first/sem:s, $first/sem:o, $first/sem:p, $joins)
};

(: 
returns objects that matches subjects in $s, objects in $o, predicates
in $p, and then $joins.  Search is limited to triples that match
element in $seeds.

Note: It's unclear what is the correct return value if all 3 $s, $o,
and $p are specified.  But it seems that if $o and $p are specified,
then $seeds has to be a subject.  If $s and $p are specified, then
$seeds have to be an object.
:)
declare private function sem:object-for-join(
  $seeds as xs:string*,
  $s as xs:string*,
  $o as xs:string*,
  $p as xs:string*,
  $joins as element(sem:join)* )
 as xs:string*
{
  sem:object-for-join(
    if ($o and $p) then sem:subject-by-subject-object-predicate(
      $seeds, $o, $p)
    (: seeds will be objects for the relation :)
    else if ($s and $p) then sem:object-by-subject-object-predicate(
      $s, $seeds, $p)
    (: TODO handle other join cases? :)
    else error(
      (), 'SEM-UNEXPECTED',
      text { 'cannot join without object-predicate or subject-predicate' })
    ,
    $joins
  )
};

(: Same as object-for-join, except this returns objects instead of subjects :)
(: substitute function calls for flwor, to maintain streaming :)
declare function sem:subject-for-join(
  $joins as element(sem:join)+)
 as xs:string*
{
  if (not($sem:DEBUG)) then ()
  else xdmp:log(text { 'sem:subject-for-join', count($joins) })
  ,
  if (count($joins, 2) gt 1) then sem:subject-for-join(
    sem:subject-for-join($joins[1]),
    subsequence($joins, 2) )
  (: single join :)
  else if ($joins/sem:o) then sem:subject-for-object-predicate(
      $joins/sem:o, $joins/sem:p)
  else if ($joins/sem:s) then sem:subject-for-subject-predicate(
      $joins/sem:s, $joins/sem:p)
  else if ($joins/sem:select) then (
    if ($joins/sem:select/@type
      eq 'subject') then sem:subject-for-subject-predicate(
      sem:select($joins/sem:select), $joins/sem:p)
    else if ($joins/sem:select/@type
      eq 'object') then sem:subject-for-object-predicate(
      sem:select($joins/sem:select), $joins/sem:p)
    else error(
      (), 'SEM-UNEXPECTED', text {
        'select type must be subject or object' })
  )
  (: TODO handle other join cases? :)
  else error(
    (), 'SEM-UNEXPECTED',
    text { 'cannot join without object-predicate or subject-predicate' })
};

(: Same as object-for-join, except this returns objects instead of subjects :)
(: substitute function calls for flwor, to maintain streaming :)
declare function sem:subject-for-join(
  $seeds as xs:string*,
  $joins as element(sem:join)* )
 as xs:string*
{
  if (not($sem:DEBUG)) then ()
  else xdmp:log(text {
      'sem:subject-for-join', count($seeds), count($joins) })
  ,
  if (empty($seeds) or empty($joins)) then $seeds
  else sem:subject-for-join($seeds, $joins[1], subsequence($joins, 2))
};


(: Same as object-for-join, except this returns objects instead of subjects :)
declare private function sem:subject-for-join(
  $seeds as xs:string*,
  $first as element(sem:join),
  $joins as element(sem:join)* )
 as xs:string*
{
  sem:subject-for-join(
    $seeds, $first/sem:s, $first/sem:o, $first/sem:p, $joins)
};

(: Same as object-for-join, except this returns objects instead of subjects :)
declare private function sem:subject-for-join(
  $seeds as xs:string*,
  $s as xs:string*,
  $o as xs:string*,
  $p as xs:string*,
  $joins as element(sem:join)* )
 as xs:string*
{
  sem:subject-for-join(
    if ($o and $p) then sem:subject-by-subject-object-predicate(
      $seeds, $o, $p)
    (: seeds will be objects for the relation :)
    else if ($s and $p) then sem:object-by-subject-object-predicate(
      $s, $seeds, $p)
    (: TODO handle other join cases? :)
    else error(
      (), 'SEM-UNEXPECTED',
      text { 'cannot join without object-predicate or subject-predicate' })
    ,
    $joins
  )
};

declare function sem:owl-on-property(
  $prop as xs:string*)
as xs:string*
{
  if (empty($prop)) then () else
  sem:subject-for-object-predicate($prop, $sem:P-OWL-ON-PROPERTY)
};

declare function sem:owl-subclasses(
  $class as xs:string*)
as xs:string*
{
  if (empty($class)) then () else
  sem:rdf-subclasses((
      sem:subject-for-object-predicate(
        sem:subject-for-object-predicate($class, $sem:P-RDF-FIRST),
        $sem:P-OWL-INTERSECTION ),
      sem:owl-subclasses-implicit($class) ))
};

declare private function sem:owl-subclasses-implicit(
  $class as xs:string*)
as xs:string*
{
  $class,
  let $inter := sem:object-for-subject-predicate(
    $class, $sem:P-OWL-INTERSECTION)
  let $req-1 := sem:object-for-subject-predicate($inter, $sem:P-RDF-FIRST)
  let $req-2 := sem:object-for-subject-predicate($inter, $sem:P-RDF-REST)
  let $req-2 := sem:subject-for-join(
    $req-2, (sem:object-predicate-join($sem:O-RDF-NIL, $sem:P-RDF-REST)) )
  let $req-2 := sem:object-for-subject-predicate($req-2, $sem:P-RDF-FIRST)
  let $req-2 := sem:object-for-subject-predicate(
    $req-2, $sem:P-OWL-ON-PROPERTY)
  let $req-2 := sem:rdf-subclasses(sem:owl-on-property($req-2))
  return sem:subject-for-join(
    $req-2,
    (sem:object-predicate-join($req-1, $sem:P-RDF-SUBCLASS)) )
};

declare function sem:rdf-subclasses(
  $class as xs:string*)
as xs:string*
{
  if (empty($class)) then () else
  let $sub := sem:subject-for-object-predicate($class, $sem:P-RDF-SUBCLASS)
  return (
    (: time to stop? :)
    if (empty($sub)) then $class else (
      $class,
      sem:rdf-subclasses($sub)
    )
  )
};

declare function sem:rdf-subproperties(
  $prop as xs:string*)
as xs:string*
{
  if (empty($prop)) then () else
  let $sub := sem:subject-for-object-predicate($prop, $sem:P-RDF-SUBPROPERTY)
  return (
    (: time to stop? :)
    if (empty($sub)) then $prop else (
      $prop,
      sem:rdf-subproperties($sub)
    )
  )
};

declare function sem:relate(
  $a as xs:QName,
  $b as xs:QName,
  $a-seed as xs:string*,
  $b-seed as xs:string*,
  $join as element(sem:join)* )
as map:map
{
  sem:relate(
    $a, $b,
    sem:relate-query($a, $b, $a-seed, $b-seed, $join),
    map:map()
  )
};

declare private function sem:relate-query(
  $a as xs:QName,
  $b as xs:QName,
  $a-seed as xs:string*,
  $b-seed as xs:string*,
  $join as element(sem:join)* )
as cts:query
{
  cts:and-query(
    (if (empty($a-seed)) then () else sem:rq($a, $a-seed),
      if (empty($b-seed)) then () else sem:rq($b, $b-seed),
      for $j in $join
      return (
        if ($j/sem:o and $j/sem:p) then error((), 'UNIMPLEMENTED')
        else if ($j/sem:s and $j/sem:p) then error((), 'UNIMPLEMENTED')
        else if ($j/sem:p) then sem:pq($j/sem:p)
        else error((), 'SEM-UNEXPECTED')
        ) ) )
};

declare private function sem:relate(
  $a as xs:QName, $b as xs:QName,
  $query as cts:query,
  $m as map:map)
as map:map
{
  sem:relate(
    $m, cts:element-value-co-occurrences(
      $a, $b, $sem:LEXICON-OPTIONS, $query) ),
  if (not($sem:DEBUG)) then () else xdmp:log(
    text { 'sem:relate', count(map:keys($m)) } ),
  $m
};

declare private function sem:relate(
  $m as map:map, $co as element(cts:co-occurrence) )
as empty-sequence()
{
  map:put($m, $co/cts:value[1], $co/cts:value[2]/string())
};

declare private function sem:relate-join(
  $a as xs:QName, $b as xs:QName,
  $query as cts:query )
as element(cts:co-occurrence)*
{
  cts:element-value-co-occurrences(
    $a, $b, $sem:LEXICON-OPTIONS, $query)
};

declare function sem:relate-join(
  $a as xs:QName,
  $b as xs:QName,
  $a-seed as xs:string*,
  $b-seed as xs:string*,
  $join as element(sem:join)* )
as element(cts:co-occurrence)*
{
  sem:relate-join(
    $a, $b,
    sem:relate-query($a, $b, $a-seed, $b-seed, $join)
  )
};

declare function sem:uri-for-tuple(
  $s as xs:string,
  $p as xs:string,
  $o as xs:string,
  $c as xs:string?)
as xs:string
{
  (: build a deterministic uri for a triple or quad :)
  xdmp:integer-to-hex(
    xdmp:hash64(
      string-join(($s, $p, $o, $c), '|') ) )
};

declare function sem:uri-for-tuple(
  $t as element(t) )
as xs:string
{
  sem:uri-for-tuple($t/s, $t/p, $t/o, $t/c)
};

declare function sem:tuple(
  $s as xs:string,
  $p as xs:string,
  $o as xs:string,
  $c as xs:string?)
as element(t)
{
  element t {
    element s {
      $s },
    element p {
      $p },
    element o {
      $o },
    if (empty($c)) then ()
    else element c {
      $c }
  }
};

declare function sem:tuple-insert-as-property(
  $s as xs:string,
  $p as xs:string,
  $o as xs:string,
  $c as xs:string?)
as empty-sequence()
{
  xdmp:document-add-properties(
    sem:uri-for-tuple($s, $p, $o, $c),
    sem:tuple($s, $p, $o, $c)/* )
};

declare function sem:tuple-insert-as-property(
  $t as element(t))
as empty-sequence()
{
  xdmp:document-add-properties(
    sem:uri-for-tuple($t/s, $t/p, $t/o, $t/c),
    sem:tuple($t/s, $t/p, $t/o, $t/c)/* )
};

declare function sem:tuple-insert(
  $s as xs:string,
  $p as xs:string,
  $o as xs:string,
  $c as xs:string?)
as empty-sequence()
{
  xdmp:document-insert(
    sem:uri-for-tuple($s, $p, $o, $c),
    sem:tuple($s, $p, $o, $c) )
};

declare function sem:tuple-insert(
  $t as element(t))
as empty-sequence()
{
  xdmp:document-insert(
    sem:uri-for-tuple($t/s, $t/p, $t/o, $t/c),
    sem:tuple($t/s, $t/p, $t/o, $t/c) )
};

declare function sem:tuples-for-query(
  $q as cts:query )
as element(t)*
{
  cts:search(/t, $q, 'unfiltered')
};

declare function sem:tuples-for-predicate(
  $p as xs:string+ )
as element(t)*
{
  sem:tuples-for-query(sem:pq($p))
};

declare function sem:tuples-for-subject(
  $s as xs:string+ )
as element(t)*
{
  sem:tuples-for-query(sem:sq($s))
};

declare function sem:tuples-for-object(
  $o as xs:string+ )
as element(t)*
{
  sem:tuples-for-query(sem:oq($o))
};

declare function sem:select(
  $s as element(sem:select))
{
  sem:select($s/@type, $s/sem:join)
};

declare function sem:select(
  $type as xs:string,
  $join as element(sem:join)+)
{
  if ($type eq 'subject') then sem:subject-for-join($join)
  else if ($type eq 'object') then sem:object-for-join($join)
  else error((), 'SEM-UNEXPECTED', text {
      'select must have type subject or object, not',
      xdmp:describe($type) })
};

(: 
 : -------------------------------------
 : PART 2 enhancement
 : -------------------------------------
 :)
 
declare variable $sem:P-OWL-INVERSE :=
'http://www.w3.org/2002/07/owl#inverseOf'
;

declare variable $sem:C-OWL-TRANSITIVE-PROPERTY :=
'http://www.w3.org/2002/07/owl#TransitiveProperty'
;
 
declare variable $sem:C-OWL-SYMMETRIC-PROPERTY :=
'http://www.w3.org/2002/07/owl#SymmetricProperty'
;

declare variable $sem:P-OWL-SAMEAS :=
'http://www.w3.org/2002/07/owl#sameAs'
;


declare variable $sem:P-OWL-HAS-VALUE :=
'http://www.w3.org/2002/07/owl#hasValue'
;


declare variable $sem:O-OWL-DATATYPE-PROPERTY :=
'http://www.w3.org/2002/07/owl#DatatypeProperty'
;
 

(: 
 : -------------------------------------
 : PART 2.1 wrappers
 :	- query constructor
 :	- query evaluation
 : -------------------------------------
 :)

(: shortcut for sem:rq, create a query pattern on subject :)
declare  function sem:query-s(
  $s as xs:string*)
 as cts:query
{
  if (empty($s)) 
  then sem:rq($sem:QN-S, '')
  else sem:rq($sem:QN-S, $s)
};

(: shortcut for sem:rq, create a query pattern on object :)
declare  function sem:query-o(
  $o as xs:string*)
 as cts:query
{
  if (empty($o)) 
  then sem:rq($sem:QN-O, '')
  else sem:rq($sem:QN-O, $o)
};

(: shortcut for sem:rq, create a query pattern on predicate :)
declare function sem:query-p(
  $p as xs:string*)
 as cts:query
{
  if (empty($p)) 
  then sem:rq($sem:QN-P, '')
  else sem:rq($sem:QN-P, $p)
};

(: shortcut for sem:rq, create a query pattern on context (named graph) :)
declare function sem:query-c(
  $c as xs:string*)
 as cts:query
{
  if (empty($c)) 
  then sem:rq($sem:QN-C, '') 
  else sem:rq($sem:QN-C, $c)
};


(: evaluate a list of queries, return a list of strings :)
declare function sem:ev1(
  $qn as xs:QName, 
  $query as cts:query*)
as xs:string*
{
	if (empty($query))
	then ()
	else sem:ev($qn, cts:and-query( $query) )
};

(: evaluate a list of queries, return a list of triples :)
declare function sem:evT(
  $query as cts:query*)
as element(t)*
{
	if (empty($query))
	then ()
	else sem:tuples-for-query(cts:and-query( $query) )
};




(: 
 : -------------------------------------
 : PART 2.2 Set Operations
 : -------------------------------------
 :)
 
declare function sem:setop-union(
  $seq1 as item()*,
  $seq2 as item()*)
as item()*
{
  if (empty($seq1)) then $seq2
  else if (empty($seq2)) then $seq1
  else
  for $x in	$seq1
  for $y in $seq2
  return ($x, $y)
};
 
declare function sem:setop-distinct-element($seq as element()*, $m as map:map) {
    for $e in $seq
    return map:put($m, $e,$e)  
};

declare function sem:setop-distinct-element($seq as element()*) {
  let $m := map:map()
  let $x := sem:setop-distinct-element($seq, $m)
  for $y in map:keys($m)
  return map:get($m,$y)
};

declare function sem:setop-intersect($m as map:map, $seq1 as element()*, $seq2 as element()*) {
    for $e1 in $seq1
    for $e2 in $seq2
    where deep-equal($e1,$e2)
    return map:put($m, $e1,$e1) 
};
 


(: 
 : -------------------------------------
 : PART 2.3 dynamic inference
 : -------------------------------------
 :)


(: list properties which are direct inverse of the input properties :)
declare function sem:list-direct-owl-inverse(
  $p as xs:string*)
as xs:string*
{
  if (empty($p)) then () else
  sem:setop-union(
	sem:subject-for-object-predicate($p, $sem:P-OWL-INVERSE),
    sem:object-for-subject-predicate($p, $sem:P-OWL-INVERSE)
  )
};

(: list classes which are direct sub-classes of the input classes. Results include the input :) 
 declare function sem:list-direct-subclasses(
  $class as xs:string*)
as xs:string*
{
  if (empty($class)) then () else
  let $sub := sem:subject-for-object-predicate($class, $sem:P-RDF-SUBCLASS)
  return (
    (: time to stop? :)
    if (empty($sub)) then $class else (
      $class,
      $sub
    )
  )
};

(: list properties which are direct sub-properties of the input properties. Results include the input :) 
declare function sem:list-direct-subproperties(
  $prop as xs:string*)
as xs:string*
{
  if (empty($prop)) then () else
  let $sub := sem:subject-for-object-predicate($prop, $sem:P-RDF-SUBPROPERTY)
  return (
    (: time to stop? :)
    if (empty($sub)) then $prop else (
      $prop,
     $sub
    )
  )
};




(: 
 : -------------------------------------
 : PART 2.4 forward chaining materialization inference
 : -------------------------------------
 :)

 
(:  Forward-Chaining Inference -- general :)

(:  insert a couple of documents encoded in map in form of  "document key" => "document content" :)
declare function sem:inf-tuple-insert($m as map:map)
as  empty-sequence()
{
  for $key in map:keys($m)
  return  xdmp:document-insert($key, map:get($m, $key))
};


(:  Forward-Chaining Inference -- add owl2 ontology :)

declare function sem:inf-owl2-ontology()
as xs:integer*{
 (	
   sem:tuple-insert( 'http://www.w3.org/2002/07/owl#SymmetricProperty' , 'http://www.w3.org/2000/01/rdf-schema#subClassOf' ,  'http://www.w3.org/2002/07/owl#ObjectProperty', 'http://www.w3.org/2002/07/owl' ),
   sem:tuple-insert( 'http://www.w3.org/2002/07/owl#TransitiveProperty' , 'http://www.w3.org/2000/01/rdf-schema#subClassOf' ,  'http://www.w3.org/2002/07/owl#ObjectProperty', 'http://www.w3.org/2002/07/owl' ),
   ()
 )
};



(:  Forward-Chaining Inference -- OWL2RL rules http://www.w3.org/TR/owl2-profiles/#OWL_2_RL :)


(: owl2rl | eq-sym | sameAs :)
declare function sem:inf-owl2rl-eq-sym()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-eq-sym($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-eq-sym($m as map:map)
as  empty-sequence()
{
  for  $t_x_y in sem:evT( sem:query-p( $sem:P-OWL-SAMEAS ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  let $key := sem:uri-for-tuple($y, $sem:P-OWL-SAMEAS, $x, '')
  where (($x != $y) and (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) )
  return map:put(
      $m, 
      $key,   
      sem:tuple($y, $sem:P-OWL-SAMEAS, $x, '')) 
};
 


(: owl2rl | eq-trans | sameAs :)
declare function sem:inf-owl2rl-eq-trans()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-eq-trans($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-eq-trans($m as map:map)
as empty-sequence()
{
  for  $t_x_y in sem:evT( sem:query-p( $sem:P-OWL-SAMEAS ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  for  $z in sem:ev1( $sem:QN-O, (sem:query-s( $y ), sem:query-p( $sem:P-OWL-SAMEAS ) )) 
  let $key := sem:uri-for-tuple($x, $sem:P-OWL-SAMEAS, $z, '')
  where (($x != $y) and ($y != $z) and (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) ) 
  return map:put(
      $m, 
      $key,   
      sem:tuple($x, $sem:P-OWL-SAMEAS, $z, '')) 
};
 


(: owl2rl | eq-rep-s | sameAs :)
declare function sem:inf-owl2rl-eq-rep-s()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-eq-rep-s($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-eq-rep-s($m as map:map)
as  empty-sequence()
{
  for  $t_x_y in sem:evT( sem:query-p( $sem:P-OWL-SAMEAS ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  for  $t_p_o in sem:evT( sem:query-s( $x ) ) 
      , $p in $t_p_o/p/text()
      , $o in $t_p_o/o/text()
  let $key := sem:uri-for-tuple($y, $p, $o, '')
  where (($x != $y) and (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) ) 
  return map:put(
      $m, 
      $key,   
      sem:tuple($y, $p, $o, '')) 
};
 
 
 
(: owl2rl | eq-rep-p | sameAs :)
declare function sem:inf-owl2rl-eq-rep-p()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-eq-rep-p($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-eq-rep-p($m as map:map)
as  empty-sequence()
{
  for  $t_x_y in sem:evT( sem:query-p( $sem:P-OWL-SAMEAS ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  for  $t_s_o in sem:evT( sem:query-p( $x ) ) 
      , $s in $t_s_o/s/text()
      , $o in $t_s_o/o/text()
  let $key := sem:uri-for-tuple($s, $y, $o, '')
  where (($x != $y) and (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) ) 
  return map:put(
      $m, 
      $key,   
      sem:tuple($s, $y, $o, '')) 
};



(: owl2rl | eq-rep-o | sameAs :)
declare function sem:inf-owl2rl-eq-rep-o()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-eq-rep-o($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-eq-rep-o($m as map:map)
as  empty-sequence()
{
  for  $t_x_y in sem:evT( sem:query-p( $sem:P-OWL-SAMEAS ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  for  $t_s_p in sem:evT( sem:query-o( $x ) ) 
      , $s in $t_s_p/s/text()
      , $p in $t_s_p/p/text()
  let $key := sem:uri-for-tuple($s, $p, $y, '')
  where (($x != $y) and (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) ) 
  return map:put(
      $m, 
      $key,   
      sem:tuple($s, $p, $y, '')) 
};




(: owl2rl | prp-symp | SymmetricProperty :)
declare function sem:inf-owl2rl-prp-symp()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-prp-symp($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-prp-symp($m as map:map)
as  empty-sequence()
{
  for  $p in sem:ev1(  $sem:QN-S, (sem:query-p( $sem:P-RDF-TYPE ), sem:query-o( $sem:C-OWL-SYMMETRIC-PROPERTY)) ) 
  for  $t_x_y in sem:evT( sem:query-p( $p ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  let $key := sem:uri-for-tuple($y, $p, $x, '')
  where ( ($x != $y)  and (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) )
  return map:put(
      $m, 
      $key,   
      sem:tuple($y, $p, $x, '')) 
};




(: owl2rl | prp-trp  | TransitiveProperty :)
declare function sem:inf-owl2rl-prp-trp()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-prp-trp($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-prp-trp($m as map:map)
as empty-sequence()
{
  for  $p in sem:ev1(  $sem:QN-S, (sem:query-p( $sem:P-RDF-TYPE ), sem:query-o( $sem:C-OWL-TRANSITIVE-PROPERTY )) ) 
  for  $t_x_y in sem:evT( sem:query-p( $p ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  for  $z in sem:ev1( $sem:QN-O, (sem:query-s( $y ), sem:query-p( $p ) )) 
  let $key := sem:uri-for-tuple($x, $p, $z, '')
  where (($x != $y) and ($y != $z) and (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) ) 
  return map:put(
      $m, 
      $key,   
      sem:tuple($x, $p, $z, '')) 
};


(: owl2rl | prp-spo1  | subPropertyOf inference :)
declare function sem:inf-owl2rl-prp-spo1()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-prp-spo1($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-prp-spo1($m as map:map)
as empty-sequence()
{
  for  $t_p1_p2 in sem:evT( sem:query-p( $sem:P-RDF-SUBPROPERTY ) ) 
      , $p1 in $t_p1_p2/s/text()
      , $p2 in $t_p1_p2/o/text()
  for  $t_x_y in sem:evT( sem:query-p( $p1 ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  let $key := sem:uri-for-tuple($x, $p2, $y, '')
  where ( ($p1 != $p2 ) and (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) ) 
  return map:put(
      $m, 
      $key,   
      sem:tuple($x, $p2, $y, '')) 
};


 
(: owl2rl | prp-inv1  | inverseOf:)
declare function sem:inf-owl2rl-prp-inv1()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-prp-inv1($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-prp-inv1($m as map:map)
as  empty-sequence()
{
  for  $t_x_y in sem:evT( sem:query-p( $sem:P-OWL-INVERSE ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  for  $t_s_o in sem:evT( sem:query-p( $x ) ) 
      , $s in $t_s_o/s/text()
      , $o in $t_s_o/o/text()
  let $key := sem:uri-for-tuple($o, $y, $s, '')
  where ( ($x != $y)  and (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) )
  return map:put(
      $m, 
      $key,   
      sem:tuple($o, $y, $s, '')) 
};




(: owl2rl | prp-inv2  | inverseOf:)
declare function sem:inf-owl2rl-prp-inv2()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-prp-inv2($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-prp-inv2($m as map:map)
as  empty-sequence()
{
  for  $t_x_y in sem:evT( sem:query-p( $sem:P-OWL-INVERSE ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  for  $t_s_o in sem:evT( sem:query-p( $y ) ) 
      , $s in $t_s_o/s/text()
      , $o in $t_s_o/o/text()
  let $key := sem:uri-for-tuple($o, $x, $s, '')
  where ( ($x != $y)  and (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) )
  return map:put(
      $m, 
      $key,   
      sem:tuple($o, $x, $s, '')) 
};


(: owl2rl | cls-hv1  | owl:hasValue  :)
declare function sem:inf-owl2rl-cls-hv1()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-cls-hv1($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-cls-hv1($m as map:map)
as  empty-sequence()
{
  for  $t_x_y in sem:evT( sem:query-p( $sem:P-OWL-HAS-VALUE ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  for  $p in sem:ev1(  $sem:QN-O, (sem:query-p( $sem:P-OWL-ON-PROPERTY ), sem:query-s( $x )) ) 
  for  $u in sem:ev1(  $sem:QN-S, (sem:query-p( $sem:P-RDF-TYPE ), sem:query-o( $x )) ) 
  let $key := sem:uri-for-tuple($u, $p, $y, '')
  where ( (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) )
  return map:put(
      $m, 
      $key,   
      sem:tuple($u, $p, $y, '')) 
};


(: owl2rl | cls-hv2  | owl:hasValue  :)
declare function sem:inf-owl2rl-cls-hv2()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-cls-hv2($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-cls-hv2($m as map:map)
as  empty-sequence()
{
  for  $t_x_y in sem:evT( sem:query-p( $sem:P-OWL-HAS-VALUE ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  for  $p in sem:ev1(  $sem:QN-O, (sem:query-p( $sem:P-OWL-ON-PROPERTY ), sem:query-s( $x )) ) 
  for  $u in sem:ev1(  $sem:QN-S, (sem:query-p( $p ), sem:query-o( $x )) ) 
  let $key := sem:uri-for-tuple($u, $sem:P-RDF-TYPE, $x, '')
  where ( (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) )
  return map:put(
      $m, 
      $key,   
      sem:tuple($u, $sem:P-RDF-TYPE, $x, '')) 
};



(: owl2rl | cax-sco | subClassOf inference :)
declare function sem:inf-owl2rl-cax-sco()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-cax-sco($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-cax-sco($m as map:map)
as  empty-sequence()
{
  for  $t_c1_c2 in sem:evT( sem:query-p( $sem:P-RDF-SUBCLASS ) ) 
      , $c1 in $t_c1_c2/s/text()
      , $c2 in $t_c1_c2/o/text()
  for  $x in sem:ev1( $sem:QN-S, (sem:query-o( $c1 ), sem:query-p( $sem:P-RDF-TYPE ) )) 
  let $key := sem:uri-for-tuple($x, $sem:P-RDF-TYPE , $c2, '')
  where ( ($c1 != $c2)  and (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) )
  return map:put(
      $m, 
      $key,   
      sem:tuple($x, $sem:P-RDF-TYPE , $c2, '')) 
};



(: owl2rl | scm-cls | class inference  TODO PARTIAL only first of four possible triples are generated :)
declare function sem:inf-owl2rl-scm-cls()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-scm-cls($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-scm-cls($m as map:map)
as  empty-sequence()
{
  for  $c in sem:ev1(  $sem:QN-S, (sem:query-p( $sem:P-RDF-TYPE ), sem:query-o( $sem:O-OWL-CLASS)) ) 
  let $key := sem:uri-for-tuple($c, $sem:P-RDF-SUBCLASS, $c, '')
  where ( (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) )
  return map:put(
      $m, 
      $key,   
      sem:tuple($c, $sem:P-RDF-SUBCLASS, $c, '')) 
};



(: owl2rl | scm-sco   | subClassOf :)
declare function sem:inf-owl2rl-scm-sco()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-scm-sco($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-scm-sco($m as map:map)
as  empty-sequence()
{
  for  $t_x_y in sem:evT( sem:query-p( $sem:P-RDF-SUBCLASS ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  for  $z in sem:ev1( $sem:QN-O, (sem:query-s( $y ), sem:query-p( $sem:P-RDF-SUBCLASS ) )) 
  let $key := sem:uri-for-tuple($x, $sem:P-RDF-SUBCLASS, $z, '')
  where ( ($x != $y) and ($y != $z)  and (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) )
  return map:put(
      $m, 
      $key,   
      sem:tuple($x, $sem:P-RDF-SUBCLASS, $z, '')) 
};



(: owl2rl | scm-op | Property inference TODO PARTIAL only first of two possible triples are generated:)
declare function sem:inf-owl2rl-scm-op()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-scm-op($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-scm-op($m as map:map)
as  empty-sequence()
{
  for  $p in sem:ev1(  $sem:QN-S, (sem:query-p( $sem:P-RDF-TYPE ), sem:query-o( $sem:O-OWL-OBJECT-PROPERTY)) ) 
  let $key := sem:uri-for-tuple($p, $sem:P-RDF-SUBPROPERTY, $p, '')
  where ( (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) )
  return map:put(
      $m, 
      $key,   
      sem:tuple($p, $sem:P-RDF-SUBPROPERTY, $p, '')) 
};


(: owl2rl | scm-dp | Property inference TODO PARTIAL only first of two possible triples are generated:)
declare function sem:inf-owl2rl-scm-dp()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-scm-dp($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-scm-dp($m as map:map)
as  empty-sequence()
{
  for  $p in sem:ev1(  $sem:QN-S, (sem:query-p( $sem:P-RDF-TYPE ), sem:query-o( $sem:O-OWL-DATATYPE-PROPERTY)) ) 
  let $key := sem:uri-for-tuple($p, $sem:P-RDF-SUBPROPERTY, $p, '')
  where ( (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) )
  return map:put(
      $m, 
      $key,   
      sem:tuple($p, $sem:P-RDF-SUBPROPERTY, $p, '')) 
};


(: owl2rl | scm-spo   | subPropertyOf :)
declare function sem:inf-owl2rl-scm-spo()
as xs:integer
{
  let $m := map:map()
  let $query := sem:inf-owl2rl-scm-spo($m)
  let $exec := sem:inf-tuple-insert($m)
  return map:count($m)
};

declare private function sem:inf-owl2rl-scm-spo($m as map:map)
as  empty-sequence()
{
  for  $t_x_y in sem:evT( sem:query-p( $sem:P-RDF-SUBPROPERTY ) ) 
      , $x in $t_x_y/s/text()
      , $y in $t_x_y/o/text()
  for  $z in sem:ev1( $sem:QN-O, (sem:query-s( $y ), sem:query-p( $sem:P-RDF-SUBPROPERTY ) )) 
  let $key := sem:uri-for-tuple($x, $sem:P-RDF-SUBPROPERTY, $z, '')
  where ( ($x != $y) and ($y != $z)  and (map:count($m) lt 10000) and ( not (fn:doc-available($key)) ) )
  return map:put(
      $m, 
      $key,    
      sem:tuple($x, $sem:P-RDF-SUBPROPERTY, $z, '')) 
};

(: semantic.xqy :)
