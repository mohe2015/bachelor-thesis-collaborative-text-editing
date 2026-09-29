#import "@preview/glossarium:0.5.10": make-glossary, register-glossary, print-glossary, gls, glspl

#let benchmarkResults(name, caption) = figure(
  {
    set figure(supplement: [])
    show figure.caption: it => [
      #context it.counter.display("(a)")
      #it.body
    ]
    grid(
      columns: (50%, 50%),
      align: bottom,
      [ #figure(image("../figures/" + name + ".pdf"), caption: "time", kind: "fig"+name) #label(name) ],
      [ #figure(image("../figures/" + name + "-memory.pdf"), caption: "memory", kind: "fig"+name) #label(name) ],
    )
  },
  caption: caption
)

#let evil-edge-case(name, caption) = [ #figure(
  {
    set figure(supplement: [])
    show figure.caption: it => [
      #context it.counter.display("(a)")
      #it.body
    ]
    grid(
      columns: (50%, 50%),
      align: bottom,
      [
        #figure(
          image("/result/" + name + "-before.pdf"),
          caption: "before",
          kind: "fig" + name,
        ) #label(name)
      ],
      [
        #figure(
          image("/result/" + name + "-after.pdf"),
          caption: "after",
          kind: "fig" + name,
        ) #label(name)
      ],
    )
  },
  caption: "Example for " + caption,
) #label("fig:edge-case-" + name + "-example") ]

#let twoMinipageFigures(
  file1,
  caption1,
  label1,
  file2,
  caption2,
  label2,
) = figure({
  show figure: set figure(numbering: "(a)", supplement: [])
  grid(
    columns: (50%, 50%),
    align: bottom,
    [ #figure(image(file1), caption: caption1, kind: "fig1") #label(label1) ],
    [ #figure(image(file2), caption: caption2, kind: "fig1") #label(label2) ],
  )
})
