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
  expect(page).to have_content(text)
end
