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
