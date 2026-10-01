#import "@preview/glossarium:0.5.10": make-glossary, register-glossary, print-glossary, gls, glspl

#let twoMinipageFigures(
  figure1,
  figure2,
) = figure({
  show figure: set figure(numbering: "(a)", supplement: [])
  grid(
    columns: (50%, 50%),
    align: bottom,
    figure1,
    figure2
  )
})
