package text_rdt.helper

import munit.Fixture

import java.util.UUID
import scala.collection.mutable
import java.nio.file.Paths
import org.openqa.selenium.WebDriver
import org.openqa.selenium.chrome.ChromeDriver
import org.openqa.selenium.bidi.browsingcontext.BrowsingContext

class WebDriverFixture
    extends Fixture[Unit]("webdriver") {
   
  var webdriver: WebDriver = scala.compiletime.uninitialized

  override def beforeAll(): Unit = {
    println(s"CREATE PLAYWRIGHT FOR ${Thread.currentThread()}")
    // TODO headless
    webdriver = new ChromeDriver()
  }

  def getOrCreateWebDriver(): BrowsingContext = {
    val bc = new BrowsingContext(webdriver);
    val context = browser.newContext().nn
    context.onWebError(error => {
      throw new RuntimeException(error.toString())
    })
    context
      .tracing()
      .nn
      .start(
        new Tracing.StartOptions()
          .setScreenshots(true)
          .nn
          .setSnapshots(true)
          .nn
          .setSources(true)
          .nn
      );
    context.newPage.nn
  }

  def giveBack(webDriver: Page, uuid: UUID): Unit = {
    if (!(thread eq Thread.currentThread())) {
      throw new IllegalStateException()
    }
    webDriver
      .context()
      .nn
      .tracing()
      .nn
      .stop(
        new Tracing.StopOptions()
          .setPath(Paths.get(s"traces/trace-$uuid.zip"))
      );
    webDriver.context().nn.close()
  }
  
  override def afterAll(): Unit = {
    if (!(thread eq Thread.currentThread())) {
      throw new IllegalStateException()
    }
  }

  override def apply(): Unit = ()
}
