package text_rdt

import scala.collection.mutable

// https://www3.ntu.edu.sg/scse/staff/czsun/projects/otfaq/#_Toc321146152
// COT would be way to complicated, choose something simpler
// dOPT
// https://dl.acm.org/doi/pdf/10.1145/289444.289469

// https://www3.ntu.edu.sg/scse/staff/czsun/projects/otfaq/#_Toc321146146

// https://arxiv.org/pdf/1905.01302
// 3.1.3 Server-based versus Distributed OT

// I think the causal context can be used as context
case class OTOperation(replica: RID, inner: OperationType, contextBefore: mutable.HashMap[text_rdt.RID, Integer], var contextAfter: mutable.HashMap[text_rdt.RID, Integer]) { // , contextBefore: String, contextAfter: String
    
}

def inclusionTransform(operationToTransform: Option[OTOperation], operationToTransformAgainst: OTOperation): Option[OTOperation] = {
    println(s"inclusion transforming $operationToTransform against $operationToTransformAgainst")
  val result = inclusionTransformInternal(operationToTransform, operationToTransformAgainst)
  println(s"inclusion transformed $operationToTransform against $operationToTransformAgainst to $result")
  // possibly the reverse does not hold
  //assert(operationToTransform == exclusionTransformInternal(result, operationToTransformAgainst), s"IT($operationToTransform, $operationToTransformAgainst) -> $result -> ET($result, $operationToTransformAgainst) -> ${exclusionTransformInternal(result, operationToTransformAgainst)}")
  result
}

def inclusionTransformInternal(operationToTransform: Option[OTOperation], operationToTransformAgainst: OTOperation): Option[OTOperation] = {
  assert(operationToTransform.isEmpty || operationToTransform.get.contextBefore == operationToTransformAgainst.contextBefore, s"${operationToTransform.get.contextBefore} == ${operationToTransformAgainst.contextBefore}")
  val result = (operationToTransform.map(v => (v.replica, v.inner)), (operationToTransformAgainst.replica, operationToTransformAgainst.inner)) match {
    case Tuple2(None, other) => None
    case Tuple2(Some((oReplica, OperationType.Insert(oI, oX))), (bReplica, OperationType.Insert(bI, bX))) => if (oI < bI || (oI == bI && oReplica < bReplica)) {
      Some((oReplica, OperationType.Insert(oI, oX)))
    } else {
      Some((oReplica, OperationType.Insert(oI + 1, oX)))
    }
    case Tuple2(Some((oReplica, OperationType.Insert(oI, oX))), (bReplica, OperationType.Delete(bI))) => if (oI <= bI) {
      Some((oReplica, OperationType.Insert(oI, oX)))
    } else {
      Some((oReplica, OperationType.Insert(oI - 1, oX)))
    }
    case Tuple2(Some((oReplica, OperationType.Delete(oI))), (bReplica, OperationType.Insert(bI, bX))) => if (oI < bI) {
      Some((oReplica, OperationType.Delete(oI)))
    } else {
      Some((oReplica, OperationType.Delete(oI + 1)))
    }
    case Tuple2(Some((oReplica, OperationType.Delete(oI))), (bReplica, OperationType.Delete(bI))) => if (oI < bI) {
      Some((oReplica, OperationType.Delete(oI)))
    } else if (oI > bI) {
      Some((oReplica, OperationType.Delete(oI - 1)))
    } else {
      None
    }
  }
  // TODO unclear, maybe merge the statevectors?
  result.map((replicaId, operationType) => OTOperation(replicaId, operationType, operationToTransformAgainst.contextAfter, mutable.HashMap()))
}

def exclusionTransform(operationToTransform: Option[OTOperation], operationToTransformAgainst: OTOperation): Option[OTOperation] = {
  println(s"exclusion transforming $operationToTransform against $operationToTransformAgainst")
  val result = exclusionTransformInternal(operationToTransform, operationToTransformAgainst)
  println(s"exclusion transformed $operationToTransform against $operationToTransformAgainst to $result")
  //assert(operationToTransform == inclusionTransformInternal(result, operationToTransformAgainst))
  result
}

def exclusionTransformInternal(operationToTransform: Option[OTOperation], operationToTransformAgainst: OTOperation): Option[OTOperation] = {
    assert(operationToTransform.isEmpty || operationToTransform.get.contextBefore == operationToTransformAgainst.contextAfter)
  val result = (operationToTransform.map(v => (v.replica, v.inner)), (operationToTransformAgainst.replica, operationToTransformAgainst.inner)) match {
    case Tuple2(None, other) => None
    case Tuple2(Some((oReplica, OperationType.Insert(oI, oX))), (bReplica, OperationType.Insert(bI, bX))) => if (oI > bI || (oI == bI && oReplica < bReplica)) {
      Some((oReplica, OperationType.Insert(oI, oX)))
    } else {
      Some((oReplica, OperationType.Insert(oI - 1, oX)))
    }
    case Tuple2(Some((oReplica, OperationType.Insert(oI, oX))), (bReplica, OperationType.Delete(bI))) => if (oI >= bI) {
      Some((oReplica, OperationType.Insert(oI + 1, oX)))
    } else {
      Some((oReplica, OperationType.Insert(oI, oX)))
    }
    case Tuple2(Some((oReplica, OperationType.Delete(oI))), (bReplica, OperationType.Insert(bI, bX))) => if (oI > bI) {
      Some((oReplica, OperationType.Delete(oI)))
    } else {
      Some((oReplica, OperationType.Delete(oI + 1)))
    }
    case Tuple2(Some((oReplica, OperationType.Delete(oI))), (bReplica, OperationType.Delete(bI))) => if (oI < bI) {
      Some((oReplica, OperationType.Delete(oI)))
    } else if (oI > bI) {
      Some((oReplica, OperationType.Delete(oI - 1)))
    } else {
      None
    }
  }
  result.map((replicaId, operationType) => OTOperation(replicaId, operationType, operationToTransformAgainst.contextBefore, operationToTransformAgainst.contextAfter))
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
        val message = OTOperation(algorithm.replicaId, OperationType.Delete(i), algorithm.causalBroadcast.causalState.clone(), mutable.HashMap())

        algorithm.causalBroadcast.addOneToHistory(
          message
        )

        message.contextAfter = algorithm.causalBroadcast.causalState.clone()

        println(s"produced message $message at ${algorithm.replicaId}")

        text.deleteCharAt(i)
      }

      override def insert(i: Int, x: Char): Unit = {
        val message = OTOperation(algorithm.replicaId, OperationType.Insert(i, x), algorithm.causalBroadcast.causalState.clone(), mutable.HashMap())

        algorithm.causalBroadcast.addOneToHistory(
          message
        )

        message.contextAfter = algorithm.causalBroadcast.causalState.clone()

        println(s"produced message $message at ${algorithm.replicaId}")

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
        algorithm.causalBroadcast.syncFrom(other.causalBroadcast, (otherCausalId, otherMessage) => {
          // do we need to find the closest head? I think we should read a paper
          // maybe choosing an arbitrary head should work?
          println(s"receiving $otherMessage with causal info ${otherCausalId} from ${other.replicaId} at ${algorithm.replicaId}")

          val selfHead = algorithm.causalBroadcast.cachedHeads(0)

          // maybe check that these are by other users?
          val concurrentChangesOfOther = other.causalBroadcast.concurrentToAndBefore(selfHead, otherCausalId)

          println(s"concurrent other changes to $selfHead and not after $otherCausalId: $concurrentChangesOfOther")

          val concurrentChangesOfSelf = algorithm.causalBroadcast.concurrentToAndNotAfter(otherCausalId, selfHead)

          println(s"concurrent self changes to $otherCausalId and before $selfHead: $concurrentChangesOfSelf")

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