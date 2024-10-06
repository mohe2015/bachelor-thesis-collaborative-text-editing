package text_rdt

// https://www3.ntu.edu.sg/scse/staff/czsun/projects/otfaq/#_Toc321146152
// COT would be way to complicated, choose something simpler
// dOPT
// https://dl.acm.org/doi/pdf/10.1145/289444.289469

// https://www3.ntu.edu.sg/scse/staff/czsun/projects/otfaq/#_Toc321146146

// https://arxiv.org/pdf/1905.01302
// 3.1.3 Server-based versus Distributed OT

case class OTOperation(replica: RID, inner: OperationType) { // , contextBefore: String, contextAfter: String
    
}

def inclusionTransform(operationToTransform: Option[OTOperation], operationToTransformAgainst: OTOperation): Option[OTOperation] = {
  val result = inclusionTransformInternal(operationToTransform, operationToTransformAgainst)
  assert(operationToTransform == exclusionTransformInternal(result, operationToTransformAgainst), s"$operationToTransform $operationToTransformAgainst")
  result
}

def inclusionTransformInternal(operationToTransform: Option[OTOperation], operationToTransformAgainst: OTOperation): Option[OTOperation] = {
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

def exclusionTransform(operationToTransform: Option[OTOperation], operationToTransformAgainst: OTOperation): Option[OTOperation] = {
  val result = exclusionTransformInternal(operationToTransform, operationToTransformAgainst)
  assert(operationToTransform == inclusionTransformInternal(result, operationToTransformAgainst))
  result
}

def exclusionTransformInternal(operationToTransform: Option[OTOperation], operationToTransformAgainst: OTOperation): Option[OTOperation] = {
  (operationToTransform, operationToTransformAgainst) match {
    case Tuple2(None, other) => None
    case Tuple2(Some(OTOperation(oContext, OperationType.Insert(oI, oX))), OTOperation(bContext, OperationType.Insert(bI, bX))) => if (oI < bI || (oI == bI && oContext < bContext)) {
      Some(OTOperation(oContext, OperationType.Insert(oI, oX)))
    } else {
      Some(OTOperation(oContext, OperationType.Insert(oI - 1, oX)))
    }
    case Tuple2(Some(OTOperation(oContext, OperationType.Insert(oI, oX))), OTOperation(bContext, OperationType.Delete(bI))) => if (bI < oI || (bI == oI && oContext < bContext)) {
      Some(OTOperation(oContext, OperationType.Insert(oI + 1, oX)))
    } else {
      Some(OTOperation(oContext, OperationType.Insert(oI, oX)))
    }
    case Tuple2(Some(OTOperation(oContext, OperationType.Delete(oI))), OTOperation(bContext, OperationType.Insert(bI, bX))) => if (oI < bI) {
      Some(OTOperation(oContext, OperationType.Delete(oI)))
    } else {
      Some(OTOperation(oContext, OperationType.Delete(oI - 1)))
    }
    case Tuple2(Some(OTOperation(oContext, OperationType.Delete(oI))), OTOperation(bContext, OperationType.Delete(bI))) => if (oI < bI) {
      Some(OTOperation(oContext, OperationType.Delete(oI)))
    } else if (oI > bI) {
      Some(OTOperation(oContext, OperationType.Delete(oI + 1)))
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
        println(inclusionTransformInternal(Some(OTOperation("A",OperationType.Insert(2,'>'))), OTOperation("B",OperationType.Delete(0))))
        println(exclusionTransformInternal(Some(OTOperation("A",OperationType.Insert(1,'>'))), OTOperation("B",OperationType.Delete(0))))

        algorithm.causalBroadcast.syncFrom(other.causalBroadcast, (otherCausalId, otherMessage) => {
          // do we need to find the closest head? I think we should read a paper
          // maybe choosing an arbitrary head should work?

          val selfHead = algorithm.causalBroadcast.cachedHeads(0)

          val concurrentChangesOfOther = other.causalBroadcast.concurrentToAndBefore(selfHead, otherCausalId)

          val concurrentChangesOfSelf = algorithm.causalBroadcast.concurrentToAndBefore(otherCausalId, selfHead)

          //println(s"receiving ${otherMessage.toString().replace("\n", "\\n")} from ${other.replicaId} with changes to transform against: ${concurrentChanges.toString().replace("\n", "\\n")}")

          var newOperation: Option[OTOperation] = concurrentChangesOfOther.flatMap(_._2).foldLeft(Some(otherMessage))(exclusionTransform)

          newOperation = concurrentChangesOfSelf.flatMap(_._2).foldLeft(newOperation)(inclusionTransform)

          newOperation.foreach(operation => operation.inner match {
            case OperationType.Insert(i, x) => text.insert(i, x)
            case OperationType.Delete(i) => text.deleteCharAt(i)
          })
        })
      }
    }
  }
}