xquery version "1.0-ml";
(:
 : Copyright (c)2009-2010 Mark Logic Corporation
 :)

import module namespace sem="http://marklogic.com/semantic"
 at "semantic.xqy";

declare variable $URI as xs:string external
;
declare variable $NODE as node() external
;
declare variable $SKIP-EXISTING as xs:boolean external
;

if ($SKIP-EXISTING and exists(doc($URI))) then ()
else xdmp:document-insert($URI, $NODE)
