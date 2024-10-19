#import "@preview/athena-tu-darmstadt-thesis:0.1.0": *
#import "@preview/glossarium:0.4.1": make-glossary, print-glossary, gls, glspl 

#show: make-glossary

#show: tudapub.with(
  reduce_heading_space_when_first_on_page: false, // so it converges
  thesis_type: "bachelor",
  title: [Optimizing Collaborative Plain~Text Editing Algorithms],
  title_german: [for Decentralized Non-Realtime Text Editing],
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
  bib: bibliography("./literature.bib"),
  margin: tud_page_margin_big,
  // outline_table_of_contents_style: "adapted",
  // reduce_heading_space_when_first_on_page: false
  show_pages: (
    title_page: true,
    outline_table_of_contents: true,
    thesis_statement_pursuant: true
  ),
  thesis_statement_pursuant_include_english_translation: false,
)

#set figure(placement: top)

= THIS IS AN INCOMPLETE TYPST CONVERSION OF MY THESIS

My actual thesis is published at https://doi.org/10.26083/tuprints-00027834.
Some parts have been lost in the conversion using pandoc and I did not put in the effort to fix this manually. This is only as a proof of concept and not for actually reading my thesis.

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

#heading(numbering: none, "Acronyms")

#print-glossary((
    (key: "crdt", short: "CRDT", long: "conflict-free replicated data type"),
    (key: "ot", short: "OT", long: "operational transformation"),
    (key: "oo", short: "OO", long: "Object-oriented"),
    (key: "fp", short: "FP", long: "Functional programming"),
    (key: "p2p", short: "P2P", long: "peer-to-peer"),
    (key: "dtn", short: "DTN", long: "delay tolerant network"),
    (key: "rdt", short: "RDT", long: "replicated data type"),
    (key: "woot", short: "WOOT", long: "WithOut Operational Transforms"),
    (key: "rga", short: "RGA", long: "Replicated Growable Array"),
    (key: "yata", short: "YATA", long: "Yet Another Transformation Approach"),
    (key: "manet", short: "MANET", long: "mobile ad hoc network"),
  ),
  show-all: true
)

#set heading(numbering: (..nums) => {
  nums = nums.pos()
  if nums.len() == 1 {
    return "A"
  } else if nums.len() == 2 {
    return "A." + numbering("1", ..nums.slice(1))
  }
})

= Appendix
<appendix:appendix>

== CPU Profile for Simple Algorithm with Sequential Insertions
<appendix:simple-sequential-inserts-cpu>

//#image("./text-rdt/target/pdfs/simple-sequential-inserts-cpu.svg")

== CPU Profile for Batching Algorithm with Sequential Insertions
<appendix:complex-sequential-inserts-cpu>

//#image("./text-rdt/target/pdfs/complex-sequential-inserts-cpu.svg")

== Allocation Profile for Batching Algorithm with Sequential Insertions
<appendix:complex-sequential-inserts-alloc>

//#image("./text-rdt/target/pdfs/complex-sequential-inserts-alloc.svg")

== CPU Profile for Batching Algorithm with Real World Dataset
<appendix:complex-real-world-cpu>

//#image("./text-rdt/target/pdfs/complex-real-world-cpu.svg")

== CPU Profile for Simple AVL Algorithm with Real World Dataset
<appendix:simpleavl-real-world-cpu>

//#image("./text-rdt/target/pdfs/simpleavl-real-world-cpu.svg")

== Allocation Profile for Simple AVL Algorithm with Real World Dataset
<appendix:simpleavl-real-world-alloc>

//#image("./text-rdt/target/pdfs/simpleavl-real-world-alloc.svg")

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