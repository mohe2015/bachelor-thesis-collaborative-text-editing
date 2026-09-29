// pandoc --template template.pandoc.typ -f reader.lua -t haobook.lua chapters_en/02_Studium/0201_1x1.tex -o chapters_en/02_Studium/0201_1x1.typ
#import "/src/packages.typ": haobook, tiaoma
#import "/src/util.typ": TODO, multi-file-fixes, ophasenqr, räume

#show heading.where(level: 3): set heading(outlined: false, numbering: none) // TODO: Fix?
#show figure.where(kind: "symbolbild"): set figure(
    supplement: "For illustrative purposes only",
)

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

$if(citations)$
$if(csl)$

#set bibliography(style: "$csl$")
$elseif(bibliographystyle)$

#set bibliography(style: "$bibliographystyle$")
$endif$
$if(bibliography)$

#bibliography($for(bibliography)$"$bibliography$"$sep$,$endfor$)
$endif$
$endif$
$for(include-after)$

$include-after$
$endfor$