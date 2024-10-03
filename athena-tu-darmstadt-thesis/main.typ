#import "@preview/athena-tu-darmstadt-thesis:0.1.0": *

#show: tudapub.with(
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