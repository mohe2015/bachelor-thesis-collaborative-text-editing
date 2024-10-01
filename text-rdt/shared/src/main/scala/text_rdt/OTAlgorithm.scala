package text_rdt

// https://www3.ntu.edu.sg/scse/staff/czsun/projects/otfaq/

case class OTOperation(context: Int, inner: OperationType) {
    
}

 enum OperationType() {
    case Insert(i: Int, x: Char)
    case Delete(i: Int)
 }

final case class OTAlgorithm(replicaId: String, val operations: Vector[OTOperation]) {

  val causalBroadcast = CausalBroadcast[OTOperation](replicaId)

}

object OTAlgorithm {
  given algorithm: CollaborativeTextEditingAlgorithm[OTAlgorithm] with {

    extension (algorithm: OTAlgorithm) {
      override def delete(i: Int): Unit = {
        val message = OTOperation(42, OperationType.Delete(i))

        algorithm.causalBroadcast.addOneToHistory(
          message
        )
      }

      override def insert(i: Int, x: Char): Unit = {
        val message = OTOperation(42, OperationType.Insert(i, x))

        algorithm.causalBroadcast.addOneToHistory(
          message
        )
      }   

      override def text(): String = {
        ???
      }

      override def sync(other: OTAlgorithm) = {
        ???
      }

      override def syncFrom(other: OTAlgorithm) = {
        ???
      }
    }
  }
}