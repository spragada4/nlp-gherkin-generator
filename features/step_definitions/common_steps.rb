Given("I visit the login page") do
  visit "/login"
end

When("I fill in {string} with {string}") do |field, value|
  fill_in field, with: value
end

When("I click {string}") do |label|
  click_on label
end

Then("I should see {string}") do |text|
  attempts = 0
  begin
    expect(page).to have_content(text)
  rescue Selenium::WebDriver::Error::UnknownError => e
    attempts += 1
    if attempts <= 2
      sleep 1
      retry
    else
      raise e
    end
  end
end
