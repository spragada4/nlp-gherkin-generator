require_relative "pipeline_lib"

test_sentences = [
  "Type '<username>' into the Username box",
  "Enter '<password>' in the Password field",
  "The page should show '<message>'"
]

test_sentences.each do |sentence|
  result = GherkinGen.process(sentence)
  puts "Input:   #{sentence}"
  puts "Matched: #{result[:matched_pattern].inspect}  (score #{result[:score]&.round(3)})"
  puts "Gherkin: #{result[:gherkin].inspect}"
  puts
end