# Extracts Cucumber step patterns from a step_definitions Ruby file.
# Matches: Given("..."), When('...'), Then("..."), And(...)
# Does NOT execute the Ruby file — just scans it as text, so this is safe
# to run even on step defs with side effects (browser calls, etc).

def extract_patterns(path)
    content = File.read(path)
    content.scan(/^\s*(?:Given|When|Then|And)\(\s*(['"])(.*?)\1/).map { |_, pattern| pattern }
  end
  
  if __FILE__ == $0
    path = ARGV[0] || "features/step_definitions/common_steps.rb"
    patterns = extract_patterns(path)
    puts "Found #{patterns.length} step pattern(s) in #{path}:"
    patterns.each { |p| puts "  #{p}" }
  end