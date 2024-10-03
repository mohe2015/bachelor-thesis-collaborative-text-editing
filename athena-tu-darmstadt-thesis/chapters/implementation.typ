= Implementation of Fugue Algorithm
<section:implementation>
This chapter first lists the requirements for an implementation of the
Fugue algorithm in . gives insights into our editor implementation in
the browser and our p2p functionality and explains how our
synchronization works and is optimized. introduces our use of property
tests to ensure convergence of our implementation and argues that
extensive use of assertions for invariants aids in finding the root
cause of test failures. Finally, reveals some small issues in the
algorithmic description in the Fugue paper
#cite(<2023-weidner-minimizing-interleaving>);.

The source code is available at: \
#link("https://github.com/mohe2015/bachelor-thesis-collaborative-text-editing")

== Required Implementation Functionality
<section:implementation-requirements>
Based on the Fugue paper #cite(<2023-weidner-minimizing-interleaving>)
and our explanation of the Fugue algorithm in the last chapter, an
implementation needs to provide the following functionality:

It needs to provide an interface to a tree with left and right children,
possibly multiple children on each side but usually only one on one
side. It requires fast retrieval of a node based on an index in the
non-deleted node traversal and fast retrieval of an index in the
non-deleted node traversal based on the node. Additionally, it requires
fast retrieval of a node based on its ID. For initial loading it also
needs to be able to traverse the whole tree in order. Furthermore,
inserting nodes to the right and left of other nodes needs to be
efficient with the special case of multiple left or right children.

In practice, trees usually contain many deep right descendants because
of consecutive character insertions
#cite(<2023-weidner-minimizing-interleaving>)[Figure 5];, so this is a
case that should be heavily optimized.

#block[
```scala
val schema = Schema(SchemaSpec(orderedmap.from(StringDictionary(
  ("text", NodeSpec()),
  ("doc",
    NodeSpec()
      .setContent("text*")
      .setMarks("")
      .setCode(true)
      .setDefining(true)
      .setParseDOM(
        js.Array(TagParseRule("pre").setPreserveWhitespace(full)))
      .setToDOM(_ => Array("pre", 0)))))))
val hardBreakCommand: Command = (state, dispatch, view) => {
  dispatch.get(state.tr.insertText("\n"))
  true
}
val editorStateConfig = EditorStateConfig().setSchema(schema)
  .setPluginsVarargs(keymap(StringDictionary(("Enter", hardBreakCommand))))
```

]
== Browser Implementation of Text Editor
<section:implementation-browser>
To properly use text editing algorithms an editor is required, so we
implement an interface to
ProseMirror#footnote[#link("https://prosemirror.net/");] and transpile
Scala to JavaScript using
Scala.js#footnote[#link("https://www.scala-js.org/");] to be able to use
our implementation on the web.

By default, ProseMirror creates newlines using `<br/>`~tags and
paragraphs using `<p>`~tags. This makes it complicated to convert
between the ProseMirror document offset and the text offset. Therefore,
we configured ProseMirror to only support plaintext and use `\n` for
newlines and configured the browser to render `\n` as newlines \(which
does not work by default) as shown in .

We also implemented a demo using
WebRTC#footnote[#link("https://webrtc.org/");] to collaboratively edit a
text. It keeps the full history on all connected peers, so it is not
possible to permanently delete anything. This is the reason for not
implementing persistence, see .

== Synchronization of Changes
<sec:synchronization>
The changes are synchronized using causal broadcast as in the Fugue
paper #cite(<2023-weidner-minimizing-interleaving>);. The events are
ordered using vector clocks
#cite(<1988-mattern-vector-clock>);#cite(<1988-fidge-vector-clock>);.
Only change synchronization updates the vector clock. Therefore, the
clock does not need to be updated while working offline, and the changes
can be sent in one batch which is more efficient. Instead of creating a
message per character insertion or deletion, consecutive deletions and
insertions that have the same causality are combined to optimize memory
usage.

== Testing Using Property Tests
<sec:property-tests>
Property tests are a core part of testing rdts as the existence of
numerous edge cases make unit testing infeasible. The tests run both on
the internal data structure, with an interface for inserting and
deleting characters at indices, and on the local web application as a
Playwright#footnote[#link("https://playwright.dev/java/");] test.

The property tests run using
ScalaCheck#footnote[#link("https://scalacheck.org/");] and specifically
its stateful testing
support#footnote[#link("https://github.com/typelevel/scalacheck/blob/main/doc/UserGuide.md#stateful-testing");]
using
`Commands`#footnote[<footnote:commands>#link("https://github.com/typelevel/scalacheck/blob/main/core/shared/src/main/scala/org/scalacheck/commands/Commands.scala");];.
ScalaCheck `Commands` store a system under test and a state that is
compared to the system under test. Possible actions are defined by
implementing the `Command` trait. The trait has several methods for pre
conditions, post conditions, running the action and calculating the next
state. ScalaCheck generates `Command`s and their contents using
Generators, e.g. `Gen.chooseNum(0, Int.MaxValue)` which are then run by
ScalaCheck against the system under test and if failures occur it tries
to simplify the failure case.

Our property tests randomly create replicas, synchronize replicas,
insert text at a replica or delete text at a replica. Then, they check
whether replicas have the same text after they synchronized.
Unfortunately it is not easily possible to check #emph[what] the
expected text would be as that would need more or less a
reimplementation of the synchronization logic, see . We also have
property tests that check that local operations match the same
operations on a `String`.

While trying out new approaches, implementation mistakes are likely,
particularly when more complicated approaches have lots of edge cases.
It is really laborious to find the root cause for every test failure to
fix edge cases, especially for property tests that do not always produce
the smallest possible test case. It helps significantly to add lots of
assertions into the code that not only check local conditions like
traditional uses of assertions but also check global invariants. Some
examples of such assertions are ensuring that parent and child
references are symmetric to each other and that insertions and deletions
correctly update the positions of all characters. These assertions
strongly affect the performance, so they need to be disabled for
production use.

Ideally, invariant assertions would be automatically checked after every
object creation and modification, but that is not easily possible with
Scala. Therefore, they were added manually at relevant places. The tests
also detect the bugs without these invariant assertions. The failure
then happens at a later time in execution, which complicates finding the
root cause, but does not decrease the reliability.

== Issues in the Algorithmic Description
<section:implementation-issues-algorithmic-description>
While working on our implementation, we found that the algorithmic
description #cite(<2023-weidner-minimizing-interleaving>)[Algorithm~1]
is, for the most part, satisfactory. However, it contains one large
issue. While the Fugue paper includes the conversion from character
offsets to their internal representation, it misses the reverse
direction #cite(<2023-weidner-minimizing-interleaving>)[Algorithm~1];.
Received operations also need to be converted to the index to update the
local text editor. Therefore, we extended the algorithmic description
with that. This is not just relevant for implementation but also for
optimization, which we address in the next chapter. It means that
further functionality is required, that can map a node ID to the
position in the tree traversal of visible nodes, which is the visible
text. The remaining issues were only minor or instances of suboptimal
specification.

First, the ID type
#cite(<2023-weidner-minimizing-interleaving>)[Algorithm~1] can always be
`null`. As this can only be the case for the root node, we moved this
case to the places where the root node could potentially be used. There
are some places where this could #emph[not] be the case, e.g. remote
insertions can not send the root node as the root node is always locally
created.

Second, in line 10 of the description
#cite(<2023-weidner-minimizing-interleaving>)[Algorithm~1];, root is
initialized with a value that is invalid according to their
specification because the side can only be `L` or `R` but never `null`
according to the types. Our implementation arbitrarily chooses the root
node to be on the right side to simplify checks at other places in the
code. An alternative would be to use an enumeration for the node and not
have an ID, value, side and parent for the root node at all.

Third, each node does not necessarily need to store the ID of its parent
and children #cite(<2023-weidner-minimizing-interleaving>)[Algorithm~1];.
It could also store a reference directly to them.

Lastly, the node after `leftOrigin` in line 24
#cite(<2023-weidner-minimizing-interleaving>)[Algorithm~1] can be
retrieved as the leftmost descendant of the first right child of the
`leftOrigin`. The leftmost descendant is the node that is reached by
repeatedly descending into the leftmost child until there are no left
children. This is logical as the next node must be in the right subtree
and there the first node is the leftmost node. Depending on the
implementation that may be faster or easier.
