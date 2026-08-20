require "capybara/cucumber"
require "selenium-webdriver"

Capybara.default_driver = :selenium_chrome_headless
Capybara.app_host = "https://the-internet.herokuapp.com"
Capybara.run_server = false

# Ensure a clean browser state between scenarios — prevents stale element
# references and leftover session state from bleeding into the next scenario.
After do
    Capybara.reset_sessions!
  end