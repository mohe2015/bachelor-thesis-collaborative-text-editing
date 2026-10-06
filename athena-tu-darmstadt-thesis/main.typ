#import "@preview/athena-tu-darmstadt-thesis:0.1.2": *
#import "utils.typ": make-glossary, register-glossary, print-glossary, gls, glspl
#import "@preview/numera:0.1.0": heading-dependent, normal-figure, numera, ref-dependent, subfigure-dependent, subfigure-counter-dependent
#import "@preview/zebraw:0.6.3": *
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.10": *

#let entry-list = (
  (key: "crdt", short: [CRDT], long: [conflict-free replicated data type]),
  (key: "ot", short: [OT], long: [operational transformation]),
  (key: "oo", short: [OO], long: [Object-oriented]),
  (key: "fp", short: [FP], long: [Functional programming]),
  (key: "p2p", short: [P2P], long: [peer-to-peer]),
  (key: "dtn", short: [DTN], long: [delay tolerant network]),
  (key: "rdt", short: [RDT], long: [replicated data type]),
  (key: "woot", short: [WOOT], long: [WithOut Operational Transforms]),
  (key: "rga", short: [RGA], long: [Replicated Growable Array]),
  (key: "yata", short: [YATA], long: [Yet Another Transformation Approach]),
  (key: "manet", short: [MANET], long: [mobile ad hoc network])
)
#let hidden-entry-list = (
  (key: "simple-algorithm", short: [simple algorithm], description: "Our algorithm without batching and without an AVL tree"),
  (key: "simple-ID", short: [simple ID], description: "The ID for our simple algorithm"),
  (key: "batching-ID", short: [batching ID], description: "The ID for our batching algorithm"),
  (key: "batching-algorithm", short: [batching algorithm], description: "Our algorithm with batching but without an AVL tree"),
  (key: "simple-AVL-algorithm", short: [simple AVL algorithm], description: "Our algorithm without batching but with an AVL tree"),
  (key: "batching-AVL-algorithm", short: [batching AVL algorithm], description: "Our algorithm with batching and with an AVL tree"),
)
#show: make-glossary
#register-glossary(entry-list + hidden-entry-list)

#show: tudapub.with(
  reduce_heading_space_when_first_on_page: false, // so it converges
  thesis_type: "bachelor",
  title: [Optimizing Collaborative Plain~Text Editing Algorithms],
  subtitle: [for Decentralized Non-Realtime Text Editing],
  author: "Moritz Hedtke",
  date_of_submission: datetime(
      year: 2024,
      month: 8,
      day: 5,
  ),
  reviewer_names: ("Prof. Dr.-Ing. Mira Mezini", "Dr.-Ing. Ragnar Mogk"),
  logo_sub_content_text: [
    Computer~Science \
    Department

    TU Darmstadt

    Software~Technology~Group
  ],
  logo_tuda: image("logos/tuda_logo.svg"),
  accentcolor: "9c",
  abstract: [
    #include "chapters/abstract.typ"
  ],
  margin: tud_page_margin_big,
  show_pages: (
    title_page: true,
    outline_table_of_contents: true,
    thesis_statement_pursuant: true
  ),
  page_numbering_starts_after_outline: false,
  additional_pages_after_title_page: [
    #set page(header: none, footer: none)
    #grid(rows: 1fr,
    [Optimizing Collaborative Plain Text Editing Algorithms\
    for Decentralized Non-Realtime Text Editing

    Bachelor thesis by Moritz Hedtke

    Date of submission: August 5, 2024

    Darmstadt],

    [Bitte zitieren Sie dieses Dokument als:\
    URN: urn:nbn:de:tuda-tuprints-278347\
    URL: https://tuprints.ulb.tu-darmstadt.de/27834\
    Jahr der Veröffentlichung auf TUprints: 2024

    Dieses Dokument wird bereitgestellt von tuprints,\
    E-Publishing-Service der TU Darmstadt\
    https://tuprints.ulb.tu-darmstadt.de\
    tuprints\@ulb.tu-darmstadt.de],

    [Die Veröffentlichung steht unter folgender Creative Commons Lizenz:\
    Namensnennung 4.0 International\
    https://creativecommons.org/licenses/by/4.0/\
    This work is licensed under a Creative Commons License:\
    Attribution 4.0 International\
    https://creativecommons.org/licenses/by/4.0/])
    #pagebreak(weak: true)
  ],
  thesis_statement_pursuant_include_english_translation: false,
)

#set heading(numbering: "1.")
#show heading.where(level: 1): set heading(supplement: [Chapter])

#let level = 1
#show: numera(level: level)

#show figure: set figure(numbering: ref-dependent(
  subfigure-dependent("(a)", figure-numbering: heading-dependent(level, "1.")),
  heading-dependent(level, subfigure-counter-dependent(
    "1a",
    figure-numbering: auto,
  )),
))

#show figure.where(kind: "subfigure"): set figure(supplement: "")

// override
#show heading.where(level: 5): it => {
  par()[]
  set text(
    font: "Roboto",
    fallback: false,
    weight: "bold",
    size: 10.909pt,
  )
  it.body
  h(1mm)
}

#show heading: it => {
  if it.level <= level {
    counter(footnote).update(0)
  }
  it
}

// https://forum.typst.app/t/are-there-equivalent-to-the-latex-microtype-package-and-the-memoir-document-class/1540
#set par(justify: true, justification-limits: (tracking: (min: -0.01em, max: 0.02em)))

#set figure(placement: top)

//#show: zebraw
//#show: zebraw-init.with(background-color: none, lang: false)

#show: codly-init
#codly(display-name: false, zebra-fill: none)

#include "chapters/introduction.typ"
#include "chapters/challenges.typ"
#include "chapters/background.typ"
#include "chapters/implementation.typ"
#include "chapters/optimization.typ"
#include "chapters/evaluation.typ"
#include "chapters/future-work.typ"
#include "chapters/conclusion.typ"

#heading(numbering: none, outlined: false, "Acknowledgments")

I would like to thank everyone who reviewed drafts of this thesis. I would also like to thank my human and non-human rubber ducks for their help in debugging my code.

#heading(numbering: none, [Acronyms])

#print-glossary(entry-list, deduplicate-back-references: true)
#print-glossary(hidden-entry-list, invisible: true)

#heading([Bibliography], numbering: none, outlined: false)
#bibliography(title: none, "./literature.bib", style: "basic.csl")

#set heading(supplement: [Appendix], numbering: (..nums) => {
  nums = nums.pos()
  return "A." + numbering("1", ..nums.slice(1))
})

= Appendix
<appendix:appendix>

== CPU Profile for Simple Algorithm with Sequential Insertions
<appendix:simple-sequential-inserts-cpu>

#image("/result/simple-sequential-inserts-cpu.png", width: 80%)

== CPU Profile for Batching Algorithm with Sequential Insertions
<appendix:complex-sequential-inserts-cpu>

#image("/result/complex-sequential-inserts-cpu.png")

== Allocation Profile for Batching Algorithm with Sequential Insertions
<appendix:complex-sequential-inserts-alloc>

#image("/result/complex-sequential-inserts-alloc.png")

== CPU Profile for Batching Algorithm with Real World Dataset
<appendix:complex-real-world-cpu>

#image("/result/complex-real-world-cpu.png")

== CPU Profile for Simple AVL Algorithm with Real World Dataset
<appendix:simpleavl-real-world-cpu>

#image("/result/simpleavl-real-world-cpu.png")

== Allocation Profile for Simple AVL Algorithm with Real World Dataset
<appendix:simpleavl-real-world-alloc>

#image("/result/simpleavl-real-world-alloc.png")

== Code Showing FugueMax Is Interleaving
<appendix:code-fuguemax-interleaving>

```ts
let rng = seedrandom("42");
let docA = new CRuntime({
  debugReplicaID: ReplicaIDs.pseudoRandom(rng),
});
let ctextA = docA.registerCollab(
  "text",
  (init) => new FugueMaxSimple(init)
);
let docB = new CRuntime({
  debugReplicaID: ReplicaIDs.pseudoRandom(rng),
});
let ctextB = docB.registerCollab(
  "text",
  (init) => new FugueMaxSimple(init)
);
let messageA: Uint8Array = null!
docA.on("Send", (e) => {
  messageA = e.message
})
let messageB: Uint8Array = null!
docB.on("Send", (e) => {
  messageB = e.message
})
docA.transact(() => {
  ctextA.insert(0, 'S')
  ctextA.insert(1, 'h')
  ctextA.insert(2, 'o')
  ctextA.insert(3, 'p')
  ctextA.insert(4, 'p')
  ctextA.insert(5, 'i')
  ctextA.insert(6, 'n')
  ctextA.insert(7, 'g')
})
docB.receive(messageA)
docB.transact(() => {
  ctextB.insert(8, '*')
  ctextB.insert(9, 'b')
  ctextB.insert(10, 'r')
  ctextB.insert(11, 'e')
  ctextB.insert(12, 'a')
  ctextB.insert(13, 'd')
  ctextB.delete(7)
  ctextB.insert(7, 'g')
  ctextB.insert(8, 'B')
  ctextB.insert(9, 'a')
  ctextB.insert(10, 'k')
  ctextB.insert(11, 'e')
  ctextB.insert(12, 'r')
  ctextB.insert(13, 'y')
  ctextB.insert(14, ':')
})
docA.transact(() => {
  ctextA.insert(8, '*')
  ctextA.insert(9, 'a')
  ctextA.insert(10, 'p')
  ctextA.insert(11, 'p')
  ctextA.insert(12, 'l')
  ctextA.insert(13, 'e')
  ctextA.insert(14, 's')
  ctextA.insert(8, 'F')
  ctextA.insert(9, 'r')
  ctextA.insert(10, 'u')
  ctextA.insert(11, 'i')
  ctextA.insert(12, 't')
  ctextA.insert(13, ':')
})
docB.receive(messageA)
docA.receive(messageB)
console.log([...ctextA.values()].join(""))
console.log([...ctextB.values()].join(""))
```