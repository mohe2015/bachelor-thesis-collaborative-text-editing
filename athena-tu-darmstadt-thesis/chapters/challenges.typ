= Challenges with Collaborative Text Editing
<chapter:challenges>
This chapter first introduces the goal of user intent-preservation by
showing the problem of text interleaving in . Then, introduces the
solution proposed by Fugue #cite(<2023-weidner-minimizing-interleaving>)
to solve text interleaving. Finally, compares crdts and ot and shows
that the current crdts runtime complexity is quadratic and current ot
algorithms are unsuitable for #emph[non-realtime] editing.

== Text Interleaving
<section:challenges-text-interleaving>
When users write text in a collaborative text editor, they expect that
their text is not modified in an unexpected way by concurrent edits from
other users. One example are insertions at #emph[different] positions.
Starting with the text `"Alice plays Minecraft"`, Alice changes the text
to `"Alice ``happily`` plays Minecraft"`. Concurrently, Bob changes the
text to `"Alice plays Minecraft ``with Bob``"`. Then, the expected
result after synchronizing is
`"Alice ``happily`` plays Minecraft ``with Bob``"`. As the insertions
are at different positions in the text, the expected outcome is
unambiguous, and all characters should stay at their relative position
to the surrounding characters. Users also expect that text they wrote in
one go is not interleaved by text that another user wrote concurrently.
An example with insertions at the #emph[same] position is the following.
Starting with the text `"milk, chocolate"`, Alice changes the text to
`"milk, ``eggs,`` chocolate"` and Bob concurrently changes the text to
`"milk, ``bread,`` chocolate"`. The expected result after synchronizing
is either `"milk, ``eggs,`` ``bread,`` chocolate"` or
`"milk, ``bread,`` ``eggs,`` chocolate"`. While there are two
possibilities in this case, no interleaving occurs in either case.

#figure([#box(width: \textwidth, image("figures/forward-more-important-than-backward.drawio.pdf"));],
  caption: [
    Example for prioritizing forward insertions inspired by Figure 6 in
    Fugue #cite(<2023-weidner-minimizing-interleaving>)
  ]
)
<fig:forward-more-important-than-backward>

For an insertion in the middle of a text, current editing behavior does
not convey whether the insertion semantically belongs to the left side
or the right side. Because most text is written in a forward direction,
so for left-to-right script from left to right, it is more likely that
an insertion in the middle of some text is appending to the left side of
the insertion point instead of prepending to the right side of the
insertion point. exemplifies this. The three replicas Alice, Bob and
Carol independently add three lists to some text. Then, Alice and Carol
synchronize. Afterwards, Alice adds `"``* Alpacas``"` to her list, such
that it comes after `"``Animals:``"` and before `"``Colors:``"` but
inherently there is no information to which part it belongs. Finally,
Alice and Bob synchronize. This separates `"``* Alpacas``"` and
`"``Colors:``"` by the received `"``Bands:``"`, which may not be wanted.
In this example the assumption of the more common forward insertion is
correct though. Further improvements to this would need analysis of the
language semantics of the text which looked into
#cite(<2023-bauwens-nlp-for-merging>);. For the concrete example, a
different idea could be to insert `"``Bands:``"` after `"``Colors:``"`
so `"``* Alpacas``"` stays in place in relation to the text preceding
and following it. Unfortunately this would lead to even more unexpected
behavior for example when Bob and Carol synchronized before and would
order the entries alphabetically because they do not know about the
insertion of `"``* Alpacas``"`. As soon as Alice would then synchronize
with them, the entries would need to be reordered, so that they
converge. As the synchronized data is not structured like the example
may suggest, but instead consists of arbitrary characters, this
reordering could result in sentence reordering or other unwanted
results. Another idea could be to prefer the side by the same replica.
This has similar issues if concurrent edits are received later and
change the effect of that rule.

== Fugues Approach to Avoid Text Interleaving
<section:challenges-text-interleaving-fugue>
This section shows the proposed solution by Fugue
#cite(<2023-weidner-minimizing-interleaving>) to solve text
interleaving. It also gives an example that the proposed #emph[maximally
non-interleaving] property can still interleave text when deletions are
involved.

#cite(<2023-weidner-minimizing-interleaving>) show that a previous
attempt at formalizing a property for non-interleaving by
#cite(<2019-Kleppmann-incorrect-noninterleaving-property>) is incorrect
#cite(<2023-weidner-minimizing-interleaving>)[Section 2.5];. Therefore,
they propose their own property which they refer to as #emph[maximally
non-interleaving];. It associates every inserted character with the
character to its left and right, which they label left and right origin.
The property orders the characters by prioritizing keeping the left
origin as the previous character because of the common forward
insertions and otherwise ordering to preserve the right origin as the
following character if possible. Only if both origins are the same, the
order is arbitrary but deterministically chosen. Therefore, this
property creates a unique order aside from tie-breaking
#cite(<2023-weidner-minimizing-interleaving>)[Section 4.5];.

Fugue refers to an interleaving issue as forward interleaving, when only
one character has another character as a left origin, yet the two
characters are not consecutive. One example where the Logoot algorithm
#cite(<2009-weiss-logoot>) interleaved characters, which also violates
this rule, is concurrently inserting `"``bread``"` and `"``eggs``"`,
producing `"``b``e``r``g``e``g``a``s``d``"`
#cite(<2019-sun-difference-ot-crdt-2-correctness-complexity>)[Section
4.4.1];. For example the `"``r``"` from `"``bread``"` has the `"``b``"`
as its left origin and no other character has the `"``b``"` as its left
origin but in the result they are not consecutive characters.

refer to another problem that many prior algorithms exhibit as backward
interleaving. When two insertions have the same left origin but a
different right origin, they should be ordered in a way that they are
consecutive with their right origins. Although it may seem this is not a
common use case, the following is a plausible example
#cite(<2023-weidner-minimizing-interleaving>)[Figure 2];. Starting with
the text `"Shopping"`, Alice first appends `"``* apples``"` after
`"Shopping"` and then prepends `"``Fruit:``"` before `"``* apples``"`.
While semantically she is prepending, both inserted texts have
`"Shopping"` as their left origin and different right origins.
Concurrently, Bob first appends `"``* bread``"` after `"Shopping"` and
then prepends `"``Bakery:``"` before `"``* bread``"`. The category
insertions by Alice and Bob both have `"Shopping"` as their left origin
but different right origins. Therefore, this should lead to either the
outcome of `"Shopping``Fruit:* apples``Bakery:* bread``"` or
`"Shopping``Bakery:* bread``Fruit:* apples``"` which only differ in the
order of which users text comes first, which is arbitrary. When
algorithms exhibit backward interleaving,
`"Shopping``Bakery:``Fruit:``* bread``* apples``"` can be a possible
result. Note that the order of the elements has not changed in relation
to each other \(e.g. `"``Fruit:``"` comes before `"``* apples``"` and
after `"Shopping"`) but this still violates the intent of the user.

According to , many popular algorithms they looked into exhibit either
forward or backward interleaving
#cite(<2023-weidner-minimizing-interleaving>)[Table 1];. A review by
#cite(<2023-sun-critical-examination-fugue-ot>);#cite(<2023-sun-critical-examination-fugue-ot-1>);#cite(<2023-sun-critical-examination-fugue-ot-2>);#cite(<2023-sun-critical-examination-fugue-ot-3>)
that refutes these claims for OT algorithms is addressed in . For Logoot
#cite(<2009-weiss-logoot>) the character-by-character interleaving issue
occurs. Further examples are provided in the appendix of the Fugue paper
#cite(<2023-weidner-minimizing-interleaving>);. While the prior crdt
algorithms
YjsMod#footnote[#link("https://github.com/josephg/reference-crdts");]
and Sync9#footnote[#link("https://braid.org/sync9");] do not exhibit
interleaving #cite(<2023-weidner-minimizing-interleaving>)[Table 1];,
those approaches were not considered here due to the lack of
documentation and their intrinsic complexity. propose their own
algorithms Fugue and FugueMax to solve these problems. They conjecture
that Sync9 is semantically equivalent to Fugue and YjsMod is
semantically equivalent to FugueMax
#cite(<2023-weidner-minimizing-interleaving>)[Section 6];. They also
prove that FugueMax fulfills the #emph[maximally non-interleaving]
property #cite(<2023-weidner-minimizing-interleaving>)[Theorem 9];,
prove that the Fugue algorithm is always forward non-interleaving
#cite(<2023-weidner-minimizing-interleaving>)[Lemma 7] and argue that it
is also backward non-interleaving when there are not multiple
interacting concurrent updates
#cite(<2023-weidner-minimizing-interleaving>)[Section 4.3];.

A counter example that interleaving can also happen for the
#emph[maximally non-interleaving] FugueMax algorithm is the following.
Starting with the text `"Shopping"`, Alice appends `"``* apples``"`
after `"Shopping"` and then prepends `"``Fruit:``"` before
`"``* apples``"`. Concurrently, Bob appends `"``* bread``"` after
`"Shopping"`, then deletes and reinserts the `"``g``"` of `"Shopping"`
and finally prepends `"``Bakery:``"` before `"``* bread``"`. The
expected result would be `"Shoppin``gBakery:* bread``Fruit:* apples``"`
but the actual result can be
`"Shoppin``gBakery:``Fruit:* apples``* bread``"` when the replicas IDs
have a specific order. The code in verifies this with the reference
implementation#footnote[#link("https://github.com/mweidner037/fugue");];.
The reason the #emph[maximally non-interleaving] property does not cover
this case is that it disregards deletions. This example shows that this
simplification is not suitable to ensure non-interleaving.

The basic implementation of Fugue has a linear runtime per character
insertion or deletion in relation to the text length \(including deleted
text) which proved to be too inefficient for larger text given the
resulting runtime scales quadratically with the text length. Comparing
the
results#footnote[#link("https://github.com/mweidner037/fugue/blob/main/results_table.md");]
from for benchmark B1.1 with benchmark B1.3 indicates, that even the
optimized variant in the Fugue paper has quadratic runtime for
sequential backward insertions.

#figure([#box(width: \textwidth, image("figures/ot.drawio.pdf"));],
  caption: [
    Example for operation transformation with two synchronizing peers
    based on figure by #cite(<2024-sun-ot-faq>)[Section 1.4 Figure 1]
  ]
)
<fig:ot-example>

#block[
```text
Tii(Ins[p1,c1], Ins[p2, c2]) {
  if p1 < p2 or (p1 = p2 and u1 > u2)
    return Ins[p1, c1];              
  else
    return Ins[p1+1, c1];
}
```

]
== OT in Comparison to CRDTs
<chapter:ot>
This section explains the differences and similarities between ot and
crdts and shows that the current crdts runtime complexity is quadratic
and current ot algorithms are unsuitable for #emph[non-realtime]
editing.

While crdt papers often claim crdts are superior to ot, crdts often miss
major relevant parts of the required algorithmic steps which makes them
seem potentially simpler and more performant
#cite(<2019-sun-difference-ot-crdt-1-general-transformation-framework>)[page
2];. For example, crdts need to extract the text from their internal
state and need to be able to address characters based on their text
position as most text editors work that way
#cite(<2019-sun-difference-ot-crdt-1-general-transformation-framework>)[Section
5.1, Section 5.2];. crdts often miss this conversion step which is a
major algorithmic complication that also affects their performance a lot
#cite(<2019-sun-difference-ot-crdt-1-general-transformation-framework>)[page
2];. Note that Fugue also has this issue as it does not describe
converting the received operations to character offsets
#cite(<2023-weidner-minimizing-interleaving>)[Algorithm 1];.

also show that both approaches are more similar than often presented
#cite(<2019-sun-difference-ot-crdt-1-general-transformation-framework>)[Section
4.1 Table 1];. While ots have position based operations directly on the
character sequence that are then transformed by concurrent operations,
crdts have identifier based operations on an internal object sequence,
that are converted to the position based character sequence after the
operations have been applied.

ot based algorithms consist of a control algorithm and a transformation
function #cite(<2024-sun-ot-faq>);. The control algorithm is generic,
and the transformation function is application specific. For example for
plain text editing there could be two operations, Insert\(index,
character) and Delete\(index). The transformation function
$T (O_2 , O_1)$ transforms $O_2$ against $O_1$. This produces the
operation that needs to be applied after $O_1$ if they were concurrent
before. shows an example where the positions of the concurrent
operations are transformed when receiving them and therefore result in
the same text at both peers. In that example the transformation function
could be defined as shown in for transforming two insert operations
#cite(<2024-sun-ot-faq>)[Section 2.15];. If a concurrent insertion
happened at a position after the current insertion it does not need to
be transformed. If a concurrent insertion happened at a position before
the current insertion it needs to be offset by one. For equal positions,
tie breaking using the replica identifier is required.

The control algorithms decide in which order operations need to be
transformed to achieve the desired outcome
#cite(<2024-sun-ot-faq>)[Section 2.2];. Depending on the control
algorithm, the transformation function needs to fulfill different
properties to ensure correctness #cite(<2024-sun-ot-faq>)[Section 2.20];.
Also, some control algorithms are able to handle undo, some can undo
arbitrary actions out of order, while some cannot
#cite(<2024-sun-ot-faq>)[Section 2.12];.

Transformation functions need to be defined for all possible
combinations of operations. This means $N^2$ such functions are needed
for $N$ possible operations. An alternative proposed by is POT+COA
\(Primitive Operation Transformation plus Complex Operation Adaptation).
It consists of having some primitive operations for which transformation
functions are defined, and then complex application operations are
converted to these primitive operations
#cite(<2019-sun-difference-ot-crdt-3-building-real-world-applications>)[Section
2.1.3];.

OT based algorithms can be integrated into existing editors with little
change of the editors source code as OT is operation and
concurrency-centric. The algorithm can just apply the received and
transformed operations to the local editor and send local operations to
other peers. refer to this as Transparent Adaptation \(TA)
#cite(<2019-sun-difference-ot-crdt-3-building-real-world-applications>)[Section
2.1.2];.

According to , ot uses a concurrency-centric and direct transformation
approach and crdt uses a content-centric and indirect transformation
approach
#cite(<2019-sun-difference-ot-crdt-1-general-transformation-framework>)[Section
1];. This has an important consequence for the time and space
complexity. The time and space complexity of ot for #emph[realtime]
editing depends on the number of concurrent operations which are usually
small in realtime text editing while the time and space complexity of
crdt depends on the length of the text or even the length of the text
including all deleted content which are usually a lot larger
#cite(<2019-sun-difference-ot-crdt-1-general-transformation-framework>)[Section
5.3];. The time complexity for prior ot based algorithms is at least
$O (c)$ per remote operation
#cite(<2019-sun-difference-ot-crdt-2-correctness-complexity>)[Section
3.1.4];. This means quadratic runtime complexity in relation to the
operation count for handling some count of operations, which is unusable
for #emph[non-realtime] editing because there can be many concurrent
operations. It is important to mention that the time complexity class is
relevant. For example,
$O (log (upright("text-length-including-deletions")))$ runtime
complexity can be equally acceptable to
$O (upright("concurrent-operations"))$ runtime complexity because
$O (log (n))$ is growing quite slowly even for extremely large inputs.
Prior research of crdts mostly managed a linear time complexity or worse
except of a paper by which optimizes an rga adaptation to $O (log (n))$
per operation similarly to us
#cite(<2019-sun-difference-ot-crdt-2-correctness-complexity>)[Table 4];.
However, have not gone into the analysis of performance edge cases
prohibiting us from drawing a fair comparison. Additionally, it is
unclear whether they include the conversion of remote operations to
character positions. Furthermore, as the algorithm is based on rga, it
exhibits interleaving
#cite(<2023-weidner-minimizing-interleaving>)[Table 1];.

While crdts often seem to be simple and easy to understand, the
fundamental concurrency issues which are inherent to unconstrained
co-editing also exist there and mixing content and concurrency creates
new difficulties with handling them
#cite(<2019-sun-difference-ot-crdt-2-correctness-complexity>)[Section~4];.
