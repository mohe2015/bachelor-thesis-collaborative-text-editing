= Introduction
<introduction>
Nearly all applications require text editing in some form — even if just
for text entry into a form element. When we want to make these
applications collaborative, those text fields need collaborative text
editing. However, such functionality is not yet easily available. In
contrast to single user text editing, collaborative text editing creates
challenges with merging concurrent edit operations and especially
handling conflicting edit operations and performance edge cases.
Collaborative text editing algorithms need to handle conflicts in an
intent-preserving and converging way.

Prior collaborative solutions require a central server, such as
Microsoft~365 and Google Docs, or open source variants such as MediaWiki
\(which powers Wikipedia), Overleaf, Etherpad, Collabora Online or
OnlyOffice. Needing a central server for text editing can be undesired
for several reasons. First, when the server is operated by a third party
it usually requires sending the text to the third party to handle the
edit actions. Second, this creates a dependency on the availability of
the server. The availability can be affected by power outages,
cyberattacks, software and hardware failures including the network,
overloading or natural disasters. Third, this also creates a dependency
on the reliability or integrity of the server. Software and hardware
failures especially of the storage can destroy the data, cyberattacks
and human mistakes can manipulate or destroy the data, natural disasters
or fire can destroy the server. Examples for such issues are OVHcloud’s
burned down data center, CrowdStrike, the Facebook BGP outage, the
Google Cloud UniSuper incident, the XZ Utils backdoor, WannaCry, and
many others.

Similarly, the client may not be able to reach the server. This may be
the case when public infrastructure like cell towers is unavailable,
because of natural disasters, sabotage, cyberattacks, failure of
infrastructure they depend on such as the power grid or for any other
reason. A recent example are the Ahrtal floods.

Decentralized algorithms can adapt to these challenges by functioning in
a wide range of network scenarios. For example, p2p networks work
without a central server. Furthermore, manets and dtns do not require
public communication infrastructure at all but instead can utilize
Wi-Fi, Bluetooth and other short-range communication technology.

In a decentralized setting there is no guarantee that peers are
frequently online. Therefore, the ability to handle #emph[non-realtime]
editing with potentially long periods of offline activity is essential.
This combination of offline and decentralized software is often called
local-first software #cite(<2019-kleppmann-local-first>);.

The two major ways in research to approach collaborative text editing
are ot and crdts
#cite(<2019-sun-difference-ot-crdt-1-general-transformation-framework>)[page
2];. ot algorithms store edit operations based on the text position and
therefore need to transform concurrent edit operations against each
other to correct the text positions. Then, the algorithms apply the
operations directly to the text. Prior algorithms for ot are, for
example, COT #cite(<2009-sun-ot-context-undo>) and Jupiter
#cite(<1995-nichols-jupiter>);. While some of these are #emph[not] able
to work in a decentralized network but need a central server to order
changes like Jupiter #cite(<1995-nichols-jupiter>);, a lot of them
#emph[are] able to work in a decentralized network like COT
#cite(<2009-sun-ot-context-undo>)
#cite(<2019-sun-difference-ot-crdt-3-building-real-world-applications>)[Section
4];. Prior ot algorithms have a runtime complexity per remote operation
that is linear in the amount of concurrent edit operations
#cite(<2019-sun-difference-ot-crdt-2-correctness-complexity>)[Section
3.1.4];. This makes them really efficient for #emph[near-realtime]
editing where only few concurrent edit operations occur. Near-realtime
editing means that only short connection interruptions happen
#cite(<2016-yata-yjs>);. For #emph[non-realtime] text editing this leads
to a highly inefficient runtime complexity because the many concurrent
edit operations must be transformed against each other
#cite(<2019-sun-difference-ot-crdt-3-building-real-world-applications>)[Section
1];. Therefore, prior ot algorithms are undesirable for supporting a
wide range of network scenarios like dtns.

In contrast, crdts associate parts of the text with identifiers and
merge these together on synchronization. Therefore, they need to convert
between identifiers and text positions to handle text edit operations.
Prior algorithms for crdts are, for example, woot
#cite(<2006-oster-woot>);, Logoot #cite(<2009-weiss-logoot>);, rgas
#cite(<2011-roh-rga>) and Fugue
#cite(<2023-weidner-minimizing-interleaving>);. crdts work in
decentralized networks, but each prior algorithm has shortcomings that
make it undesirable for a general solution. For example, Logoot
#cite(<2009-weiss-logoot>) has quadratic memory use in some cases. Also,
for handling text of some length their runtime complexity is often
quadratic or worse in relation to the text length, as with woot
#cite(<2006-oster-woot>);, rga #cite(<2011-roh-rga>) and Fugue
#cite(<2023-weidner-minimizing-interleaving>)
#cite(<2019-sun-difference-ot-crdt-1-general-transformation-framework>)[Section
5.3];.

While Fugue #cite(<2023-weidner-minimizing-interleaving>) avoids
interleaving issues of prior solutions and works in an offline setting,
the current implementation for handling text of some length has
quadratic runtime complexity in relation to the text length.

In this thesis, we first investigate suitable algorithms for local-first
plain text editing to integrate into our Scala based applications, see .
Based on the evaluation of prior solutions in Fugue
#cite(<2023-weidner-minimizing-interleaving>);, we consider interleaving
the major issue apart from performance issues, see . Therefore, we
extensively investigate how the Fugue algorithm avoids interleaving by
looking at the algorithm, the examples and the proofs in the Fugue paper
#cite(<2023-weidner-minimizing-interleaving>);, see . Additionally, we
show that the property of #emph[maximally non-interleaving] in the Fugue
paper #cite(<2023-weidner-minimizing-interleaving>) still allows
interleaving when deletions are involved. gives an insight into crdts
and ot and their advantages and disadvantages.

Then, describes the Fugue algorithm
#cite(<2023-weidner-minimizing-interleaving>) in depth. discusses our
base implementation of Fugue in Scala to be able to experiment with the
algorithm and proposes using property tests to ensure the convergence of
our implementation. For easier experimentation and as a showcase we
create a local web application to collaboratively edit a text using
WebRTC.

The benchmarks in show that the base implementation has severe
performance issues. Therefore, we optimize our implementation based on
our benchmarks and propose optimizations of the Fugue algorithm. Through
the use of binary search trees at relevant places with some use-case
specific customizations we achieve amortized logarithmic runtime per
character insertion or deletion and thus an amortized runtime of
$O (n log (n))$ for handling $n$ character operations. Additionally, we
implement batching of sequential insertions to reduce memory usage,
which was already roughly mentioned in the Fugue paper without details
on the exact implementation
#cite(<2023-weidner-minimizing-interleaving>);. Furthermore, we
contribute a benchmark that in comparison to prior work shows the
asymptotic runtime and focuses on edge cases in the algorithm that may
have performance characteristics different from those of the common
execution path. Specifically, we focus on ensuring that the algorithm
also has an acceptable runtime complexity when considering malicious or
unexpected behavior of peers.

We evaluate our optimized implementation in and show that we achieve the
targeted $O (n log (n))$ runtime complexity with a runtime of one
microsecond per character operation and memory use of 25 bytes per
operation for a realistic editing session on four Intel Xeon Gold vCPU.
Finally, shows future work such as rich text editing, and concludes our
work.
