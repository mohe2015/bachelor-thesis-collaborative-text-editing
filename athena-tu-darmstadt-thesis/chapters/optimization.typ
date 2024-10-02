\chapter{Optimizing Common Edit Operations} \label{optimization}

Based on a theoretical understanding of our base implementation developed from the algorithmic description in the Fugue paper \cite[Algorithm~1]{2023-weidner-minimizing-interleaving} we expect quadratic runtime complexity and linear memory usage in relation to the text length. This chapter discusses the implementation of benchmarks to verify the theoretical understanding of the runtime and memory complexity and then proposes optimizations for the implementation based on them.

The Fugue paper already proposes an optimization, but does not go into detail. It proposes to condense sequentially-inserted tree nodes into a single ``waypoint'' object instead of using one object per node \cite[Section 5]{2023-weidner-minimizing-interleaving} but even with their implementation\footnote{\url{https://github.com/mweidner037/fugue}} available, their exact approach is unclear. To avoid premature optimization we analyze the performance and optimize based on that.

The benchmarks also indicate a quadratic runtime complexity for our base implementation.
In \Cref{sec:optimization-batching}, we start with an optimization that combines consecutively inserted characters  as that is how most text is written. This leads to good performance for sequentially written text but still quadratic runtime performance for text with realistic editing behavior like corrections and later additions.
In \Cref{sec:optimization-look-up-datastructure}, we create a look-up data structure that can quickly convert between text positions and nodes as that is the main performance bottleneck in the base implementation. This results in $O(log(n))$ runtime complexity per operation. Then, we combine both approaches to reduce memory usage using the batching optimization. This leads to the common case being well optimized, but there are still cases that can be quadratic for text of some length.
In \Cref{edge-cases} we investigate these performance edge cases, and develop optimizations for them to ensure good performance in all cases. This is important so malicious peers or unusual editing behavior can not lead to unusable runtime performance.
Finally, in \Cref{final-high-level-code-overview}, we give an overview of the resulting data structure.

\benchmarkResults{simple-sequential-inserts}{Benchmark results for sequential insertions with the \glsfmttext{simple algorithm}}

\begin{listing}
  \begin{minted}{scala}
override def atVisibleIndex(i: Int): SimpleTreeNode[V] = {
  factory.nodes().drop(i).iterator.next
}
\end{minted}
  \caption{Code excerpt of node search based on index for the \protect\glsfmttext{simple algorithm}}
  \label{lst:simple-at-visible-index}
\end{listing}



The most basic case is sequential insertion of text which simulates a user that perfectly writes text and never needs to fix any mistakes or add something earlier in the text. Benchmarking our basic implementation called the \gls{simple algorithm} leads to the result in \Cref{fig:simple-sequential-inserts}.

Note: The graphs show the time and memory \textit{per character operation}, thus the total time to handle the character operations grows quadratically in \Cref{fig:simple-sequential-inserts}. All graphs with the same border color have the same axis scale to make them comparable.

As shown in \Cref{appendix:simple-sequential-inserts-cpu} almost all the time is spent in \texttt{atVisibleIndex}. This matches the repeated linear search to find the element at which we need to insert based on its index in the original algorithm as shown in \Cref{lst:simple-at-visible-index}.

\begin{listing}
  \begin{minted}{scala}
final case class BatchingTreeNode(
    rid: RID | Null,
    counter: Int,
    var \_values: StringBuilder | Null,
    var offset: Int,
    var to: Int,
    side: Side,
    var parent: BatchingTreeNodeSingle | Null,
    var leftChildrenBuffer: mutable.ArrayBuffer[BatchingTreeNode],
    var rightChildrenBuffer: mutable.ArrayBuffer[BatchingTreeNode],
    var allowAppend: Boolean
)
\end{minted}
  \caption{Data structure of batching node}
  \label{lst:data-structure-batching-node}
\end{listing}

\clearpage

\section{Optimization Using Batching} \label{sec:optimization-batching}

The optimization that many algorithms already utilize and that the Fugue authors also have hinted at \cite[Section 5]{2023-weidner-minimizing-interleaving}, is batching sequential insertions by one peer to reduce metadata and memory overhead. In the following section we describe what is needed for that optimization in detail.

The previously used \gls{simple ID} for tree nodes consists of a replica ID and a counter. To combine sequential tree nodes by the same replica, an offset is added to be able to address single characters for insert and delete operations. This ID that consists of a replica ID, counter and offset is called a \gls{batching ID} and our algorithm the \gls{batching algorithm}.

The algorithm intentionally only optimizes consecutive right children or rather forward insertions as that is the most common case. In all cases this is only a best-effort optimization as operations may not be combinable at all, for example if they are from multiple peers.

\Cref{lst:data-structure-batching-node} shows the rough data structure of a node. The \texttt{replicaId} and \texttt{counter} represent the \gls{simple ID} part of this node. If the \texttt{replicaId} is null, then the value of the \texttt{counter} is not relevant. This is the case for the root node. The \texttt{\_values} reference one \texttt{ArrayBuffer} per \gls{simple ID}, so multiple nodes may reference the same \texttt{ArrayBuffer}. This happens when a batching node needs to be split. The \texttt{offset} and \texttt{to} variables represent which subrange of the \texttt{ArrayBuffer} this node represents, so which characters of the text it stores. This means the \gls{batching ID}s for this node then consist of the \gls{simple ID} part and each value in the range from \texttt{offset} until \texttt{to} combined with the character at that index in \texttt{\_values}. In the tree these are always right children of their predecessor as we optimize forward insertions. The \texttt{side} stores if this is a left or right child of its parent, except for the root node where this value does not store anything meaningful. \texttt{BatchingTreeNodeSingle} stores a reference to the parent \texttt{BatchingTreeNode} combined with the offset into that node at which this node is added. The \texttt{leftChildrenBuffer} and \texttt{rightChildrenBuffer} store the children in an array. \texttt{allowAppend} stores whether appending an element to this node is possible by appending an element to \texttt{\_values}. This is not allowed for the left part of a split because otherwise \glspl{batching ID} could be duplicated.

\clearpage

\paragraph{Insert operation}

To insert an element there are the following cases.

\paragraph{Case 1: Insert to the right at the right edge of a non-deleted node with the same replica ID where appending is allowed and which does not already have right children}

This is the easiest and fastest case. It only consists of adding the value to the array of values.

\paragraph{Case 2: Insert to the right at the right edge of a non-deleted node with the same replica ID and counter where appending is allowed but which already has right children}

Directly appending here is disallowed because otherwise the already existing right children would be at the wrong position. Therefore, add a new right child node that references the existing buffer with correct \texttt{offset} and \texttt{to} values.

\paragraph{Case 3: Insert to the right at the right edge}

In this case a new node is added as a right child of the existing node.

\paragraph{Case 4: Insert to the left at the left edge}

In this case a new node is added as a left child of the existing node.

\paragraph{Otherwise:}

In the other cases, so "Insert to the right not at the right edge" and "Insert to the left not at the left edge" the node needs to be split and inserted at the correct location. Further details about splitting can be found in \Cref{subsection:evil-split}. As later optimizations combine sequential \textit{deletions}, this also needs to be handled correctly.

\paragraph{Delete operation}

If an element is already deleted because of concurrent actions, nothing needs to be done. Note that also the editor then does not need any updates. Deletion generally needs to split a node into up to three parts (except if the first or last element is deleted) as there needs to be a node for the part before the deleted element, a node for the deleted element and a node for the part after the deleted element. Later optimizations avoid this for sequential forward and backward deletions by the same replica if both nodes have the same \gls{simple ID}. Instead, the deleted element is moved to the node containing the other already deleted elements if the parent node has no other right children.

\benchmarkResults{simple-complex-sequential-inserts}{Benchmark results for sequential insertions comparing the \glsfmttext{simple algorithm} and the \glsfmttext{batching algorithm}}

\paragraph{Results for sequential insertions}

Benchmarking the sequential insertions produces the results in \Cref{fig:simple-complex-sequential-inserts}. The reason the \gls{batching algorithm} is so fast in comparison to the \gls{simple algorithm} is that it mainly needs to append to an \texttt{ArrayBuffer} for sequential insertions.

Even though every character insertion only needs to append a character to an \texttt{ArrayBuffer}, the memory usage per character is about 100 bytes. This is because it also stores the causal history which is required for properly syncing between peers but is only optimized in the final version later.

The CPU profile in \Cref{appendix:complex-sequential-inserts-cpu} shows that most time is spent in garbage collection. This indicates that allocating elements for the nodes and messages and resizing ArrayBuffers requires extensive CPU time. The profile shows the CPU time, so this affects the realtime less on a multithreaded system than on a single threaded system. Garbage collection makes it harder to optimize the code as the garbage collector creates a non-local performance bottleneck. It may be helpful to look at the allocation profile in \Cref{appendix:complex-sequential-inserts-alloc}.
There are some things like allocations of temporary values for iterators and views that can be optimized away. In our experience this only leads to limited improvements though. It would be easier to use a programming language that does not use a garbage collector or probably not even a JIT compiler to optimize the algorithm to that depth. Still, Scala, Java and the JVM are well-suited to look at the asymptotic performance because memory allocation or cyclic data structures do not need to be considered in contrast to low level languages like C++ or Rust.

\benchmarkResults{simple-complex-real-world}{Benchmark results for real world editing trace comparing the \glsfmttext{simple algorithm} and the \glsfmttext{batching algorithm}}

\paragraph{Results for real world editing trace}

While this results in good performance, it clearly does not cover real world editing behavior. Therefore, we use the dataset from \url{https://github.com/automerge/automerge-perf} which contains 259,778 insertion and deletion operations that produce a text with 104,852 characters. It is the editing trace from the \LaTeX~source of \url{https://arxiv.org/abs/1608.03960}.

\Cref{fig:simple-complex-real-world} shows the runtime \textit{per operation} grows linearly and is also extremely slow for only a few tens of thousands of characters. \Cref{appendix:complex-real-world-cpu} shows that most time is spent in \texttt{findElementAtIndex} similar to the simple sequential insertions.
This is because the batching only helps to improve the performance by some factor that is correlated with the size of consecutive insertions. We therefore looked into an approach that fixes the root cause which is the search of the node in the tree that represents the character at a position in the text.

\benchmarkResults{simple-complex-simpleavl-real-world}{Benchmark results for real world editing trace comparing the \glsfmttext{simple algorithm}, the \glsfmttext{batching algorithm} and the \glsfmttext{simple AVL algorithm}}

\benchmarkResults{simpleavl-real-world}{Benchmark results for real world editing trace with the \glsfmttext{simple AVL algorithm}}

\clearpage

\section{Optimization Using a Look-Up Datastructure} \label{sec:optimization-look-up-datastructure}

For this optimization a data structure is needed, that can quickly retrieve the node based on its index in the text and also allows quick insertions and deletions at arbitrary positions. This is similar to a binary search tree with the difference that the index of a node shifts when inserting a node to the left of it. Therefore, instead of storing the index of a node, it stores the size of all (visible) subnodes in the search tree. Then a binary search on that size finds the insert position. This also means that an insertion needs to update all sizes up to the root. An AVL tree was chosen as the binary search tree because it has logarithmic asymptotic complexity in all cases and more complex and potentially faster binary search trees such as B-trees do not have better asymptotic complexity.
The batching optimization is excluded to be able to isolate the performance changes to the algorithmic changes.

This results in a very low time per character operation as shown in \Cref{fig:simple-complex-simpleavl-real-world} in comparison to the two other approaches with the real world benchmark. As it is not possible to read the values for the \gls{simple AVL algorithm} there, \Cref{fig:simpleavl-real-world} shows only the \gls{simple AVL algorithm} with the full text, so much more operations, and a different y-axis scale.
The CPU profile in \Cref{appendix:simpleavl-real-world-cpu} shows that there is not a single hot location, but execution is distributed over many methods. The memory overhead is still very high, because a new node in the AVL tree and the Fugue tree needs to be created for every character. \Cref{fig:simpleavl-real-world} shows a memory usage of about 250 bytes per character operation. Note that this also includes the full insertion and deletion history and not only the tree itself.

\benchmarkResults{simpleavl-complexavl-real-world}{Benchmark results for real world editing trace comparing the \glsfmttext{simple AVL algorithm} and the \glsfmttext{batching AVL algorithm}}

\section{Combined Optimizations}

Combining the AVL tree optimization and node batching improves the memory usage and runtime. The results are shown in \Cref{fig:simpleavl-complexavl-real-world} for the real world benchmark. The runtime per operation is one microsecond, thus one million operations can be handled per second. The memory usage per operation is about 25 bytes per operation. This concludes our optimization of the common execution path.

\evilEdgeCase{evil-children}{edge case with many children}

\benchmarkResults{complexavl-evil-children}{Benchmark results of an edge case with many children}

\section{Performance Edge Cases} \label{edge-cases}

An optimal algorithm must perform efficiently in \textit{all} cases. Therefore, efficiently handling edge cases is essential. This is important because remote users can send arbitrary operations. Therefore, a malicious user could use that to attack the algorithm and render the text editing unusable. The following are specific cases for our algorithm. Other algorithms need to be analyzed case by case.

\paragraph{Edge case with many children}

Child insertions need to be efficient even after many children are inserted at the same side of the same node as shown in \Cref{fig:edge-case-evil-children-example} with the benchmark results in \Cref{fig:complexavl-evil-children}. Therefore, the children are stored in a \texttt{mutable.SortedSet}, so a binary search tree. This results in logarithmic insertion.

\evilEdgeCase{evil-insert-1}{edge case for insertion to the left of the root}

\benchmarkResults{complexavl-evil-insert-1}{Benchmark results of an edge case for insertion to the left of the root}

\begin{listing}
  \begin{minted}{scala}
val firstRightChild = leftOrigin.firstRightChild()
var side: Side | Null = null
val origin = if (firstRightChild == null) {
  side = Side.Right
  leftOrigin
} else {
  side = Side.Left
  firstRightChild.leftmostDescendant()
}
\end{minted}
  \caption{Code excerpt of an edge case for insertion to the left of the root}
  \label{lst:code-evil-insert-1}
\end{listing}

\paragraph{Edge case for insertion to the left of the root}

Another case is repeatedly inserting at position $0$ as shown in \Cref{fig:edge-case-evil-insert-1-example} with the benchmark results in \Cref{fig:complexavl-evil-insert-1}.
As the root node has a right child after the first insertion, further nodes need to be inserted to the left of that child. To find the node before the child our algorithm retrieves the leftmost descendant of it as shown in \Cref{lst:code-evil-insert-1}. This requires a recursive traversal down the leftmost child, which is a linear operation. Therefore, our algorithm uses a cache for the leftmost descendant of every node in the tree. As all nodes in the path from the node to its leftmost descendant have the same leftmost descendant, one cache is used for this group of nodes. As shown later, it needs to be possible to split the cache up, if a child is inserted somewhere in that path to the left. The cache also uses an AVL tree with the specialty of storing a parent reference in each AVL tree node and the root node storing a reference to the leftmost descendant of all nodes of that AVL tree. Therefore, the leftmost descendant of this group of nodes can be efficiently retrieved and updated, the cache can be efficiently split up by splitting the AVL tree and new nodes can be efficiently inserted.

\clearpage

\evilEdgeCase{evil-insert-2}{edge case for concurrent insertion to the right}

\benchmarkResults{complexavl-evil-insert-2}{Benchmark results of an edge case for concurrent insertion to the right}

\begin{listing}
  \begin{minted}{scala}
val base = if (rightChildrenBuffer.nn.isEmpty || before.isEmpty) {
  parent
} else {
  BatchingAVLTreeNodeSingle(before.get, before.get.value.to)
    .rightmostDescendant().complexTreeNode
}
  \end{minted}
  \caption{Code excerpt of an edge case for concurrent insertion to the right}
  \label{lst:code-evil-insert-2}
\end{listing}

\clearpage

\paragraph{Edge case for concurrent insertion to the right}

In the edge case in \Cref{fig:edge-case-evil-insert-2-example} with the benchmark results in \Cref{fig:complexavl-evil-insert-2} the \texttt{p} nodes were first inserted and then \texttt{c} nodes were inserted concurrent to them. This means for every \texttt{c} node insertion, the node needs to be inserted at the correct position in the AVL tree to preserve the correct character ordering. For example as this is a concurrent insertion, the first \texttt{c} node needs to be inserted after the subtree of the child to the left of it. Therefore, the last node in the subtree of its left child needs to be retrieved, which requires to get the rightmost descendant of that child as shown in \Cref{lst:code-evil-insert-2}. Therefore, this also needs the optimization as explained for the previous edge case.

\evilEdgeCase{evil-split}{edge case for node splitting}

\benchmarkResults{complexavl-evil-split}{Benchmark results of an edge case for node splitting}

\clearpage

\paragraph{Edge case for node splitting} \label{subsection:evil-split}

Splitting a batched node as shown in \Cref{fig:edge-case-evil-split-example} with the benchmark results in \Cref{fig:complexavl-evil-split} needs to be efficiently handled. The consecutive elements are stored in an \texttt{ArrayBuffer} and splitting it would be a linear operation. Therefore, instead of splitting it, nodes reference a subpart of the buffer. This means splitting a node only requires creating and inserting a new node and updating a few references to the buffer start and end, inserting it into the AVL tree and updating the descendant cache. The disadvantage is that the memory for deleted nodes is not reclaimed.

\evilEdgeCase{evil-split-many-right-children}{edge case for node splitting with many right children}

\benchmarkResults{complexavl-evil-split-many-right-children}{Benchmark results of an edge case for node splitting with many right children}

\paragraph{Edge case for node splitting with many right children}

A previous version of the algorithm stored a reference to the parent in each node. Therefore, splitting a node as shown in \Cref{fig:edge-case-evil-split-many-right-children-example} with the benchmark results in \Cref{fig:complexavl-evil-split-many-right-children} required updating the parent of all its former children. The parent reference is not required for the \gls{batching AVL algorithm}, therefore it was simply removed.

\paragraph{Closing remarks}

It is important to note that there is no guarantee this covers all edge cases. Except for formal verification, the most feasible way is to thoroughly look at the source code and check that each possible operation is able to compute in the expected time. Appending to a batched node in our algorithm can be $O(n)$ in the case that the \texttt{ArrayBuffer} requires resizing, but our algorithm intentionally targets \textit{amortized} $O(log(n))$ as it is not relevant if a single operation takes a bit longer. Also, resizing the \texttt{ArrayBuffer} is fast as it only consists of a memory copy.

All these data structures also lead to a high per-node memory overhead, so it may be interesting if there are better ways to achieve the same performance goal. Note especially the last edge case where almost 1300 bytes are needed per character operation. Through optimization, probably in an ahead-of-time compiled language and not Scala or another JVM based language, this can probably be reduced at least a bit.

\begin{listing}
  \begin{minted}{scala}
final case class BatchingAVLTreeNode[V](
  replicaId: RID | Null,
  counter: Int,
  var \_values: ArrayBuffer[V] | Null,
  var offset: Int,
  var to: Int,
  side: Side,
  var leftChildrenBuffer: SortedSet[AVLTreeNode[BatchingAVLTreeNode[V]]]
                          | AVLTreeNode[BatchingAVLTreeNode[V]] | Null,
  var rightChildrenBuffer: SortedSet[AVLTreeNode[BatchingAVLTreeNode[V]]]
                          | AVLTreeNode[BatchingAVLTreeNode[V]] | Null,
  var allowAppend: Boolean,
  var leftDescCache: AVL2TreeNode[AVLTreeNode[BatchingAVLTreeNode[V]]],
  var rightDescCache: AVL2TreeNode[AVLTreeNode[BatchingAVLTreeNode[V]]],
)
\end{minted}
  \caption{Code excerpt of node data structure for \protect\glsfmttext{batching AVL algorithm}}
  \label{lst:final-code}
\end{listing}

\clearpage

\section{Node Data Structure Including All Optimizations} \label{final-high-level-code-overview}

In \Cref{lst:final-code} we show our node data structure for the \gls{batching AVL algorithm} that combines the batching with the look-up tree optimization. The fields that are from the batching node data structure shown in \Cref{lst:data-structure-batching-node} have the same meaning as explained in \Cref{sec:optimization-batching}. For the look-up tree optimization, the \texttt{leftDescCache} and \texttt{rightDescCache} store an AVL tree for quickly retrieving the respective descendant. The \texttt{leftChildrenBuffer} and \texttt{rightChildrenBuffer} use a \texttt{SortedSet} to insert nodes in $log(n)$ and have an optimization for single or no children to save memory. They also store the children in an \texttt{AVLTreeNode} for the fast node retrieval using an AVL tree.
