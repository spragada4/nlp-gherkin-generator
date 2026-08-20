require_relative "pipeline_lib"

# Usage: ruby generate_feature.rb [path_to_scenarios.txt] ["Feature title"]
input_path = ARGV[0] || "scenarios.txt"
feature_title = ARGV[1] || "Generated feature"

unless File.exist?(input_path)
  puts "Input file not found: #{input_path}"
  puts "Usage: ruby generate_feature.rb [path_to_scenarios.txt] [\"Feature title\"]"
  exit 1
end

raw_lines = File.readlines(input_path).map(&:strip)

# Parse a "| a | b | c |" row into ["a", "b", "c"]
def parse_table_row(line)
  line.split("|").map(&:strip).reject(&:empty?)
end

# Parse into scenario blocks. Three line types:
#   "Scenario: <title>"  -> starts a plain scenario
#   "Outline: <title>"   -> starts a scenario outline (expects an Examples: table)
#   "Examples:"          -> switches the current outline into table-reading mode
# Anything else is either a plain-English step or a table row, depending on mode.
scenarios = []
current = nil
reading_table = false

raw_lines.each do |line|
  next if line.empty?

  if line.start_with?("Scenario:")
    current = { type: :scenario, title: line.sub("Scenario:", "").strip, sentences: [] }
    scenarios << current
    reading_table = false
  elsif line.start_with?("Outline:")
    current = { type: :outline, title: line.sub("Outline:", "").strip, sentences: [], table: [] }
    scenarios << current
    reading_table = false
  elsif line.start_with?("Examples:")
    unless current && current[:type] == :outline
      warn "WARNING: 'Examples:' found outside an Outline block, ignoring."
      next
    end
    reading_table = true
  elsif reading_table
    current[:table] << parse_table_row(line)
  elsif current
    current[:sentences] << line
  else
    warn "WARNING: line found before any 'Scenario:'/'Outline:' header, ignoring: #{line}"
  end
end

if scenarios.empty?
  puts "No scenarios found in #{input_path}. Each scenario must start with a line like 'Scenario: My scenario name'."
  exit 1
end

def keyword_for(index, gherkin_line)
  if index.zero?
    "Given"
  elsif gherkin_line.start_with?("I should see")
    "Then"
  else
    "When"
  end
end

def build_scenario_lines(scenario)
  results = scenario[:sentences].map { |s| GherkinGen.process(s) }

  low_confidence = results.reject { |r| r[:confident] }
  if low_confidence.any?
    puts "WARNING: in scenario \"#{scenario[:title]}\", #{low_confidence.length} sentence(s) had no confident match and were skipped:"
    low_confidence.each { |r| puts "  (score #{r[:score].round(3)}) #{r[:input]}" }
  end

  confident_results = results.select { |r| r[:confident] }

  lines = ["  Scenario: #{scenario[:title]}"]
  last_keyword = nil
  confident_results.each_with_index do |result, i|
    keyword = keyword_for(i, result[:gherkin])
    display_keyword = (keyword == last_keyword) ? "And" : keyword
    lines << "    #{display_keyword} #{result[:gherkin]}"
    last_keyword = keyword
  end
  lines
end

def build_outline_lines(scenario)
  results = scenario[:sentences].map { |s| GherkinGen.process(s) }

  low_confidence = results.reject { |r| r[:confident] }
  if low_confidence.any?
    puts "WARNING: in outline \"#{scenario[:title]}\", #{low_confidence.length} sentence(s) had no confident match and were skipped:"
    low_confidence.each { |r| puts "  (score #{r[:score].round(3)}) #{r[:input]}" }
  end

  confident_results = results.select { |r| r[:confident] }

  lines = ["  Scenario Outline: #{scenario[:title]}"]
  last_keyword = nil
  confident_results.each_with_index do |result, i|
    keyword = keyword_for(i, result[:gherkin])
    display_keyword = (keyword == last_keyword) ? "And" : keyword
    lines << "    #{display_keyword} #{result[:gherkin]}"
    last_keyword = keyword
  end

  if scenario[:table].any?
    lines << ""
    lines << "  Examples:"
    scenario[:table].each do |row|
      lines << "    | #{row.join(' | ')} |"
    end
  else
    warn "WARNING: outline \"#{scenario[:title]}\" has no Examples: table."
  end

  lines
end

feature_lines = ["Feature: #{feature_title}", ""]

scenarios.each_with_index do |scenario, i|
  block_lines = scenario[:type] == :outline ? build_outline_lines(scenario) : build_scenario_lines(scenario)
  feature_lines.concat(block_lines)
  feature_lines << "" unless i == scenarios.length - 1
end

output = feature_lines.join("\n") + "\n"

puts "\nGenerated feature:\n\n"
puts output

safe_name = feature_title.downcase.gsub(/[^a-z0-9]+/, "_")
output_filename = "features/generated_#{safe_name}.feature"
File.write(output_filename, output)
puts "Written to #{output_filename}"