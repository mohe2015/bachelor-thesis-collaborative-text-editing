package text_rdt

import scala.collection.mutable
import scala.collection.mutable.ArrayBuffer

// https://www3.ntu.edu.sg/scse/staff/czsun/projects/otfaq/#_Toc321146152
// COT would be way to complicated, choose something simpler
// dOPT
// https://dl.acm.org/doi/pdf/10.1145/289444.289469

// https://www3.ntu.edu.sg/scse/staff/czsun/projects/otfaq/#_Toc321146146

// https://arxiv.org/pdf/1905.01302
// 3.1.3 Server-based versus Distributed OT

// The context needs to represent a context vector. This means for every replicating site it stores which operations O_0 to O_i have been executed. https://dl.acm.org/doi/pdf/10.1145/1180875.1180918
// 2.7.How to represent operation context in OT design? 
case class OTOperation(replica: RID, inner: OperationType, context: mutable.HashMap[text_rdt.RID, Int]) {
    
}

def inclusionTransform(operationToTransform: Option[OTOperation], operationToTransformAgainst: OTOperation): Option[OTOperation] = {
    println(s"inclusion transforming $operationToTransform against $operationToTransformAgainst")
  val result = inclusionTransformInternal(operationToTransform, operationToTransformAgainst)
  println(s"inclusion transformed $operationToTransform against $operationToTransformAgainst to $result")
  // possibly the reverse does not hold
  //assert(operationToTransform == exclusionTransformInternal(result, operationToTransformAgainst), s"IT($operationToTransform, $operationToTransformAgainst) -> $result -> ET($result, $operationToTransformAgainst) -> ${exclusionTransformInternal(result, operationToTransformAgainst)}")
  result
}

// 2.17.    What are the pre-/post-conditions for transformation functions?
def inclusionTransformInternal(operationToTransform: Option[OTOperation], operationToTransformAgainst: OTOperation): Option[OTOperation] = {
  assert(operationToTransform.isEmpty || operationToTransform.get.context == operationToTransformAgainst.context, s"${operationToTransform.get.context} == ${operationToTransformAgainst.context}")
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
  result.map((replicaId, operationType) => OTOperation(replicaId, operationType, operationToTransformAgainst.context.clone().addOne(operationToTransformAgainst.replica, operationToTransformAgainst.context.getOrElse(operationToTransformAgainst.replica, 0) + 1)))
}

def exclusionTransform(operationToTransform: Option[OTOperation], operationToTransformAgainst: OTOperation): Option[OTOperation] = {
  println(s"exclusion transforming $operationToTransform against $operationToTransformAgainst")
  val result = exclusionTransformInternal(operationToTransform, operationToTransformAgainst)
  println(s"exclusion transformed $operationToTransform against $operationToTransformAgainst to $result")
  //assert(operationToTransform == inclusionTransformInternal(result, operationToTransformAgainst))
  result
}

// https://en.wikipedia.org/wiki/Operational_transformation
// 2.17.    What are the pre-/post-conditions for transformation functions?    
def exclusionTransformInternal(operationToTransform: Option[OTOperation], operationToTransformAgainst: OTOperation): Option[OTOperation] = {
  assert(operationToTransform.isEmpty || operationToTransform.get.context == operationToTransformAgainst.context.clone().addOne(operationToTransformAgainst.replica, operationToTransformAgainst.context.getOrElse(operationToTransformAgainst.replica, 0) + 1), s"${operationToTransform.get.context} == ${operationToTransformAgainst.context.clone().addOne(operationToTransformAgainst.replica, operationToTransformAgainst.context.getOrElse(operationToTransformAgainst.replica, 0) + 1)}")
  val result = (operationToTransform.map(v => (v.replica, v.inner)), (operationToTransformAgainst.replica, operationToTransformAgainst.inner)) match {
    case Tuple2(None, other) => None
    case Tuple2(Some((oReplica, OperationType.Insert(oI, oX))), (bReplica, OperationType.Insert(bI, bX))) => if (oI < bI || (oI == bI && oReplica < bReplica)) {
      Some((oReplica, OperationType.Insert(oI, oX)))
    } else {
      Some((oReplica, OperationType.Insert(oI - 1, oX)))
    }
    case Tuple2(Some((oReplica, OperationType.Insert(oI, oX))), (bReplica, OperationType.Delete(bI))) => if (oI <= bI) {
      Some((oReplica, OperationType.Insert(oI, oX)))
    } else {
      Some((oReplica, OperationType.Insert(oI + 1, oX)))
    }
    case Tuple2(Some((oReplica, OperationType.Delete(oI))), (bReplica, OperationType.Insert(bI, bX))) => if (oI < bI) {
      Some((oReplica, OperationType.Delete(oI)))
    } else {
      Some((oReplica, OperationType.Delete(oI - 1)))
    }
    case Tuple2(Some((oReplica, OperationType.Delete(oI))), (bReplica, OperationType.Delete(bI))) => if (oI < bI) {
      Some((oReplica, OperationType.Delete(oI)))
    } else if (oI > bI) {
      Some((oReplica, OperationType.Delete(oI + 1)))
    } else {
      None
    }
  }
  result.map((replicaId, operationType) => OTOperation(replicaId, operationType, operationToTransformAgainst.context))
}

enum OperationType() {
  case Insert(i: Int, x: Char)
  case Delete(i: Int)
}

final case class OTAlgorithm(replicaId: String, val operations: Vector[OTOperation]) {

  val causalBroadcast = CausalBroadcast[OTOperation](replicaId, false)

  val text: StringBuilder = StringBuilder()

}

// TODO FIXME maybe disable message batching for this?
object OTAlgorithm {
  given algorithm: CollaborativeTextEditingAlgorithm[OTAlgorithm] with {

    extension (algorithm: OTAlgorithm) {
      override def delete(i: Int): Unit = {
        if (algorithm.causalBroadcast.needsTick) {
          algorithm.causalBroadcast.needsTick = false
          algorithm.causalBroadcast.tick()
        }
        
        val message = OTOperation(algorithm.replicaId, OperationType.Delete(i), algorithm.causalBroadcast.causalState.clone())

        algorithm.causalBroadcast.addOneToHistory(
          message
        )

        println(s"produced message $message at ${algorithm.replicaId}")

        text.deleteCharAt(i)
      }

      override def insert(i: Int, x: Char): Unit = {
        if (algorithm.causalBroadcast.needsTick) {
          algorithm.causalBroadcast.needsTick = false
          algorithm.causalBroadcast.tick()
        }
        
        val message = OTOperation(algorithm.replicaId, OperationType.Insert(i, x), algorithm.causalBroadcast.causalState.clone())

        algorithm.causalBroadcast.addOneToHistory(
          message
        )

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

      def transform(other: OTAlgorithm, otherCausalId: CausalID, otherMessage: OTOperation): Option[OTOperation] = {
          println("transform start")
          val selfHead = algorithm.causalBroadcast.cachedHeads(0)

          // maybe check that these are by other users?
          val concurrentChangesOfOther = other.causalBroadcast.concurrentToAndBefore(selfHead, otherCausalId)

          println(s"concurrent other changes to $selfHead and before $otherCausalId: $concurrentChangesOfOther")

          val concurrentChangesOfSelf = algorithm.causalBroadcast.concurrentToAndNotAfter(otherCausalId, selfHead)

          println(s"concurrent self changes to $otherCausalId and not after $selfHead: $concurrentChangesOfSelf")

          //println(s"receiving ${otherMessage.toString().replace("\n", "\\n")} from ${other.replicaId} with changes to transform against: ${concurrentChanges.toString().replace("\n", "\\n")}")

          var newOperation: Option[OTOperation] = concurrentChangesOfOther.flatMap(_._2).foldLeft(Some(otherMessage))(exclusionTransform)

          newOperation = concurrentChangesOfSelf.flatMap(_._2).foldLeft(newOperation)(inclusionTransform)

          // this is probably wrong, causal id probably needs to be from concurrentChangesOfOther
          newOperation = concurrentChangesOfOther.flatMap(v => v._2.flatMap(vv => transform(other, v._1, vv))).foldLeft(newOperation)(inclusionTransform)

          println("transform end")
          newOperation
      }

      override def syncFrom(other: OTAlgorithm) = {
        algorithm.causalBroadcast.syncFrom(other.causalBroadcast, (otherCausalId, otherMessage) => {
          // do we need to find the closest head? I think we should read a paper
          // maybe choosing an arbitrary head should work?
          println(s"receiving $otherMessage with causal info ${otherCausalId} from ${other.replicaId} at ${algorithm.replicaId}")

          val newOperation = transform(other, otherCausalId, otherMessage)

          println(s"executing $newOperation at ${algorithm.replicaId}")

          newOperation.foreach(operation => operation.inner match {
            case OperationType.Insert(i, x) => text.insert(i, x)
            case OperationType.Delete(i) => text.deleteCharAt(i)
          })
        })
      }
    }
  }
}