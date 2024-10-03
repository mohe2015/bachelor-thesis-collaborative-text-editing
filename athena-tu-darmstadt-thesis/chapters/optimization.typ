= Optimizing Common Edit Operations
<optimization>
Based on a theoretical understanding of our base implementation developed from the algorithmic description in the Fugue paper @2023-weidner-minimizing-interleaving[Algorithm~1] we expect quadratic runtime complexity and linear memory usage in relation to the text length. This chapter discusses the implementation of benchmarks to verify the theoretical understanding of the runtime and memory complexity and then proposes optimizations for the implementation based on them.

The Fugue paper already proposes an optimization, but does not go into detail. It proposes to condense sequentially-inserted tree nodes into a single "waypoint" object instead of using one object per node @2023-weidner-minimizing-interleaving[Section 5] but even with their implementation#footnote[#link("https://github.com/mweidner037/fugue");] available, their exact approach is unclear. To avoid premature optimization we analyze the performance and optimize based on that.

The benchmarks also indicate a quadratic runtime complexity for our base implementation.
In , we start with an optimization that combines consecutively inserted characters as that is how most text is written. This leads to good performance for sequentially written text but still quadratic runtime performance for text with realistic editing behavior like corrections and later additions.
In , we create a look-up data structure that can quickly convert between text positions and nodes as that is the main performance bottleneck in the base implementation. This results in $O (l o g (n))$ runtime complexity per operation. Then, we combine both approaches to reduce memory usage using the batching optimization. This leads to the common case being well optimized, but there are still cases that can be quadratic for text of some length.
In we investigate these performance edge cases, and develop optimizations for them to ensure good performance in all cases. This is important so malicious peers or unusual editing behavior can not lead to unusable runtime performance.
Finally, in , we give an overview of the resulting data structure.

#block[
```scala
override def atVisibleIndex(i: Int): SimpleTreeNode[V] = {
  factory.nodes().drop(i).iterator.next
}
```

]
The most basic case is sequential insertion of text which simulates a user that perfectly writes text and never needs to fix any mistakes or add something earlier in the text. Benchmarking our basic implementation called the simple algorithm leads to the result in .

Note: The graphs show the time and memory #emph[per character operation];, thus the total time to handle the character operations grows quadratically in . All graphs with the same border color have the same axis scale to make them comparable.

As shown in almost all the time is spent in `atVisibleIndex`. This matches the repeated linear search to find the element at which we need to insert based on its index in the original algorithm as shown in .

#block[
```scala
final case class BatchingTreeNode(
    rid: RID | Null,
    counter: Int,
    var _values: StringBuilder | Null,
    var offset: Int,
    var to: Int,
    side: Side,
    var parent: BatchingTreeNodeSingle | Null,
    var leftChildrenBuffer: mutable.ArrayBuffer[BatchingTreeNode],
    var rightChildrenBuffer: mutable.ArrayBuffer[BatchingTreeNode],
    var allowAppend: Boolean
)
```

]
== Optimization Using Batching
<sec:optimization-batching>
The optimization that many algorithms already utilize and that the Fugue authors also have hinted at @2023-weidner-minimizing-interleaving[Section 5], is batching sequential insertions by one peer to reduce metadata and memory overhead. In the following section we describe what is needed for that optimization in detail.

The previously used simple ID for tree nodes consists of a replica ID and a counter. To combine sequential tree nodes by the same replica, an offset is added to be able to address single characters for insert and delete operations. This ID that consists of a replica ID, counter and offset is called a batching ID and our algorithm the batching algorithm.

The algorithm intentionally only optimizes consecutive right children or rather forward insertions as that is the most common case. In all cases this is only a best-effort optimization as operations may not be combinable at all, for example if they are from multiple peers.

shows the rough data structure of a node. The `replicaId` and `counter` represent the simple ID part of this node. If the `replicaId` is null, then the value of the `counter` is not relevant. This is the case for the root node. The `_values` reference one `ArrayBuffer` per simple ID, so multiple nodes may reference the same `ArrayBuffer`. This happens when a batching node needs to be split. The `offset` and `to` variables represent which subrange of the `ArrayBuffer` this node represents, so which characters of the text it stores. This means the batching IDs for this node then consist of the simple ID part and each value in the range from `offset` until `to` combined with the character at that index in `_values`. In the tree these are always right children of their predecessor as we optimize forward insertions. The `side` stores if this is a left or right child of its parent, except for the root node where this value does not store anything meaningful. `BatchingTreeNodeSingle` stores a reference to the parent `BatchingTreeNode` combined with the offset into that node at which this node is added. The `leftChildrenBuffer` and `rightChildrenBuffer` store the children in an array. `allowAppend` stores whether appending an element to this node is possible by appending an element to `_values`. This is not allowed for the left part of a split because otherwise batching IDs could be duplicated.

===== Insert operation
<insert-operation>
To insert an element there are the following cases.

===== Case 1: Insert to the right at the right edge of a non-deleted node with the same replica ID where appending is allowed and which does not already have right children
<case-1-insert-to-the-right-at-the-right-edge-of-a-non-deleted-node-with-the-same-replica-id-where-appending-is-allowed-and-which-does-not-already-have-right-children>
This is the easiest and fastest case. It only consists of adding the value to the array of values.

===== Case 2: Insert to the right at the right edge of a non-deleted node with the same replica ID and counter where appending is allowed but which already has right children
<case-2-insert-to-the-right-at-the-right-edge-of-a-non-deleted-node-with-the-same-replica-id-and-counter-where-appending-is-allowed-but-which-already-has-right-children>
Directly appending here is disallowed because otherwise the already existing right children would be at the wrong position. Therefore, add a new right child node that references the existing buffer with correct `offset` and `to` values.

===== Case 3: Insert to the right at the right edge
<case-3-insert-to-the-right-at-the-right-edge>
In this case a new node is added as a right child of the existing node.

===== Case 4: Insert to the left at the left edge
<case-4-insert-to-the-left-at-the-left-edge>
In this case a new node is added as a left child of the existing node.

===== Otherwise:
<otherwise>
In the other cases, so \"Insert to the right not at the right edge\" and \"Insert to the left not at the left edge\" the node needs to be split and inserted at the correct location. Further details about splitting can be found in . As later optimizations combine sequential #emph[deletions];, this also needs to be handled correctly.

===== Delete operation
<delete-operation>
If an element is already deleted because of concurrent actions, nothing needs to be done. Note that also the editor then does not need any updates. Deletion generally needs to split a node into up to three parts \(except if the first or last element is deleted) as there needs to be a node for the part before the deleted element, a node for the deleted element and a node for the part after the deleted element. Later optimizations avoid this for sequential forward and backward deletions by the same replica if both nodes have the same simple ID. Instead, the deleted element is moved to the node containing the other already deleted elements if the parent node has no other right children.

===== Results for sequential insertions
<results-for-sequential-insertions>
Benchmarking the sequential insertions produces the results in . The reason the batching algorithm is so fast in comparison to the simple algorithm is that it mainly needs to append to an `ArrayBuffer` for sequential insertions.

Even though every character insertion only needs to append a character to an `ArrayBuffer`, the memory usage per character is about 100 bytes. This is because it also stores the causal history which is required for properly syncing between peers but is only optimized in the final version later.

The CPU profile in shows that most time is spent in garbage collection. This indicates that allocating elements for the nodes and messages and resizing ArrayBuffers requires extensive CPU time. The profile shows the CPU time, so this affects the realtime less on a multithreaded system than on a single threaded system. Garbage collection makes it harder to optimize the code as the garbage collector creates a non-local performance bottleneck. It may be helpful to look at the allocation profile in .
There are some things like allocations of temporary values for iterators and views that can be optimized away. In our experience this only leads to limited improvements though. It would be easier to use a programming language that does not use a garbage collector or probably not even a JIT compiler to optimize the algorithm to that depth. Still, Scala, Java and the JVM are well-suited to look at the asymptotic performance because memory allocation or cyclic data structures do not need to be considered in contrast to low level languages like C++ or Rust.

===== Results for real world editing trace
<results-for-real-world-editing-trace>
While this results in good performance, it clearly does not cover real world editing behavior. Therefore, we use the dataset from #link("https://github.com/automerge/automerge-perf") which contains 259,778 insertion and deletion operations that produce a text with 104,852 characters. It is the editing trace from the LaTeX~source of #link("https://arxiv.org/abs/1608.03960");.

shows the runtime #emph[per operation] grows linearly and is also extremely slow for only a few tens of thousands of characters. shows that most time is spent in `findElementAtIndex` similar to the simple sequential insertions.
This is because the batching only helps to improve the performance by some factor that is correlated with the size of consecutive insertions. We therefore looked into an approach that fixes the root cause which is the search of the node in the tree that represents the character at a position in the text.

== Optimization Using a Look-Up Datastructure
<sec:optimization-look-up-datastructure>
For this optimization a data structure is needed, that can quickly retrieve the node based on its index in the text and also allows quick insertions and deletions at arbitrary positions. This is similar to a binary search tree with the difference that the index of a node shifts when inserting a node to the left of it. Therefore, instead of storing the index of a node, it stores the size of all \(visible) subnodes in the search tree. Then a binary search on that size finds the insert position. This also means that an insertion needs to update all sizes up to the root. An AVL tree was chosen as the binary search tree because it has logarithmic asymptotic complexity in all cases and more complex and potentially faster binary search trees such as B-trees do not have better asymptotic complexity.
The batching optimization is excluded to be able to isolate the performance changes to the algorithmic changes.

This results in a very low time per character operation as shown in in comparison to the two other approaches with the real world benchmark. As it is not possible to read the values for the simple AVL algorithm there, shows only the simple AVL algorithm with the full text, so much more operations, and a different y-axis scale.
The CPU profile in shows that there is not a single hot location, but execution is distributed over many methods. The memory overhead is still very high, because a new node in the AVL tree and the Fugue tree needs to be created for every character. shows a memory usage of about 250 bytes per character operation. Note that this also includes the full insertion and deletion history and not only the tree itself.

== Combined Optimizations
<combined-optimizations>
Combining the AVL tree optimization and node batching improves the memory usage and runtime. The results are shown in for the real world benchmark. The runtime per operation is one microsecond, thus one million operations can be handled per second. The memory usage per operation is about 25 bytes per operation. This concludes our optimization of the common execution path.

== Performance Edge Cases
<edge-cases>
An optimal algorithm must perform efficiently in #emph[all] cases. Therefore, efficiently handling edge cases is essential. This is important because remote users can send arbitrary operations. Therefore, a malicious user could use that to attack the algorithm and render the text editing unusable. The following are specific cases for our algorithm. Other algorithms need to be analyzed case by case.

===== Edge case with many children
<edge-case-with-many-children>
Child insertions need to be efficient even after many children are inserted at the same side of the same node as shown in with the benchmark results in . Therefore, the children are stored in a `mutable.SortedSet`, so a binary search tree. This results in logarithmic insertion.

#block[
```scala
val firstRightChild = leftOrigin.firstRightChild()
var side: Side | Null = null
val origin = if (firstRightChild == null) {
  side = Side.Right
  leftOrigin
} else {
  side = Side.Left
  firstRightChild.leftmostDescendant()
}
```

]
===== Edge case for insertion to the left of the root
<edge-case-for-insertion-to-the-left-of-the-root>
Another case is repeatedly inserting at position $0$ as shown in with the benchmark results in .
As the root node has a right child after the first insertion, further nodes need to be inserted to the left of that child. To find the node before the child our algorithm retrieves the leftmost descendant of it as shown in . This requires a recursive traversal down the leftmost child, which is a linear operation. Therefore, our algorithm uses a cache for the leftmost descendant of every node in the tree. As all nodes in the path from the node to its leftmost descendant have the same leftmost descendant, one cache is used for this group of nodes. As shown later, it needs to be possible to split the cache up, if a child is inserted somewhere in that path to the left. The cache also uses an AVL tree with the specialty of storing a parent reference in each AVL tree node and the root node storing a reference to the leftmost descendant of all nodes of that AVL tree. Therefore, the leftmost descendant of this group of nodes can be efficiently retrieved and updated, the cache can be efficiently split up by splitting the AVL tree and new nodes can be efficiently inserted.

#block[
```scala
val base = if (rightChildrenBuffer.nn.isEmpty || before.isEmpty) {
  parent
} else {
  BatchingAVLTreeNodeSingle(before.get, before.get.value.to)
    .rightmostDescendant().complexTreeNode
}
```

]
===== Edge case for concurrent insertion to the right
<edge-case-for-concurrent-insertion-to-the-right>
In the edge case in with the benchmark results in the `p` nodes were first inserted and then `c` nodes were inserted concurrent to them. This means for every `c` node insertion, the node needs to be inserted at the correct position in the AVL tree to preserve the correct character ordering. For example as this is a concurrent insertion, the first `c` node needs to be inserted after the subtree of the child to the left of it. Therefore, the last node in the subtree of its left child needs to be retrieved, which requires to get the rightmost descendant of that child as shown in . Therefore, this also needs the optimization as explained for the previous edge case.

===== Edge case for node splitting
<subsection:evil-split>
Splitting a batched node as shown in with the benchmark results in needs to be efficiently handled. The consecutive elements are stored in an `ArrayBuffer` and splitting it would be a linear operation. Therefore, instead of splitting it, nodes reference a subpart of the buffer. This means splitting a node only requires creating and inserting a new node and updating a few references to the buffer start and end, inserting it into the AVL tree and updating the descendant cache. The disadvantage is that the memory for deleted nodes is not reclaimed.

===== Edge case for node splitting with many right children
<edge-case-for-node-splitting-with-many-right-children>
A previous version of the algorithm stored a reference to the parent in each node. Therefore, splitting a node as shown in with the benchmark results in required updating the parent of all its former children. The parent reference is not required for the batching AVL algorithm, therefore it was simply removed.

===== Closing remarks
<closing-remarks>
It is important to note that there is no guarantee this covers all edge cases. Except for formal verification, the most feasible way is to thoroughly look at the source code and check that each possible operation is able to compute in the expected time. Appending to a batched node in our algorithm can be $O (n)$ in the case that the `ArrayBuffer` requires resizing, but our algorithm intentionally targets #emph[amortized] $O (log (n))$ as it is not relevant if a single operation takes a bit longer. Also, resizing the `ArrayBuffer` is fast as it only consists of a memory copy.

All these data structures also lead to a high per-node memory overhead, so it may be interesting if there are better ways to achieve the same performance goal. Note especially the last edge case where almost 1300 bytes are needed per character operation. Through optimization, probably in an ahead-of-time compiled language and not Scala or another JVM based language, this can probably be reduced at least a bit.

#block[
```scala
final case class BatchingAVLTreeNode[V](
  replicaId: RID | Null,
  counter: Int,
  var _values: ArrayBuffer[V] | Null,
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
```

]
== Node Data Structure Including All Optimizations
<final-high-level-code-overview>
In we show our node data structure for the batching AVL algorithm that combines the batching with the look-up tree optimization. The fields that are from the batching node data structure shown in have the same meaning as explained in . For the look-up tree optimization, the `leftDescCache` and `rightDescCache` store an AVL tree for quickly retrieving the respective descendant. The `leftChildrenBuffer` and `rightChildrenBuffer` use a `SortedSet` to insert nodes in $log (n)$ and have an optimization for single or no children to save memory. They also store the children in an `AVLTreeNode` for the fast node retrieval using an AVL tree.
