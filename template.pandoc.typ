#import "../utils.typ": gls, glspl

$if(template)$
#import "$template$": conf
$endif$

$if(smart)$
$else$
#set smartquote(enabled: false)

$endif$
$for(header-includes)$
$header-includes$

$endfor$

$for(include-before)$
$include-before$

$endfor$
$if(toc)$
#outline(
  title: auto,
  depth: $toc-depth$
);
$endif$

$body$

$for(include-after)$

$include-after$
$endfor$