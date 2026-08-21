require "capybara/cucumber"
require "selenium-webdriver"

Capybara.register_driver :selenium_chrome_headless_ci do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage") # avoids /dev/shm crashes in constrained CI containers
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1400,1400")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_driver = :selenium_chrome_headless_ci
Capybara.app_host = "https://the-internet.herokuapp.com"
Capybara.run_server = false
Capybara.default_max_wait_time = 10

After do
  Capybara.reset_sessions!
end