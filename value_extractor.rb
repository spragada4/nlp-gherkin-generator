def extract_values(sentence)
    quoted = sentence.scan(/'([^']*)'|"([^"]*)"/).flatten.compact
  
    # Strip out the quoted spans (quotes and their contents) before
    # scanning for capitalized field/button names, so quoted values
    # can't also get picked up as "capitalized" candidates.
    sentence_without_quotes = sentence.gsub(/'[^']*'|"[^"]*"/, "")
  
    capitalized = sentence_without_quotes
                  .scan(/\b([A-Z][a-zA-Z]*(?:\s[A-Z][a-zA-Z]*)*)\b/)
                  .flatten
                  .reject { |w| sentence_without_quotes.strip.start_with?(w) }
                  .map(&:strip)
                  .reject(&:empty?)
  
    { quoted: quoted, capitalized: capitalized }
  end
  
  test_sentences = [
    "Type 'tomsmith' into the Username box",
    "Enter \"SuperSecretPassword!\" in the Password field",
    "Press the Login button",
    "Go to the login screen"
  ]
  
  test_sentences.each do |sentence|
    result = extract_values(sentence)
    puts sentence
    puts "  quoted:      #{result[:quoted]}"
    puts "  capitalized: #{result[:capitalized]}"
    puts
  end