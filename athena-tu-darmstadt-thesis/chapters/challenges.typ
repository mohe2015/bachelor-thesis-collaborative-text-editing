#import "../utils.typ": evil-edge-case, gls, glspl
= Challenges with Collaborative Text Editing
<chapter:challenges>
This chapter first introduces the goal of user intent-preservation by showing the problem of text interleaving in @section:challenges-text-interleaving.
Then, @section:challenges-text-interleaving-fugue introduces the solution proposed by Fugue @2023-weidner-minimizing-interleaving to solve text interleaving.
Finally, @chapter:ot compares @crdt:pl and @ot and shows that the current @crdt:pl runtime complexity is quadratic and current @ot algorithms are unsuitable for #emph[non-realtime] editing.

== Text Interleaving
<section:challenges-text-interleaving>
When users write text in a collaborative text editor, they expect that their text is not modified in an unexpected way by concurrent edits from other users.
One example are insertions at #emph[different] positions.
Starting with the text `"Alice plays Minecraft"`, #text(
  fill: red,
)[Alice] changes the text to `"Alice `#text(
  fill: red,
)[`happily`]` plays Minecraft"`.
Concurrently, #text(
  fill: blue,
)[Bob] changes the text to `"Alice plays Minecraft `#text(
  fill: blue,
)[`with Bob`]`"`.
Then, the expected result after synchronizing is `"Alice `#text(
  fill: red,
)[`happily`]` plays Minecraft `#text(fill: blue)[`with Bob`]`"`.
As the insertions are at different positions in the text, the expected outcome is unambiguous, and all characters should stay at their relative position to the surrounding characters.
Users also expect that text they wrote in one go is not interleaved by text that another user wrote concurrently.
An example with insertions at the #emph[same] position is the following.
Starting with the text `"milk, chocolate"`, #text(
  fill: red,
)[Alice] changes the text to `"milk, `#text(
  fill: red,
)[`eggs,`]` chocolate"` and #text(
  fill: blue,
)[Bob] concurrently changes the text to `"milk, `#text(
  fill: blue,
)[`bread,`]` chocolate"`.
The expected result after synchronizing is either `"milk, `#text(
  fill: red,
)[`eggs,`]` `#text(fill: blue)[`bread,`]` chocolate"` or `"milk, `#text(
  fill: blue,
)[`bread,`]` `#text(fill: red)[`eggs,`]` chocolate"`.
While there are two possibilities in this case, no interleaving occurs in either case.

#figure(
  image("/figures/forward-more-important-than-backward.drawio.pdf"),
  caption: [
    Example for prioritizing forward insertions inspired by Figure 6 in Fugue @2023-weidner-minimizing-interleaving
  ],
)
<fig:forward-more-important-than-backward>

#pagebreak()
For an insertion in the middle of a text, current editing behavior does not convey whether the insertion semantically belongs to the left side or the right side.
Because most text is written in a forward direction, so for left-to-right script from left to right, it is more likely that an insertion in the middle of some text is appending to the left side of the insertion point instead of prepending to the right side of the insertion point.
@fig:forward-more-important-than-backward exemplifies this.
The three replicas #text(fill: red)[Alice], #text(fill: blue)[Bob] and #text(
  fill: rgb(38, 162, 105),
)[Carol] independently add three lists to some text.
Then, #text(fill: red)[Alice] and #text(fill: rgb(
  38,
  162,
  105,
))[Carol] synchronize.
Afterwards, #text(fill: red)[Alice] adds `"`#text(
  fill: red,
)[`* Alpacas`]`"` to her list, such that it comes after `"`#text(
  fill: red,
)[`Animals:`]`"` and before `"`#text(fill: rgb(
  38,
  162,
  105,
))[`Colors:`]`"` but inherently there is no information to which part it belongs.
Finally, #text(fill: red)[Alice] and #text(fill: blue)[Bob] synchronize.
This separates `"`#text(fill: red)[`* Alpacas`]`"` and `"`#text(fill: rgb(
  38,
  162,
  105,
))[`Colors:`]`"` by the received `"`#text(
  fill: blue,
)[`Bands:`]`"`, which may not be wanted.
In this example the assumption of the more common forward insertion is correct though.
Further improvements to this would need analysis of the language semantics of the text which #cite(
  <2023-bauwens-nlp-for-merging>,
  form: "author",
) looked into @2023-bauwens-nlp-for-merging.
For the concrete example, a different idea could be to insert `"`#text(
  fill: blue,
)[`Bands:`]`"` after `"`#text(fill: rgb(
  38,
  162,
  105,
))[`Colors:`]`"` so `"`#text(
  fill: red,
)[`* Alpacas`]`"` stays in place in relation to the text preceding and following it.
Unfortunately this would lead to even more unexpected behavior for example when #text(
  fill: blue,
)[Bob] and #text(fill: rgb(
  38,
  162,
  105,
))[Carol] synchronized before and would order the entries alphabetically because they do not know about the insertion of `"`#text(
  fill: red,
)[`* Alpacas`]`"`.
As soon as #text(
  fill: red,
)[Alice] would then synchronize with them, the entries would need to be reordered, so that they converge.
As the synchronized data is not structured like the example may suggest, but instead consists of arbitrary characters, this reordering could result in sentence reordering or other unwanted results.
Another idea could be to prefer the side by the same replica.
This has similar issues if concurrent edits are received later and change the effect of that rule.

== Fugues Approach to Avoid Text Interleaving
<section:challenges-text-interleaving-fugue>
This section shows the proposed solution by Fugue @2023-weidner-minimizing-interleaving to solve text interleaving.
It also gives an example that the proposed #emph[maximally non-interleaving] property can still interleave text when deletions are involved.

#cite(<2023-weidner-minimizing-interleaving>, form: "author")
@2023-weidner-minimizing-interleaving show that a previous attempt at formalizing a property for non-interleaving by
#cite(<2019-Kleppmann-incorrect-noninterleaving-property>, form: "author")
@2019-Kleppmann-incorrect-noninterleaving-property is incorrect @2023-weidner-minimizing-interleaving[Section 2.5].
Therefore, they propose their own property which they refer to as #emph[maximally non-interleaving].
It associates every inserted character with the character to its left and right, which they label left and right origin.
The property orders the characters by prioritizing keeping the left origin as the previous character because of the common forward insertions and otherwise ordering to preserve the right origin as the following character if possible.
Only if both origins are the same, the order is arbitrary but deterministically chosen.
Therefore, this property creates a unique order aside from tie-breaking @2023-weidner-minimizing-interleaving[Section 4.5].

Fugue refers to an interleaving issue as forward interleaving, when only one character has another character as a left origin, yet the two characters are not consecutive.
One example where the Logoot algorithm @2009-weiss-logoot interleaved characters, which also violates this rule, is concurrently inserting `"`#text(
  fill: blue,
)[`bread`]`"` and `"`#text(fill: red)[`eggs`]`"`, producing `"`#text(
  fill: blue,
)[`b`]#text(fill: red)[`e`]#text(fill: blue)[`r`]#text(fill: red)[`g`]#text(
  fill: blue,
)[`e`]#text(fill: red)[`g`]#text(fill: blue)[`a`]#text(fill: red)[`s`]#text(
  fill: blue,
)[`d`]`"` @2019-sun-difference-ot-crdt-2-correctness-complexity[Section 4.4.1].
For example the `"`#text(fill: blue)[`r`]`"` from `"`#text(
  fill: blue,
)[`bread`]`"` has the `"`#text(
  fill: blue,
)[`b`]`"` as its left origin and no other character has the `"`#text(
  fill: blue,
)[`b`]`"` as its left origin but in the result they are not consecutive characters.

#cite(
  <2023-weidner-minimizing-interleaving>,
  form: "author",
) refer to another problem that many prior algorithms exhibit as backward interleaving.
When two insertions have the same left origin but a different right origin, they should be ordered in a way that they are consecutive with their right origins.
Although it may seem this is not a common use case, the following is a plausible example @2023-weidner-minimizing-interleaving[Figure 2].
Starting with the text `"Shopping"`, #text(
  fill: red,
)[Alice] first appends `"`#text(
  fill: red,
)[`* apples`]`"` after `"Shopping"` and then prepends `"`#text(
  fill: red,
)[`Fruit:`]`"` before `"`#text(fill: red)[`* apples`]`"`.
While semantically she is prepending, both inserted texts have `"Shopping"` as their left origin and different right origins.
Concurrently, #text(fill: blue)[Bob] first appends `"`#text(
  fill: blue,
)[`* bread`]`"` after `"Shopping"` and then prepends `"`#text(
  fill: blue,
)[`Bakery:`]`"` before `"`#text(fill: blue)[`* bread`]`"`.
The category insertions by #text(fill: red)[Alice] and #text(
  fill: blue,
)[Bob] both have `"Shopping"` as their left origin but different right origins.
Therefore, this should lead to either the outcome of `"Shopping`#text(
  fill: red,
)[`Fruit:* apples`]#text(fill: blue)[`Bakery:* bread`]`"` or `"Shopping`#text(
  fill: blue,
)[`Bakery:* bread`]#text(
  fill: red,
)[`Fruit:* apples`]`"` which only differ in the order of which users text comes first, which is arbitrary.
When algorithms exhibit backward interleaving, `"Shopping`#text(
  fill: blue,
)[`Bakery:`]#text(fill: red)[`Fruit:`]#text(fill: blue)[`* bread`]#text(
  fill: red,
)[`* apples`]`"` can be a possible result.
Note that the order of the elements has not changed in relation to each other (e.g.
`"`#text(fill: red)[`Fruit:`]`"` comes before `"`#text(
  fill: red,
)[`* apples`]`"` and after `"Shopping"`) but this still violates the intent of the user.

According to #cite(
  <2023-weidner-minimizing-interleaving>,
  form: "author",
), many popular algorithms they looked into exhibit either forward or backward interleaving @2023-weidner-minimizing-interleaving[Table 1].
A review by
#cite(<2023-sun-critical-examination-fugue-ot>, form: "author")
@2023-sun-critical-examination-fugue-ot@2023-sun-critical-examination-fugue-ot-1@2023-sun-critical-examination-fugue-ot-2@2023-sun-critical-examination-fugue-ot-3 that refutes these claims for OT algorithms is addressed in @chapter:ot.
For Logoot @2009-weiss-logoot the character-by-character interleaving issue occurs.
Further examples are provided in the appendix of the Fugue paper @2023-weidner-minimizing-interleaving.
While the prior @crdt algorithms YjsMod#footnote[#link(
  "https://github.com/josephg/reference-crdts",
)] and Sync9#footnote[#link(
  "https://braid.org/sync9",
)] do not exhibit interleaving @2023-weidner-minimizing-interleaving[Table 1], those approaches were not considered here due to the lack of documentation and their intrinsic complexity.
#cite(
  <2023-weidner-minimizing-interleaving>,
  form: "author",
) propose their own algorithms Fugue and FugueMax to solve these problems.
They conjecture that Sync9 is semantically equivalent to Fugue and YjsMod is semantically equivalent to FugueMax @2023-weidner-minimizing-interleaving[Section 6].
They also prove that FugueMax fulfills the #emph[maximally non-interleaving] property @2023-weidner-minimizing-interleaving[Theorem 9], prove that the Fugue algorithm is always forward non-interleaving @2023-weidner-minimizing-interleaving[Lemma 7] and argue that it is also backward non-interleaving when there are not multiple interacting concurrent updates @2023-weidner-minimizing-interleaving[Section 4.3].

A counter example that interleaving can also happen for the #emph[maximally non-interleaving] FugueMax algorithm is the following.
Starting with the text `"Shopping"`, #text(fill: red)[Alice] appends `"`#text(
  fill: red,
)[`* apples`]`"` after `"Shopping"` and then prepends `"`#text(
  fill: red,
)[`Fruit:`]`"` before `"`#text(fill: red)[`* apples`]`"`.
Concurrently, #text(fill: blue)[Bob] appends `"`#text(
  fill: blue,
)[`* bread`]`"` after `"Shopping"`, then deletes and reinserts the `"`#text(
  fill: blue,
)[`g`]`"` of `"Shopping"` and finally prepends `"`#text(
  fill: blue,
)[`Bakery:`]`"` before `"`#text(fill: blue)[`* bread`]`"`.
The expected result would be `"Shoppin`#text(
  fill: blue,
)[`gBakery:* bread`]#text(
  fill: red,
)[`Fruit:* apples`]`"` but the actual result can be `"Shoppin`#text(
  fill: blue,
)[`gBakery:`]#text(fill: red)[`Fruit:* apples`]#text(
  fill: blue,
)[`* bread`]`"` when the replicas IDs have a specific order.
The code in @appendix:code-fuguemax-interleaving verifies this with the reference implementation#footnote[#link(
  "https://github.com/mweidner037/fugue",
)].
The reason the #emph[maximally non-interleaving] property does not cover this case is that it disregards deletions.
This example shows that this simplification is not suitable to ensure non-interleaving.

The basic implementation of Fugue has a linear runtime per character insertion or deletion in relation to the text length (including deleted text) which proved to be too inefficient for larger text given the resulting runtime scales quadratically with the text length.
Comparing the results#footnote[#link(
  "https://github.com/mweidner037/fugue/blob/main/results_table.md",
)] from #cite(
  <2023-weidner-minimizing-interleaving>,
  form: "author",
) for benchmark B1.1 with benchmark B1.3 indicates, that even the optimized variant in the Fugue paper has quadratic runtime for sequential backward insertions.

#pagebreak()
#figure(image("/figures/ot.drawio.pdf"), caption: [
  Example for operation transformation with two synchronizing peers based on figure by #cite(
    <2024-sun-ot-faq>,
    form: "author",
  )
  @2024-sun-ot-faq[Section 1.4 Figure 1]
])
<fig:ot-example>

#figure(
  [```text
    Tii(Ins[p1,c1], Ins[p2, c2]) {
      if p1 < p2 or (p1 = p2 and u1 > u2)
        return Ins[p1, c1];
      else
        return Ins[p1+1, c1];
    }
    ```

  ],
  caption: [
    Example for transformation function from Sun
    @2024-sun-ot-faq[Section 2.15]
  ],
)
<lst:example-transformation-function>

#pagebreak()
== OT in Comparison to CRDTs
<chapter:ot>
This section explains the differences and similarities between @ot and @crdt:pl and shows that the current @crdt:pl runtime complexity is quadratic and current @ot algorithms are unsuitable for #emph[non-realtime] editing.

While @crdt papers often claim @crdt:pl are superior to @ot, @crdt:pl often miss major relevant parts of the required algorithmic steps which makes them seem potentially simpler and more performant @2019-sun-difference-ot-crdt-1-general-transformation-framework[page 2].
For example, @crdt:pl need to extract the text from their internal state and need to be able to address characters based on their text position as most text editors work that way @2019-sun-difference-ot-crdt-1-general-transformation-framework[Section 5.1, Section 5.2].
@crdt:pl often miss this conversion step which is a major algorithmic complication that also affects their performance a lot @2019-sun-difference-ot-crdt-1-general-transformation-framework[page 2].
Note that Fugue also has this issue as it does not describe converting the received operations to character offsets @2023-weidner-minimizing-interleaving[Algorithm 1].

#cite(
  <2019-sun-difference-ot-crdt-1-general-transformation-framework>,
  form: "author",
)
also show that both approaches are more similar than often presented @2019-sun-difference-ot-crdt-1-general-transformation-framework[Section 4.1 Table 1].
While @ot:pl have position based operations directly on the character sequence that are then transformed by concurrent operations, @crdt:pl have identifier based operations on an internal object sequence, that are converted to the position based character sequence after the operations have been applied.

@ot based algorithms consist of a control algorithm and a transformation function @2024-sun-ot-faq.
The control algorithm is generic, and the transformation function is application specific.
For example for plain text editing there could be two operations, Insert(index, character) and Delete(index).
The transformation function $T\(O_2\,O_1\)$ transforms $O_2$ against $O_1$.
This produces the operation that needs to be applied after $O_1$ if they were concurrent before.
@fig:ot-example shows an example where the positions of the concurrent operations are transformed when receiving them and therefore result in the same text at both peers.
In that example the transformation function could be defined as shown in @lst:example-transformation-function for transforming two insert operations @2024-sun-ot-faq[Section 2.15].
If a concurrent insertion happened at a position after the current insertion it does not need to be transformed.
If a concurrent insertion happened at a position before the current insertion it needs to be offset by one.
For equal positions, tie breaking using the replica identifier is required.

The control algorithms decide in which order operations need to be transformed to achieve the desired outcome @2024-sun-ot-faq[Section 2.2].
Depending on the control algorithm, the transformation function needs to fulfill different properties to ensure correctness @2024-sun-ot-faq[Section 2.20].
Also, some control algorithms are able to handle undo, some can undo arbitrary actions out of order, while some cannot @2024-sun-ot-faq[Section 2.12].

Transformation functions need to be defined for all possible combinations of operations.
This means $N^2$ such functions are needed for $N$ possible operations.
An alternative proposed by
#cite(
  <2019-sun-difference-ot-crdt-3-building-real-world-applications>,
  form: "author",
)
is POT+COA (Primitive Operation Transformation plus Complex Operation Adaptation).
It consists of having some primitive operations for which transformation functions are defined, and then complex application operations are converted to these primitive operations @2019-sun-difference-ot-crdt-3-building-real-world-applications[Section 2.1.3].

OT based algorithms can be integrated into existing editors with little change of the editors source code as OT is operation and concurrency-centric.
The algorithm can just apply the received and transformed operations to the local editor and send local operations to other peers.
#cite(
  <2019-sun-difference-ot-crdt-3-building-real-world-applications>,
  form: "author",
)
refer to this as Transparent Adaptation (TA) @2019-sun-difference-ot-crdt-3-building-real-world-applications[Section 2.1.2].

According to #cite(
  <2019-sun-difference-ot-crdt-1-general-transformation-framework>,
  form: "author",
), @ot uses a concurrency-centric and direct transformation approach and @crdt uses a content-centric and indirect transformation approach @2019-sun-difference-ot-crdt-1-general-transformation-framework[Section 1].
This has an important consequence for the time and space complexity.
The time and space complexity of @ot for #emph[realtime] editing depends on the number of concurrent operations which are usually small in realtime text editing while the time and space complexity of @crdt depends on the length of the text or even the length of the text including all deleted content which are usually a lot larger @2019-sun-difference-ot-crdt-1-general-transformation-framework[Section 5.3].
The time complexity for prior @ot based algorithms is at least $O\(c\)$ per remote operation @2019-sun-difference-ot-crdt-2-correctness-complexity[Section 3.1.4].
This means quadratic runtime complexity in relation to the operation count for handling some count of operations, which is unusable for #emph[non-realtime] editing because there can be many concurrent operations.
It is important to mention that the time complexity class is relevant.
For example, $O\(log\(upright("text-length-including-deletions")\)\)$ runtime complexity can be equally acceptable to $O\(upright("concurrent-operations")\)$ runtime complexity because $O\(log\(n\)\)$ is growing quite slowly even for extremely large inputs.
Prior research of @crdt:pl mostly managed a linear time complexity or worse except of a paper by #cite(
  <2016-briot-logn-optimization>,
  form: "author",
) which optimizes an @rga adaptation to $O\(log\(n\)\)$ per operation similarly to us @2019-sun-difference-ot-crdt-2-correctness-complexity[Table 4].
However, #cite(
  <2016-briot-logn-optimization>,
  form: "author",
) have not gone into the analysis of performance edge cases prohibiting us from drawing a fair comparison.
Additionally, it is unclear whether they include the conversion of remote operations to character positions.
Furthermore, as the algorithm is based on @rga, it exhibits interleaving @2023-weidner-minimizing-interleaving[Table 1].

While @crdt:pl often seem to be simple and easy to understand, the fundamental concurrency issues which are inherent to unconstrained co-editing also exist there and mixing content and concurrency creates new difficulties with handling them @2019-sun-difference-ot-crdt-2-correctness-complexity[Section~4].
