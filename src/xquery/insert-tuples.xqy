xquery version "1.0-ml";
(:
 : Copyright (c)2009-2010 Mark Logic Corporation
 :)

import module namespace sem="http://marklogic.com/semantic"
 at "semantic.xqy";

declare variable $AS-PROPERTY as xs:boolean external ;

declare variable $FOREST as xs:unsignedLong external
;
declare variable $MAP as map:map external
;

if ($AS-PROPERTY)
then sem:tuple-insert-as-property(map:get($MAP, xs:string($FOREST))) 
else sem:tuple-insert(map:get($MAP, xs:string($FOREST)))

(: insert-tuples.xqy :)
