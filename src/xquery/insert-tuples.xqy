xquery version "1.0-ml";
(:
 : Copyright (c)2009-2010 Mark Logic Corporation
 :)

import module namespace sem="http://marklogic.com/semantic"
 at "semantic.xqy";

declare variable $FOREST as xs:unsignedLong external
;
declare variable $MAP as map:map external
;

for $n as element(t) in map:get($MAP, xs:string($FOREST))
return sem:tuple-insert($n/s, $n/p, $n/o, $n/c)

(: insert-tuples.xqy :)