Text editing is ubiquitous, as it occurs on almost every website, mobile
app, and desktop application. Collaborative text editing avoids manual
synchronization when working together with others on text. This requires
algorithms that can efficiently combine the concurrent edit operations
in an intent-preserving way. Additionally, supporting a wide range of
network scenarios enables offline work in a decentralized manner with
better availability and reliability than with central servers. In this
thesis, we first look at prior solutions for plain text editing and
their ability to preserve user intentions, as users should not
experience unexpected behavior when concurrently editing text. Then, we
improve the benchmarking approach of prior research to estimate
asymptotic complexity and to measure performance of algorithmic edge
cases. Based on that, we propose optimizations for a prior collaborative
text editing algorithm called Fugue. Our optimized algorithm can handle
character insertion and deletion in logarithmic runtime in relation to
the text length and with constant memory usage per character operation.
It uses 25 bytes and one microsecond per operation on four Intel Xeon
Gold vCPUs for a representative text with 25 million operations. We also
develop a local web application as a proof of concept for working on
plain text collaboratively using WebRTC. Additionally, we show that the
maximally non-interleaving property in the Fugue paper can exhibit
interleaving when deletions are involved.
