package text_rdt

import org.scalacheck.commands.Commands
import org.scalacheck.{Gen, Prop}
import text_rdt.helper.WebDriverFixture
import java.util.UUID
import org.openqa.selenium.WebDriver
import org.openqa.selenium.By
import org.openqa.selenium.JavascriptExecutor

case class SutSingleType(
    driver: WebDriver,
    element: By,
    traceUuid: UUID
) {}

// is this a concurrency bug
case class BrowserSingleReplicaInsertDeleteTest(
    webDriverFixture: WebDriverFixture,
    algorithm: String
) extends Commands {

  type State = String

  type Sut = SutSingleType

  override def newSut(state: State): Sut = {
    assert(state.isEmpty)
    val driver: WebDriver = webDriverFixture.getOrCreateWebDriver()
    val traceUuid = UUID.randomUUID().nn
    try {
      driver.get(s"http://localhost:5173/?$algorithm")
      val createEditor = driver.findElement(By.cssSelector("#create-editor")).nn
      createEditor.click()
      SutSingleType(driver, By.cssSelector("#editor0 div"), traceUuid)
    } catch
      case e => {
        webDriverFixture.giveBack(driver, traceUuid); throw e
      }
  }

  override def initialPreCondition(state: State): Boolean = state.isEmpty

  override def genCommand(state: State): Gen[Command] = if (state.isEmpty) {
    genInsert(state)
  } else {
    Gen.oneOf(genInsert(state), genDelete(state))
  }

  def genInsert(state: State): Gen[Insert] = for {
    index <- Gen.chooseNum(0, state.length())
    character <- Gen.asciiPrintableChar
  } yield Insert(index, character)

  def genDelete(state: State): Gen[Delete] = for {
    index <- Gen.chooseNum(0, state.length() - 1)
  } yield Delete(index)

  override def canCreateNewSut(
      newState: State,
      initSuts: Iterable[State],
      runningSuts: Iterable[Sut]
  ): Boolean = true

  override def genInitialState: Gen[State] = Gen.const("")

  override def destroySut(sut: Sut): Unit = {
    webDriverFixture.giveBack(sut.driver, sut.traceUuid)
  }

  abstract class BaseCommand extends SuccessCommand {
    type Result = (String, UUID)

    override def postCondition(state: State, result: Result): Prop = {
      Prop
        .=?(nextState(state), result._1)
    }
  }

  case class Insert(index: Int, character: Char) extends BaseCommand {

    override def run(sut: Sut): Result = {
      val oldText =
        sut.driver.findElement(sut.element).getText().nn
      sut.driver.asInstanceOf[JavascriptExecutor].executeScript(s"arguments[0].textContent = arguments[1]", sut.driver.findElement(sut.element), StringBuilder(oldText).insert(index, character).toString)
      (sut.driver.findElement(sut.element).getText().nn, sut.traceUuid)
    }

    override def preCondition(state: State): Boolean = index <= state.length()

    override def nextState(state: State): State = {
      val builder = StringBuilder(state)
      builder.insert(index, character)
      builder.result()
    }
  }

  case class Delete(index: Int) extends BaseCommand {

    override def run(sut: Sut): Result = {
      val oldText = sut.driver.findElement(sut.element).getText().nn
      val toFill = StringBuilder(oldText).deleteCharAt(index).toString
      if (toFill.isEmpty()) {
        sut.driver.asInstanceOf[JavascriptExecutor].executeScript(s"arguments[0].textContent = ``", sut.driver.findElement(sut.element))
      } else {
        sut.driver.asInstanceOf[JavascriptExecutor].executeScript(s"arguments[0].textContent = arguments[1]", sut.driver.findElement(sut.element), toFill)
      }
      (sut.driver.findElement(sut.element).getText().nn, sut.traceUuid)
    }

    override def preCondition(state: State): Boolean = {
      index < state.length()
    }

    override def nextState(state: State): State = {
      val builder = StringBuilder(state)
      builder.deleteCharAt(index)
      builder.result()
    }
  }
}
