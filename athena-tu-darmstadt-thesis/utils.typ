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