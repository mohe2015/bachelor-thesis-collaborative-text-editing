package text_rdt

// https://www3.ntu.edu.sg/scse/staff/czsun/projects/otfaq/

case class OTOperation(context: RID, inner: OperationType) {
    
}

def transform(operationToTransform: Option[OTOperation], operationToTransformAgainst: OTOperation): Option[OTOperation] = {
  (operationToTransform, operationToTransformAgainst) match {
    case Tuple2(None, other) => None
    case Tuple2(Some(OTOperation(oContext, OperationType.Insert(oI, oX))), OTOperation(bContext, OperationType.Insert(bI, bX))) => if (oI < bI || (oI == bI && oContext < bContext)) {
      Some(OTOperation(oContext, OperationType.Insert(oI, oX)))
    } else {
      Some(OTOperation(oContext, OperationType.Insert(oI + 1, oX)))
    }
    case Tuple2(Some(OTOperation(oContext, OperationType.Insert(oI, oX))), OTOperation(bContext, OperationType.Delete(bI))) => if (oI <= bI) {
      Some(OTOperation(oContext, OperationType.Insert(oI, oX)))
    } else {
      Some(OTOperation(oContext, OperationType.Insert(oI - 1, oX)))
    }
    case Tuple2(Some(OTOperation(oContext, OperationType.Delete(oI))), OTOperation(bContext, OperationType.Insert(bI, bX))) => if (oI < bI) {
      Some(OTOperation(oContext, OperationType.Delete(oI)))
    } else {
      Some(OTOperation(oContext, OperationType.Delete(oI + 1)))
    }
    case Tuple2(Some(OTOperation(oContext, OperationType.Delete(oI))), OTOperation(bContext, OperationType.Delete(bI))) => if (oI < bI) {
      Some(OTOperation(oContext, OperationType.Delete(oI)))
    } else if (oI > bI) {
      Some(OTOperation(oContext, OperationType.Delete(oI - 1)))
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
        val message = OTOperation(algorithm.replicaId, OperationType.Delete(i))

        algorithm.causalBroadcast.addOneToHistory(
          message
        )

        text.deleteCharAt(i)
      }

      override def insert(i: Int, x: Char): Unit = {
        val message = OTOperation(algorithm.replicaId, OperationType.Insert(i, x))

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
          println(s"receiving ${message.toString().replace("\n", "\\n")} from ${other.replicaId} with changes to transform against: ${concurrentChanges.toString().replace("\n", "\\n")}")

          val newOperation: Option[OTOperation] = concurrentChanges.flatMap(_._2).foldLeft(Some(message))(transform)

          newOperation.foreach(operation => operation.inner match {
            case OperationType.Insert(i, x) => text.insert(i, x)
            case OperationType.Delete(i) => text.deleteCharAt(i)
          })
        })
      }
    }
  }
}