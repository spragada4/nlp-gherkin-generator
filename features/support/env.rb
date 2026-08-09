require "capybara/cucumber"
require "selenium-webdriver"

Capybara.default_driver = :selenium_chrome_headless
Capybara.app_host = "https://the-internet.herokuapp.com"
Capybara.run_server = false