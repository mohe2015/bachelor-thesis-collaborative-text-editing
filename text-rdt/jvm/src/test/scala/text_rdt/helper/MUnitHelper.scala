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
    println(s"CREATE Selenium FOR ${Thread.currentThread()}")
    // TODO headless
    webdriver = new ChromeDriver()
  }

  def getOrCreateWebDriver(): WebDriver = {
    webdriver
  }

  def giveBack(page: WebDriver, uuid: UUID): Unit = {
    
  }
  
  override def afterAll(): Unit = {
    webdriver.quit()
  }

  override def apply(): Unit = ()
}
