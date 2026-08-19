require_relative "pipeline_lib"

test_sentences = [
  "Type 'tomsmith' into the Username box",         # should match fill_in, high confidence
  "Enter \"SuperSecretPassword!\" in the Password field", # matched before but only scored 0.182
  "Press the Login button",                         # should match: click
  "Go to the login screen",                         # should match: visit
  "The page should show \"Welcome\"",                # should match should_see
  "Order a pepperoni pizza",                         # should NOT match anything well
  "What is the capital of France",                   # should NOT match anything well
  "Restart the database server"                      # should NOT match anything well
]

test_sentences.each do |sentence|
  result = GherkinGen.process(sentence)
  puts "#{result[:score].round(3)}   #{sentence}  ->  #{result[:matched_pattern]}"
end