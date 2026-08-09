Feature: Login

  Scenario: Valid login
    Given I visit the login page
    When I fill in "Username" with "tomsmith"
    And I fill in "Password" with "SuperSecretPassword!"
    And I click "Login"
    Then I should see "You logged into a secure area"