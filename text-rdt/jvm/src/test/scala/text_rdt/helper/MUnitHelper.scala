package text_rdt.helper

import com.microsoft.playwright.{Page, Playwright}
import munit.Fixture

import com.microsoft.playwright.Browser
import java.util.UUID
import com.microsoft.playwright.BrowserType
import scala.collection.mutable
import com.microsoft.playwright.Tracing
import java.nio.file.Paths
import com.microsoft.playwright.Playwright.CreateOptions

class WebDriverFixture
    extends Fixture[Unit]("webdriver") {
   
  var thread: Thread = scala.compiletime.uninitialized
  var playwright: Playwright = scala.compiletime.uninitialized
  var browser: Browser = scala.compiletime.uninitialized

  override def beforeAll(): Unit = {
    println(s"CREATE PLAYWRIGHT FOR ${Thread.currentThread()}")
    thread = Thread.currentThread()
    playwright = Playwright.create().nn
    browser = playwright.chromium.nn.launch(new BrowserType.LaunchOptions().setHeadless(true).nn).nn
  }

  def getOrCreateWebDriver(): Page = {
    if (!(thread eq Thread.currentThread())) {
      throw new IllegalStateException()
    }
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
