#import "../utils.typ": gls, glspl
= Introduction
<introduction>
Nearly all applications require text editing in some form --- even if just for text entry into a form element.
When we want to make these applications collaborative, those text fields need collaborative text editing.
However, such functionality is not yet easily available.
In contrast to single user text editing, collaborative text editing creates challenges with merging concurrent edit operations and especially handling conflicting edit operations and performance edge cases.
Collaborative text editing algorithms need to handle conflicts in an intent-preserving and converging way.

Prior collaborative solutions require a central server, such as Microsoft~365 and Google Docs, or open source variants such as MediaWiki (which powers Wikipedia), Overleaf, Etherpad, Collabora Online or OnlyOffice.
Needing a central server for text editing can be undesired for several reasons.
First, when the server is operated by a third party it usually requires sending the text to the third party to handle the edit actions.
Second, this creates a dependency on the availability of the server.
The availability can be affected by power outages, cyberattacks, software and hardware failures including the network, overloading or natural disasters.
Third, this also creates a dependency on the reliability or integrity of the server.
Software and hardware failures especially of the storage can destroy the data, cyberattacks and human mistakes can manipulate or destroy the data, natural disasters or fire can destroy the server.
Examples for such issues are OVHcloud's burned down data center, CrowdStrike, the Facebook BGP outage, the Google Cloud UniSuper incident, the XZ Utils backdoor, WannaCry, and many others.

Similarly, the client may not be able to reach the server.
This may be the case when public infrastructure like cell towers is unavailable, because of natural disasters, sabotage, cyberattacks, failure of infrastructure they depend on such as the power grid or for any other reason.
A recent example are the Ahrtal floods.

Decentralized algorithms can adapt to these challenges by functioning in a wide range of network scenarios.
For example, p2p networks work without a central server.
Furthermore, manets and dtns do not require public communication infrastructure at all but instead can utilize Wi-Fi, Bluetooth and other short-range communication technology.

In a decentralized setting there is no guarantee that peers are frequently online.
Therefore, the ability to handle #emph[non-realtime] editing with potentially long periods of offline activity is essential.
This combination of offline and decentralized software is often called local-first software @2019-kleppmann-local-first.

The two major ways in research to approach collaborative text editing are ot and crdts @2019-sun-difference-ot-crdt-1-general-transformation-framework[page 2].
ot algorithms store edit operations based on the text position and therefore need to transform concurrent edit operations against each other to correct the text positions.
Then, the algorithms apply the operations directly to the text.
Prior algorithms for ot are, for example, COT @2009-sun-ot-context-undo and Jupiter @1995-nichols-jupiter.
While some of these are #emph[not] able to work in a decentralized network but need a central server to order changes like Jupiter @1995-nichols-jupiter, a lot of them #emph[are] able to work in a decentralized network like COT @2009-sun-ot-context-undo @2019-sun-difference-ot-crdt-3-building-real-world-applications[Section 4].
Prior ot algorithms have a runtime complexity per remote operation that is linear in the amount of concurrent edit operations @2019-sun-difference-ot-crdt-2-correctness-complexity[Section 3.1.4].
This makes them really efficient for #emph[near-realtime] editing where only few concurrent edit operations occur.
Near-realtime editing means that only short connection interruptions happen @2016-yata-yjs.
For #emph[non-realtime] text editing this leads to a highly inefficient runtime complexity because the many concurrent edit operations must be transformed against each other @2019-sun-difference-ot-crdt-3-building-real-world-applications[Section 1].
Therefore, prior ot algorithms are undesirable for supporting a wide range of network scenarios like dtns.

In contrast, crdts associate parts of the text with identifiers and merge these together on synchronization.
Therefore, they need to convert between identifiers and text positions to handle text edit operations.
Prior algorithms for crdts are, for example, woot @2006-oster-woot, Logoot @2009-weiss-logoot, rgas @2011-roh-rga and Fugue @2023-weidner-minimizing-interleaving. crdts work in decentralized networks, but each prior algorithm has shortcomings that make it undesirable for a general solution.
For example, Logoot @2009-weiss-logoot has quadratic memory use in some cases.
Also, for handling text of some length their runtime complexity is often quadratic or worse in relation to the text length, as with woot @2006-oster-woot, rga @2011-roh-rga and Fugue @2023-weidner-minimizing-interleaving @2019-sun-difference-ot-crdt-1-general-transformation-framework[Section 5.3].

While Fugue @2023-weidner-minimizing-interleaving avoids interleaving issues of prior solutions and works in an offline setting, the current implementation for handling text of some length has quadratic runtime complexity in relation to the text length.

In this thesis, we first investigate suitable algorithms for local-first plain text editing to integrate into our Scala based applications, see @chapter:challenges.
Based on the evaluation of prior solutions in Fugue @2023-weidner-minimizing-interleaving, we consider interleaving the major issue apart from performance issues, see @section:challenges-text-interleaving.
Therefore, we extensively investigate how the Fugue algorithm avoids interleaving by looking at the algorithm, the examples and the proofs in the Fugue paper @2023-weidner-minimizing-interleaving, see @section:challenges-text-interleaving-fugue.
Additionally, we show that the property of #emph[maximally non-interleaving] in the Fugue paper @2023-weidner-minimizing-interleaving still allows interleaving when deletions are involved.
@chapter:ot gives an insight into crdts and ot and their advantages and disadvantages.

Then, @chapter:background describes the Fugue algorithm @2023-weidner-minimizing-interleaving in depth.
@section:implementation discusses our base implementation of Fugue in Scala to be able to experiment with the algorithm and proposes using property tests to ensure the convergence of our implementation.
For easier experimentation and as a showcase we create a local web application to collaboratively edit a text using WebRTC.

The benchmarks in @optimization show that the base implementation has severe performance issues.
Therefore, we optimize our implementation based on our benchmarks and propose optimizations of the Fugue algorithm.
Through the use of binary search trees at relevant places with some use-case specific customizations we achieve amortized logarithmic runtime per character insertion or deletion and thus an amortized runtime of $O\(n log\(n\)\)$ for handling $n$ character operations.
Additionally, we implement batching of sequential insertions to reduce memory usage, which was already roughly mentioned in the Fugue paper without details on the exact implementation @2023-weidner-minimizing-interleaving.
Furthermore, we contribute a benchmark that in comparison to prior work shows the asymptotic runtime and focuses on edge cases in the algorithm that may have performance characteristics different from those of the common execution path.
Specifically, we focus on ensuring that the algorithm also has an acceptable runtime complexity when considering malicious or unexpected behavior of peers.

We evaluate our optimized implementation in @chapter:evaluation and show that we achieve the targeted $O\(n log\(n\)\)$ runtime complexity with a runtime of one microsecond per character operation and memory use of 25 bytes per operation for a realistic editing session on four Intel Xeon Gold vCPU.
Finally, @chapter:future-work shows future work such as rich text editing, and @chapter:conclusion concludes our work.

#block[
  #block[
    Kleppmann, Martin, Adam Wiggins, Peter van Hardenberg, and Mark McGranaghan. 2019.
    “Local-First Software: You Own Your Data, in Spite of the Cloud.”
    #emph[Onward!], 154--78.

  ] <ref-2019-kleppmann-local-first>
  #block[
    Nichols, David A., Pavel Curtis, Michael Dixon, and John Lamping. 1995.
    “High-Latency, Low-Bandwidth Windowing in the Jupiter Collaboration System.”
    #emph[ACM Symposium on User Interface Software and Technology], 111--20.

  ] <ref-1995-nichols-jupiter>
  #block[
    Nicolaescu, Petru, Kevin Jahns, Michael Derntl, and Ralf Klamma. 2016.
    “Near Real-Time Peer-to-Peer Shared Editing on Extensible Data Types.”
    #emph[Proceedings of the 19th International Conference on Supporting Group Work, Sanibel Island, FL, USA, November 13 - 16, 2016], 39--49.
    #link("https://doi.org/10.1145/2957276.2957310").

  ] <ref-2016-yata-yjs>
  #block[
    Oster, Gérald, Pascal Urso, Pascal Molli, and Abdessamad Imine. 2006.
    “Data Consistency for P2P Collaborative Editing.”
    In #emph[Proceedings of the 2006 ACM Conference on Computer Supported Cooperative Work, CSCW 2006, Banff, Alberta, Canada, November 4-8, 2006], edited by Pamela J.
    Hinds and David Martin.
    ACM.
    #link("https://doi.org/10.1145/1180875.1180916").

  ] <ref-2006-oster-woot>
  #block[
    Roh, Hyun-Gul, Myeongjae Jeon, Jinsoo Kim, and Joonwon Lee. 2011.
    “Replicated Abstract Data Types: Building Blocks for Collaborative Applications.”
    #emph[J.
      Parallel Distributed Comput.] 71 (3): 354--68.

  ] <ref-2011-roh-rga>
  #block[
    Sun, Chengzheng, David Sun, Agustina, and Weiwei Cai. 2019.
    “Real Differences Between OT and CRDT Under a General Transformation Framework for Consistency Maintenance in Co-Editors.”
    #emph[CoRR] abs/1905.01518.
    #link("http://arxiv.org/abs/1905.01518").

  ] <ref-2019-sun-difference-ot-crdt-1-general-transformation-framework>
  #block[
    Sun, David, and Chengzheng Sun. 2009.
    “Context-Based Operational Transformation in Distributed Collaborative Editing Systems.”
    #emph[IEEE Trans.
      Parallel Distributed Syst.] 20 (10): 1454--70.
    #link("https://doi.org/10.1109/TPDS.2008.240").

  ] <ref-2009-sun-ot-context-undo>
  #block[
    Sun, David, Chengzheng Sun, Agustina, and Weiwei Cai. 2019a.
    “Real Differences Between OT and CRDT in Building Co-Editing Systems and Real World Applications.”
    #emph[CoRR] abs/1905.01517.
    #link("http://arxiv.org/abs/1905.01517").

  ] <ref-2019-sun-difference-ot-crdt-3-building-real-world-applications>
  #block[
    Sun, David, Chengzheng Sun, Agustina, and Weiwei Cai. 2019b.
    “Real Differences Between OT and CRDT in Correctness and Complexity for Consistency Maintenance in Co-Editors.”
    #emph[CoRR] abs/1905.01302.
    #link("http://arxiv.org/abs/1905.01302").

  ] <ref-2019-sun-difference-ot-crdt-2-correctness-complexity>
  #block[
    Weidner, Matthew, Joseph Gentle, and Martin Kleppmann. 2023.
    “The Art of the Fugue: Minimizing Interleaving in Collaborative Text Editing.”
    #emph[CoRR] abs/2305.00583.
    #link("https://doi.org/10.48550/ARXIV.2305.00583").

  ] <ref-2023-weidner-minimizing-interleaving>
  #block[
    Weiss, Stéphane, Pascal Urso, and Pascal Molli. 2009.
    “Logoot: A Scalable Optimistic Replication Algorithm for Collaborative Editing on P2P Networks.”
    #emph[29th IEEE International Conference on Distributed Computing Systems \(ICDCS 2009), 22-26 June 2009, Montreal, Québec, Canada], 404--12.
    #link("https://doi.org/10.1109/ICDCS.2009.75").

  ] <ref-2009-weiss-logoot>
] <refs>
