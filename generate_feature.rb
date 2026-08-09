require_relative "pipeline_lib"

# Plain-English scenario input. In a real workflow this might come from
# a .txt file — for now it's inline so we can see the whole flow clearly.
scenario_title = "Valid login"
sentences = [
  "Go to the login screen",
  "Type 'tomsmith' into the Username box",
  "Enter \"SuperSecretPassword!\" in the Password field",
  "Press the Login button",
  "The page should show \"You logged into a secure area\""
]

# Assign Given/When/Then/And based on position:
# first step -> Given, last "check" step -> Then, everything else -> When,
# with consecutive same-keyword steps collapsed to "And".
def keyword_for(index, total, gherkin_line)
  if index == 0
    "Given"
  elsif gherkin_line.start_with?("I should see")
    "Then"
  else
    "When"
  end
end

results = sentences.map { |s| GherkinGen.process(s) }

lines = ["Feature: #{scenario_title}", "", "  Scenario: #{scenario_title}"]

last_keyword = nil
results.each_with_index do |result, i|
  keyword = keyword_for(i, results.length, result[:gherkin])
  display_keyword = (keyword == last_keyword) ? "And" : keyword
  lines << "    #{display_keyword} #{result[:gherkin]}"
  last_keyword = keyword
end

output = lines.join("\n") + "\n"

puts "Generated feature:\n\n"
puts output

File.write("features/generated_login.feature", output)
puts "\nWritten to features/generated_login.feature"