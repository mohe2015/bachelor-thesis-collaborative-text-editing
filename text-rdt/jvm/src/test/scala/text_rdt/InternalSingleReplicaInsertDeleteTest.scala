package text_rdt

import org.scalacheck.commands.Commands
import org.scalacheck.{Gen, Prop}

final case class InternalSingleReplicaInsertDeleteTest[A](
    val factoryConstructor: String => A
)(using algorithm: CollaborativeTextEditingAlgorithm[A]) extends Commands {

  type State = String

  type Sut = A

  override def newSut(state: State): Sut = {
    assert(state.isEmpty)
    factoryConstructor("test")
  }

  override def initialPreCondition(state: State): Boolean = state.isEmpty

  override def genCommand(state: State): Gen[Command] = {
    val gens = List(genInsert(state), genDelete(state)).flatten
    Gen.choose(0, gens.size - 1).flatMap(i => gens(i))
  }

  def genInsert(state: State): Option[Gen[Insert]] = Some(for {
    index <- Gen.chooseNum(0, state.length())
    character <- Gen.asciiPrintableChar
  } yield Insert(index, character))

  def genDelete(state: State): Option[Gen[Delete]] = if (state.isEmpty) {
    None
  } else {
    Some(for {
      index <- Gen.chooseNum(0, state.length() - 1)
    } yield Delete(index))
  }

  override def canCreateNewSut(
      newState: State,
      initSuts: Iterable[State],
      runningSuts: Iterable[Sut]
  ): Boolean = true

  override def genInitialState: Gen[State] = Gen.const("")

  override def destroySut(sut: Sut): Unit = {}

  case class Insert(index: Int, character: Char) extends SuccessCommand {
    type Result = State

    override def run(sut: Sut): Result = {
      if (sut.isInstanceOf[Replica[?]]) {
        assert(sut.asInstanceOf[Replica[?]].editor.asInstanceOf[StringEditory].data.toString() == sut.text())
      }

      sut.insert(index, character)
  
      if (sut.isInstanceOf[Replica[?]]) {
        assert(sut.asInstanceOf[Replica[?]].editor.asInstanceOf[StringEditory].data.toString() == sut.text(), s"${sut.asInstanceOf[Replica[?]].editor.asInstanceOf[StringEditory].data.toString()} == ${sut.text()}")
      }

      sut.text()
    }

    override def preCondition(state: State): Boolean = index <= state.length()

    override def postCondition(state: State, result: Result): Prop = {
      Prop.=?(nextState(state), result)
    }

    override def nextState(state: State): State = {
      val builder = StringBuilder(state)
      builder.insert(index, character)
      builder.result()
    }
  }

  case class Delete(index: Int) extends SuccessCommand {
    type Result = State

    override def run(sut: Sut): Result = {
      if (sut.isInstanceOf[Replica[?]]) {
        assert(sut.asInstanceOf[Replica[?]].editor.asInstanceOf[StringEditory].data.toString() == sut.text())
      }

      sut.delete(index)
    
      if (sut.isInstanceOf[Replica[?]]) {
        assert(sut.asInstanceOf[Replica[?]].editor.asInstanceOf[StringEditory].data.toString() == sut.text())
      }

      sut.text()
    }

    override def preCondition(state: State): Boolean = {
      index < state.length()
    }

    override def postCondition(state: State, result: Result): Prop = {
      Prop.=?(
        nextState(state),
        result
      )
    }

    override def nextState(state: State): State = {
      val builder = StringBuilder(state)
      builder.deleteCharAt(index)
      builder.result()
    }
  }
}
