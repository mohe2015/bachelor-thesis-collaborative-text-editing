= Future Work
<chapter:future-work>
In this chapter we look at what is missing and which aspects could be
researched further.

===== Investigating OT Algorithms
<investigating-ot-algorithms>
In their review of the Fugue paper, shows that the claims in the Fugue
paper #cite(<2023-weidner-minimizing-interleaving>) about ot being
interleaving are not correct
#cite(<2023-sun-critical-examination-fugue-ot>);#cite(<2023-sun-critical-examination-fugue-ot-1>);#cite(<2023-sun-critical-examination-fugue-ot-2>);#cite(<2023-sun-critical-examination-fugue-ot-3>);.
First, they show that mistakes were made in the Fugue paper when
applying the ot algorithms which render their results regarding ot
invalid
#cite(<2023-sun-critical-examination-fugue-ot-1>);#cite(<2023-sun-critical-examination-fugue-ot-2>);.
They also show that interleaving has been examined and documented before
and can be solved in ot, usually by having operations based on strings
and not single characters, but this is also possible when operating on
single characters #cite(<2023-sun-critical-examination-fugue-ot-2>);.
Therefore, investigating OT algorithms, especially in a
#emph[non-realtime] setting could be interesting.

===== Necessary Non-interleaving Properties for Intent-Preserving Text Editing
<necessary-non-interleaving-properties-for-intent-preserving-text-editing>
The review by also suggests that not all the properties that are
proposed in the Fugue paper \(especially multi-user relay interleaving
and backward interleaving) are necessary or useful for user intent
preserving text editing
#cite(<2023-sun-critical-examination-fugue-ot-2>);. While the examples
we show in and are realistic, we do not know which properties are
strictly necessary, as required properties seriously limit the freedom
in the design of suitable algorithms. For example, the Fugue paper
proposes a property of maximally non-interleaving that produces a unique
order with the least possible interleaving. While it is interesting that
this property produces a unique order it is unclear whether this is
useful in practice. Our example in also shows that this property is not
sufficient for non-interleaving when deletions are involved. Future work
could investigate how this property could be adapted to better model
non-interleaving in such cases.

===== Privacy
<sec:data-privacy-issues>
One big problem we see with all these algorithms is that it is hard or
impossible to properly delete data in case a user wishes to do so while
still being able to converge and preserve user intentions. Future work
could investigate which possibilities exist to actually remove deleted
text. One possibility could be to clear the deleted characters in the
tree. This would also work for the causal broadcast messages but then
undo would not be possible anymore. Therefore, maybe more control is
needed for end users whether they want to do a normal deletion or a
permanent deletion, which would break undo, and also to see which data
is still visible in the internal data structure or in the message log.

As the messages are only required to be processed by the peers
themselves, adding encryption should be comparatively easy. This could
also route messages over a server and store them there without the
server being able to read the contents. Some thought should still be put
into what can be inferred from metadata like message timing and size.
For example, it would likely be possible for the server to find out
which user writes how many characters at what time.

===== Correctness
<section:future-work-correctness>
Currently, there is little protection against messages that do not
conform to the expected rules. For example if two peers send different
characters with the same ID this will create inconsistencies or
potentially also crashes. Also peers can easily send characters for
other peers as the peer ID is not verified to be only used by the
respective peer. This should be tested more, for example using fuzzing
tests that can send arbitrary messages that do not conform to the rules.
Also, inconsistencies by different characters with the same ID should be
avoided, for example by making the character part of the ID.

While our property tests seemed to find all relevant issues, they were
pretty limited for tests with multiple replicas and could not check the
exact expected outcome in that case. Therefore, it may be interesting to
find ways to more thoroughly test this while also testing
non-interleaving.

===== Usability
<future-work-usability>
Rich text is probably the largest missing feature that may also lead to
many design challenges. First, there is inline formatting like bold,
underlined, italic, strike-through, subscript or superscript text. But
there is also structural formatting like headings, subheadings, ordered
and unordered lists, tables, etc. Both create new challenges with user
intent. While for ot there is a lot of previous work which is also
successfully used in production e.g. Google
Docs#footnote[#link("https://www.google.com/docs/about/");];, for crdts
there is not much previous research #cite(<2022-litt-peritext>);. The
Peritext paper #cite(<2022-litt-peritext>) investigates inline
formatting and shows some problems in prior algorithms with correctly
preserving user intentions #cite(<2022-litt-peritext>);. For example the
Yjs algorithm based on yata #cite(<2016-yata-yjs>) adds markers where
inline formatting starts and where it ends into the text. This fails to
handle a simple case where a bold text is unbolded and concurrently part
of that bold text is unbolded which then leads to unrelated text getting
bold #cite(<2022-litt-peritext>)[Section 2.3.2];.

In a collaborative context it needs to be possible to undo arbitrary
actions by any user and not only the last action like it is usually the
case in traditional editors. Therefore, support for so-called selective
undo is needed. For ot algorithms, transformations need to be applied to
the correct document context #cite(<2009-sun-ot-context-undo>);. This
means the control algorithms need to properly handle this and
transformation functions potentially need to uphold specific properties
#cite(<2009-sun-ot-context-undo>);.

When part of a text is moved and concurrently part of that text is
edited it would make sense that these edits are correctly preserved. As
normal copy and paste does not track this state this needs a special
operation or needs to store the necessary metadata in the clipboard.
Also, this needs support at the crdt level
#cite(<2022-anjana-move>);#cite(<2023-kleppmann-json-move>);.

Instead of operating on a character level it could make sense to operate
on a string level. This would be more efficient and could have better
semantics for range deletions, copy and paste or moving text. For ot
this seems to often be done but is much more complicated, especially in
combination with undo #cite(<2024-sun-ot-faq>);.

While we did not look at this in this thesis, it is not hard to
serialize and deserialize our representation. It may be interesting to
find out which parts of the data structures, that are only needed to
improve lookup performance, should be persisted to storage and which
parts can be quickly rebuilt on loading.

===== Performance
<section:future-work-performance>
While in some cases the full editing history needs to be kept to be able
to attribute all changes, in other cases it can be reduced as much as
possible without causing causality problems. The approach of the
antimatter#footnote[#link("https://web.archive.org/web/20240623153539/https://braid.org/antimatter");]
algorithm is to combine operations that have been seen by the same group
of peers by tracking acknowledgements. In case peers go offline but come
online at some point later it can potentially still combine operations.

Our current performance measurements only test non-concurrent actions.
It may be beneficial to either find or create some real-world editing
trace with concurrent actions or generate some artificial trace like in
YATA #cite(<2016-yata-yjs>)[Section 6.1];.

The memory usage per character is pretty high, even for the real world
benchmark. Except for using a low-level language it could also make
sense to investigate how to only create the cache for the leftmost and
rightmost descendant if they are deeply nested which based on would
likely save large amounts of memory.

When the data is larger than the available memory, our algorithm
currently can only be used with swapping. Future work could look into
alternatives, for example to store currently not edited parts to disk.
