package text_rdt.helper

import munit.Fixture

import java.util.UUID
import scala.collection.mutable
import java.nio.file.Paths
import org.openqa.selenium.WebDriver
import org.openqa.selenium.chrome.ChromeDriver
import org.openqa.selenium.bidi.browsingcontext.BrowsingContext
import org.openqa.selenium.bidi.browsingcontext.CreateContextParameters
import org.openqa.selenium.WindowType

class WebDriverFixture
    extends Fixture[Unit]("webdriver") {

  var webdriver: WebDriver = scala.compiletime.uninitialized

  override def beforeAll(): Unit = {
    println(s"CREATE PLAYWRIGHT FOR ${Thread.currentThread()}")
    // TODO headless
    webdriver = new ChromeDriver()
  }

  def getOrCreateWebDriver(): BrowsingContext = {
    new BrowsingContext(webdriver, WindowType.TAB)
  }

  def giveBack(page: BrowsingContext, uuid: UUID): Unit = {
    page.close()
  }
  
  override def afterAll(): Unit = {
    webdriver.quit()
  }

  override def apply(): Unit = ()
}
