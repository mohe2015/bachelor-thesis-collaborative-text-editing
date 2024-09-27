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
import org.openqa.selenium.chrome.ChromeOptions
import org.openqa.selenium.firefox.FirefoxDriver
import org.openqa.selenium.chrome.ChromeDriverInfo
import org.openqa.selenium.chrome.ChromeDriverService
import org.openqa.selenium.chromium.ChromiumDriverLogLevel

class WebDriverFixture
    extends Fixture[Unit]("webdriver") {

  var webdriver: WebDriver = scala.compiletime.uninitialized

  override def beforeAll(): Unit = {
    println(s"CREATE Selenium FOR ${Thread.currentThread()}")

    val serviceBuilder = new ChromeDriverService.Builder().withLogOutput(System.out).withLogLevel(ChromiumDriverLogLevel.ALL);
    val options = new ChromeOptions();
    options.addArguments("--headless=new", "--verbose", "--log-level=0", "--enable-logging=stderr", "--v=1");
    val chromeDriverService = serviceBuilder.build(); 

    webdriver = new ChromeDriver(chromeDriverService, options)
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
