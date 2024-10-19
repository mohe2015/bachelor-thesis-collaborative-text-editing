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
      [ #figure(image("../text-rdt/jvm/figure-benchmark-results/" + name + ".svg"), caption: "time", kind: "fig"+name) #label(name) ],
      [ #figure(image("../text-rdt/jvm/figure-benchmark-results/" + name + "-memory.svg"), caption: "memory", kind: "fig"+name) #label(name) ],
    )
  },
  caption: caption
)