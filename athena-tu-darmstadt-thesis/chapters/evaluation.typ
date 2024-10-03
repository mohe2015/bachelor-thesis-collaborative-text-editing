#import "@preview/glossarium:0.4.1": gls, glspl 
#import "utils.typ": benchmarkResults

= Evaluation
<chapter:evaluation>
We chose to evaluate our approach by benchmarking with JMH#footnote[#link("https://github.com/openjdk/jmh");] as that is the de facto Java benchmarking tool. We ran the benchmarks on four Intel Xeon Gold vCPUs with 8~GB RAM rented from Hetzner Cloud#footnote[#link("https://www.hetzner.com/cloud/");] \(type cx32).

We use the JMH support for async-profiler#footnote[<footnote:async-profiler>#link("https://github.com/async-profiler/async-profiler");] because async-profiler is not affected by the Safepoint bias problem#footnote[#link("https://psy-lob-saw.blogspot.com/2016/02/why-most-sampling-java-profilers-are.html");] which can lead to bias in the profiler results. Additionally, its allocation profiling does not influence Escape Analysis#footnote[#link("https://blogs.oracle.com/javamagazine/post/escape-analysis-in-the-hotspot-jit-compiler");] or prevent JIT optimizations like allocation elimination and therefore measures only actual heap allocations.

The Scala.js output was not considered in the analysis given the inherent challenges arising from the additional layer of indirection created by the transpilation from Scala to JavaScript. This indirection likely affects performance and complicates optimization efforts because they potentially only affect the transpiled version rather than the original. Furthermore, the resulting code from the transpilation is highly unreadable, which makes it difficult to correlate it with the original code especially when it involves standard library functionality. Benchmarking the JavaScript transpiled output would have had the advantage of being able to directly compare with most other research results, as there is a popular framework by Kevin Jahns#footnote[#link("https://github.com/dmonad/crdt-benchmarks/");] that many publications use @2023-weidner-minimizing-interleaving[Section~5.1].

For our final benchmarks the generic parameter which specified the type of the elements in the list data structure was removed and specialized for text. This reduces memory usage a bit as Scala otherwise needs to create an object per character. This leads to an
overhead because of the required metadata per object and because a character object is two bytes large, but many
characters only need a single byte.

#figure[
```scala
ManagementFactory
    .getPlatformMBeanServer()
    .nn
    .invoke(
      new ObjectName("com.sun.management:type=DiagnosticCommand"),
      "gcClassHistogram",
      Array[Object | Null](null),
      Array("[Ljava.lang.String;")
    )
```

]
#figure[
```text
     #instances         #bytes  class name (module)
-------------------------------------------------------
        2957804       94649728  text_rdt.avl2.AVL2TreeNode
        1609332       88413312  [B (java.base@21.0.3)
        1478902       82818512  text_rdt.ComplexAVLTreeNode
        1478902       59156080  text_rdt.avl.AVLTreeNode
        1058700       50817600  text_rdt.ComplexAVLMessage$Insert
        1254001       50160040  scala.collection.mutable.RedBlackTree$Node
        1596802       38323248  java.lang.StringBuilder (java.base@21.0.3)
        1478903       35493672  text_rdt.avl2.AVL2Tree
        1596801       25548816  scala.collection.mutable.StringBuilder
         710800       22745600  text_rdt.ComplexAVLMessage$Delete
         538103       17219296  scala.collection.mutable.HashMap$Node
         538105       12914520  scala.Tuple2
         538101       12914424  text_rdt.SimpleID
           2270        9637384  [Ljava.lang.Object; (java.base@21.0.3)
         313201        7516824  scala.collection.mutable.RedBlackTree$Tree
         313201        7516824  scala.collection.mutable.TreeSet
         182315        4375560  text_rdt.FixtureOperation$Insert
              2        4194368  [Lscala.collection.mutable.HashMap$Node;
          77463        1239408  text_rdt.FixtureOperation$Delete
...
Total  17763864      627984600
```

]
== Measuring Maximum Memory Usage
<sec:memory-results>
The memory usage is calculated using the code in , which is equivalent to `jcmd PID GC.class_histogram`. It is measured before and after running the operations and the difference is then visualized in our graphs. The memory usage is returned using JMH `AuxCounters`#footnote[#link("https://github.com/openjdk/jmh/blob/master/jmh-core/src/main/java/org/openjdk/jmh/annotations/AuxCounters.java");] to ensure it is measured for exactly the same case as the CPU benchmarks.

For the 100 times consecutively written real-world benchmark the memory usage is as shown in . The `avl2` types are used for the leftmost and rightmost descendant cache which indicates that optimizing these would improve memory usage considerably, see . The `ComplexAVLTreeNode` is created for every batched node and the `AVLTreeNode` is needed for the AVL lookup tree and also created for every batched node. The byte arrays \(`[B`) in combination with `StringBuilder` are used to store the underlying text. The `ComplexAVLMessage` stores the history of all messages. The `HashMap$Node`, `[Lscala.collection.mutable.HashMap$Node`, `Tuple2` and `SimpleID` are used to associate IDs with the respective nodes. The `RedBlackTree` and `TreeSet` are used for multiple same-side children and for quickly retrieving the correct node when a batching node has been split. The `FixtureOperation` is the underlying test data and therefore does not count towards the memory usage when measuring the memory usage difference before and after running the test.

#benchmarkResults("complexavl-extra-large-local-real-world", [Benchmark results for repeatedly concatenated real world text inserted locally with the \glsfmttext{batching AVL algorithm])

#benchmarkResults("complexavl-extra-large-remote-real-world", [Benchmark results for repeatedly concatenated real world text inserted remotely with the \glsfmttext{batching AVL algorithm])

== Results
<results>
already looked at performance edge cases and artificial cases which are important to cover in the context of decentralized algorithms, so there is no case that could severely reduce the performance of the algorithm which could lead to it becoming unusable. Otherwise, edit actions that hit such an edge case by chance, attackers, or even just a large amount of activity could lead to this slowdown.

shows the real world text repeated 100 times to match benchmark B4x100 from Jahns benchmark framework#footnote[#link("https://github.com/dmonad/crdt-benchmarks/");];. shows the same but simulating that the edit operations are received from a remote replica. Both benchmarks show that operations are performant independent of the text size with one microsecond per operation. Memory usage is acceptable with about 25 bytes per operation but could likely be improved further.

A real world editing trace with #emph[concurrent edits] in an offline context would be useful to analyze performance in that case, but unfortunately we are not aware of such a dataset. As our algorithm has a time complexity of $O (n log (n))$ for $n$ character operations #emph[in all cases] this would only allow more accurate measurements, for example for the expected memory usage per operation.

== Investigating Prior Benchmarks
<investigating-prior-benchmarks>
The prior benchmarks based on Jahns benchmark framework#footnote[#link("https://github.com/dmonad/crdt-benchmarks/");] have several issues. First, they do not give any indication about asymptotic behavior as they are only executed with one relatively small choice for $N$ which parameterizes the repetition of operations or client count. Optimizing asymptotic behavior is much harder in general than achieving acceptable performance for the common choice of $N = 6000$ on modern CPUs with multiple billion instruction cycles per second. Also, they do not use a trusted benchmark framework but use self-written warmup and benchmark code which is likely affecting the accuracy of the benchmark as they run in the context of a JIT compiler similar to the JVM. The JMH framework is designed to have as accurate results as possible.
