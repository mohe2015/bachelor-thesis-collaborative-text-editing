#import "@preview/glossarium:0.4.1": gls, glspl 

= Conclusion
<chapter:conclusion>
This thesis shows that efficient collaborative plain text editing in a decentralized and #emph[non-realtime] setting while preserving user intentions is possible. The optimization to logarithmic runtime per operation in relation to the text length ensures that this is also efficient for extremely large text. This thesis also shows that prior benchmarks do not measure asymptotic complexity and do not cover all algorithmic performance edge cases and proposes to include both in future benchmarks. This is especially an issue in decentralized networks, as there is only limited control over all messages and peers can send you messages with malicious content that triggers these edge cases.

The WebRTC implementation shows a practical example of text editing in p2p networks and allows easy experimentation.

shows that interleaving for the #emph[maximally non-interleaving] property #cite(<2023-weidner-minimizing-interleaving>) is indeed possible when deletions are involved. Therefore, a more accurate property should be researched to ensure non-interleaving.

Significant parts that are common in text editing are still missing, the largest being rich text support. Rich text support likely leads to further implementation and optimization challenges, and it is not clear whether these are solvable while preserving the same asymptotic complexity in all cases. Additionally, the preservation of user intentions of formatting actions likely has similar challenges as ensuring non-interleaving has. The interaction of rich text and being able to undo arbitrary actions likely also poses further challenges.

While testing whether the algorithm converges is comparably simple, testing intent preservation and non-interleaving without reimplementing the algorithm in the test is challenging. As testing is a critical part to ensure correctness, more focus needs to be put on testing text editing algorithms.
