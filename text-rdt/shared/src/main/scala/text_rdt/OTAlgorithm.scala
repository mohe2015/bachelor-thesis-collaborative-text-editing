package text_rdt

// https://www3.ntu.edu.sg/scse/staff/czsun/projects/otfaq/

case class OTOperation(context: RID, inner: OperationType) {
    
}

def transform(operationToTransform: OTOperation, operationToTransformAgainst: OTOperation): Option[OperationType] = {
  (operationToTransform, operationToTransformAgainst) match {
    case Tuple2(OTOperation(oContext, OperationType.Insert(oI, oX)), OTOperation(bContext, OperationType.Insert(bI, bX))) => if (oI < bI || (oI == bI && oContext > bContext)) {
      Some(OperationType.Insert(oI, oX))
    } else {
      Some(OperationType.Insert(oI + 1, oX))
    }
    case Tuple2(OTOperation(oContext, OperationType.Insert(oI, oX)), OTOperation(bContext, OperationType.Delete(bI))) => if (oI <= bI) {
      Some(OperationType.Insert(oI, oX))
    } else {
      Some(OperationType.Insert(oI - 1, oX))
    }
    case Tuple2(OTOperation(oContext, OperationType.Delete(oI)), OTOperation(bContext, OperationType.Insert(bI, bX))) => if (oI < bI) {
      Some(OperationType.Delete(oI))
    } else {
      Some(OperationType.Delete(oI + 1))
    }
    case Tuple2(OTOperation(oContext, OperationType.Delete(oI)), OTOperation(bContext, OperationType.Delete(bI))) => if (oI < bI) {
      Some(OperationType.Delete(oI))
    } else if (oI > bI) {
      Some(OperationType.Delete(oI - 1))
    } else {
      None
    }
  }
}

enum OperationType() {
  case Insert(i: Int, x: Char)
  case Delete(i: Int)
}

final case class OTAlgorithm(replicaId: String, val operations: Vector[OTOperation]) {

  val causalBroadcast = CausalBroadcast[OTOperation](replicaId)

  val text: StringBuilder = StringBuilder()

}

object OTAlgorithm {
  given algorithm: CollaborativeTextEditingAlgorithm[OTAlgorithm] with {

    extension (algorithm: OTAlgorithm) {
      override def delete(i: Int): Unit = {
        val message = OTOperation(42, OperationType.Delete(i))

        algorithm.causalBroadcast.addOneToHistory(
          message
        )

        text.deleteCharAt(i)
      }

      override def insert(i: Int, x: Char): Unit = {
        val message = OTOperation(42, OperationType.Insert(i, x))

        algorithm.causalBroadcast.addOneToHistory(
          message
        )

        text.insert(i, x)
      }   

      override def text(): String = {
        text.toString()
      }

      override def sync(other: OTAlgorithm) = {
        algorithm.syncFrom(other)
        other.syncFrom(algorithm)
      }

      override def syncFrom(other: OTAlgorithm) = {
        algorithm.causalBroadcast.syncFrom(other.causalBroadcast, (causalId, message) => {
          val concurrentChanges = algorithm.causalBroadcast.concurrentChanges(causalId)
          println(s"concurrent changes to $causalId ${concurrentChanges}")
        })
      }
    }
  }
}