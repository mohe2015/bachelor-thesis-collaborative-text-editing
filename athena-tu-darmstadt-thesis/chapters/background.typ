\chapter{Fugue Algorithm} \label{chapter:background}

This chapter explains how the Fugue algorithm works and is heavily based on the Fugue paper \cite{2023-weidner-minimizing-interleaving}. Then, the next chapter discusses our implementation of Fugue. Further chapters discuss our improvements to the Fugue algorithm. The Fugue algorithm handles insertions and deletions for a list data structure and avoids interleaving. For text editing every list element is a character.

\section{Traversal}

\Cref{fig:fugue-traversal} visualizes the data structure of the algorithm. It is a tree starting with the root node at the top left. The nodes are connected using lines. Lines downwards to the right connect to a right child and lines downwards to the left connect to a left child. A node can have multiple children on each side. For every node except the root node, the first part is the character or whether the character is deleted, followed by a space and the ID of the peer that created that character, a \texttt{\#} symbol and then a counter for that peer that is increasing for every insertion. For example, \texttt{"t A\#1"} is the character \texttt{"t"} by peer \texttt{"A"} with the counter being $1$. The ID of the peer combined with the counter that uniquely identifies an element is called a \gls{simple ID}. The root node is a special node that behaves like a deleted character. To get the current text of the tree, it is traversed starting from the root node by recursively visiting the left children in order, then the value of the node itself and then the right children in order. For the example in \Cref{fig:fugue-traversal}, the traversal starts with the left children of the root node. As there are none, the node itself is visited. As it contains a deleted character, it is ignored. Then the first right child is traversed. Its first left child produces \texttt{"small~"} by the same rules applied recursively. It itself produces \texttt{"t"}. Its right children produces \texttt{"rees"}. Therefore, its whole traversal produces \texttt{"small~trees"}. Then the second right child is traversed in the same way and produces \texttt{"~grow"}. Combining all that will therefore produce the text \texttt{"small~trees~grow"}.

\clearpage

\begin{figure}
  \includegraphics[max width=\textwidth]{../text-rdt/target/pdfs/traversal-example.pdf}
  \caption{Fugue tree traversal}
  \label{fig:fugue-traversal}
\end{figure}

\twoMinipageFigures{../text-rdt/target/pdfs/empty.pdf}
{\caption{Fugue tree with root node}
  \label{fig:fugue-root-node}}
{../text-rdt/target/pdfs/root-right-a.pdf}
{\caption{Insertion of \texttt{"a"} into Fugue tree at index $0$}
  \label{fig:fugue-right-a}}

\section{Initial State}

The initial state consists only of the root node as shown in \Cref{fig:fugue-root-node}. Thus, the tree represents an empty text. The root node for every peer is the same, even though the root node is always created locally at every peer.

\section{Operations}

The chosen operations are insertion and deletion based on an index into the text relative to the start. The reason for choosing that interface is that text editors conform to it. All indices are zero based, so the element at index $0$ is the first element.

\twoMinipageFigures
{../text-rdt/target/pdfs/root-right-ac.pdf}
{\caption{Insertion of \texttt{"c"} into Fugue tree at index $1$}\label{fig:fugue-right-ac}}
{../text-rdt/target/pdfs/root-right-ac-left-b.pdf}
{\caption{Insertion of \texttt{"b"} into Fugue tree at index $1$}\label{fig:fugue-right-ac-left-b}}

\subsubsection{Insert operation}

To insert an element $x$ at a position $i$, the algorithm first creates a new \gls{simple ID}.
A special case is inserting at position $0$. In that case the root node is the left origin of the insertion. To insert the element, it is added as a right child to this left origin. This implies that the root node never has left children as otherwise this would be incorrect based on the tree traversal.
Starting with an empty tree, \Cref{fig:fugue-right-a} shows an insertion at index $0$.

Otherwise, the algorithm traverses through the tree, but only counts the visible elements (the ones that are not deleted) until the node at index $i-1$ is reached.
As this is the node before the index for the insertion, the insertion point is to the right of it. Like in the special case for inserting at position $0$ this is the left origin.
If that node has no right children, it adds the new node as a right child to that left origin.
Starting with the previous tree, \Cref{fig:fugue-right-ac} shows an insertion at index $1$.

Right children are always deterministically but arbitrarily ordered by their replica IDs.
Therefore, if the node already has right children, the new node can not be added to the right while ensuring it is at the correct position.
Instead, the algorithm adds it to the left of the right origin to ensure it gets placed at the correct index. The right origin is the next node (visible or not) in the tree traversal after the left origin. This right origin can not already have left children as otherwise one of them would be the right origin as they come earlier in the tree traversal. Starting with the previous tree, \Cref{fig:fugue-right-ac-left-b} shows an insertion at index $1$.

\twoMinipageFigures{../text-rdt/target/pdfs/concurrent-insert-a.pdf}
{\caption{Fugue tree with text insertion at replica A}
  \label{fig:fugue-concurrent-insert-a}}
{../text-rdt/target/pdfs/concurrent-insert-b.pdf}
{\caption{Fugue tree with text insertion at replica B}
  \label{fig:fugue-concurrent-insert-b}}

\twoMinipageFigures{../text-rdt/target/pdfs/concurrent-insert-both.pdf}{
  \caption{Fugue tree with concurrent insertions after synchronization between replica A and replica B}
  \label{fig:fugue-concurrent-insert-both}}
{../text-rdt/target/pdfs/delete.pdf}{
  \caption{Fugue tree with deletions}
  \label{fig:fugue-delete}
}



\subsubsection{Concurrent insert operation}

Due to concurrent insertions, it may happen that a node has several right or left children. This proceeds in the following way: To transmit the edits to others, the \textit{node identifier} of the inserted node and its \textit{parent}, the \textit{side} at which it is inserted (left or right) and the \textit{value} that is inserted are transmitted using causal broadcast \cite{2023-weidner-minimizing-interleaving}. Causal broadcast, also referred to as causally-ordered multicasting, ensures that a message with an event, that may have causally happened before another event, is sent before that message \cite{2013-tanenbaum-distributed,1991-birman-causal-multicast}. To incorporate remote edits, the received node is added to the own tree based on the parent identifier and side. For example when the edit in \Cref{fig:fugue-concurrent-insert-a} is concurrent with the edit in \Cref{fig:fugue-concurrent-insert-b}, both clients end up with the tree in \Cref{fig:fugue-concurrent-insert-both} which has several right children.
The order of \texttt{"alice"} and \texttt{"bob"} is deterministic based on their replica ID but otherwise unspecified. As there is no choice that is inherently better, it is just important that all clients compute the same tree.

\subsubsection{Delete operation}

\Cref{fig:fugue-delete} shows the deletion of a character. The node to delete, which is calculated from the index in the tree traversal of visible nodes, is simply marked as deleted. If it already was deleted by a concurrent user, the operation does nothing.

\twoMinipageFigures{../text-rdt/target/pdfs/sequential-inserts.pdf}{\caption{Fugue tree with sequential insertions}
  \label{fig:fugue-sequential-inserts}}{../text-rdt/target/pdfs/reverse-sequential-inserts.pdf}{\caption{Fugue tree with reverse sequential insertions}
  \label{fig:fugue-reverse-sequential-inserts}}

\begin{figure}
  \includegraphics[max width=\textwidth]{../text-rdt/target/pdfs/shopping.pdf}
  \caption{Fugue tree for shopping example}
  \label{fig:fugue-shopping}
\end{figure}



\section{Intuitive Reason for Avoiding Interleaving}

Consecutive insertions as shown in \Cref{fig:fugue-sequential-inserts} and reverse consecutive insertions as shown in \Cref{fig:fugue-reverse-sequential-inserts} create a single long branch in the Fugue tree. The intuitive reason this avoids interleaving in these cases is that merging concurrent edits never changes anything within concurrently created trees \cite[Section 4]{2023-weidner-minimizing-interleaving}.

Another reason is that Fugue prefers linking nodes to their left origin because of forward insertions and if there are already existing nodes it links to the right origin instead to avoid ambiguity. \Cref{fig:fugue-shopping} shows that this also keeps parts that were inserted together in one subtree. Note that consecutive right children are combined here to make the figure more readable.