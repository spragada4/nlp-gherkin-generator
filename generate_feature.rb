require_relative "pipeline_lib"

# Plain-English scenario input. In a real workflow this might come from
# a .txt file — for now it's inline so we can see the whole flow clearly.
# Usage: ruby generate_feature.rb [path_to_scenarios.txt] ["Scenario title"]
input_path = ARGV[0] || "scenarios.txt"
scenario_title = ARGV[1] || "Generated scenario"

unless File.exist?(input_path)
  puts "Input file not found: #{input_path}"
  puts "Usage: ruby generate_feature.rb [path_to_scenarios.txt] [\"Scenario title\"]"
  exit 1
end

sentences = File.readlines(input_path).map(&:strip).reject(&:empty?)

if sentences.empty?
  puts "No sentences found in #{input_path}"
  exit 1
end

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

low_confidence = results.reject { |r| r[:confident] }
if low_confidence.any?
  puts "WARNING: #{low_confidence.length} sentence(s) had no confident match and were skipped:"
  low_confidence.each { |r| puts "  (score #{r[:score].round(3)}) #{r[:input]}" }
  puts
end

confident_results = results.select { |r| r[:confident] }

lines = ["Feature: #{scenario_title}", "", "  Scenario: #{scenario_title}"]

last_keyword = nil
confident_results.each_with_index do |result, i|
  keyword = keyword_for(i, confident_results.length, result[:gherkin])
  display_keyword = (keyword == last_keyword) ? "And" : keyword
  lines << "    #{display_keyword} #{result[:gherkin]}"
  last_keyword = keyword
end

output = lines.join("\n") + "\n"

puts "Generated feature:\n\n"
puts output

output_filename = "features/generated_#{scenario_title.downcase.gsub(/[^a-z0-9]+/, '_')}.feature"
File.write(output_filename, output)
puts "\nWritten to #{output_filename}"