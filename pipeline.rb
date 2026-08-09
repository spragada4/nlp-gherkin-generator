require "informers"

model = Informers.pipeline("embedding", "sentence-transformers/all-MiniLM-L6-v2")

def cosine_similarity(a, b)
  dot = a.zip(b).sum { |x, y| x * y }
  mag_a = Math.sqrt(a.sum { |x| x**2 })
  mag_b = Math.sqrt(b.sum { |x| x**2 })
  dot / (mag_a * mag_b)
end

def average_vector(vectors)
  length = vectors.first.length
  sums = Array.new(length, 0.0)
  vectors.each { |v| v.each_with_index { |val, i| sums[i] += val } }
  sums.map { |s| s / vectors.length }
end

def extract_values(sentence)
  quoted = sentence.scan(/'([^']*)'|"([^"]*)"/).flatten.compact
  sentence_without_quotes = sentence.gsub(/'[^']*'|"[^"]*"/, "")
  capitalized = sentence_without_quotes
                .scan(/\b([A-Z][a-zA-Z]*(?:\s[A-Z][a-zA-Z]*)*)\b/)
                .flatten
                .reject { |w| sentence_without_quotes.strip.start_with?(w) }
                .map(&:strip)
                .reject(&:empty?)
  { quoted: quoted, capitalized: capitalized }
end

STEP_LIBRARY = [
  {
    pattern: "I visit the login page",
    slots: 0,
    examples: ["go to a page", "navigate to a screen", "open a URL", "browse to a page in the app"]
  },
  {
    pattern: 'I fill in {string} with {string}',
    slots: 2,
    # order: [field_name, value]
    examples: ["type a value into a field", "enter text into an input box",
               "fill in a form field with a value", "type something into a text box"]
  },
  {
    pattern: 'I click {string}',
    slots: 1,
    # order: [label]
    examples: ["click a button", "press a button", "click on a link", "tap on an element"]
  },
  {
    pattern: 'I should see {string}',
    slots: 1,
    # order: [text]
    examples: ["check that some text appears on the page", "verify a message is displayed",
               "the page should show certain text", "confirm text is visible"]
  }
].freeze

STEP_LIBRARY.each do |step|
  step[:centroid] = average_vector(model.(step[:examples]))
end

def best_match(model, sentence, library)
  new_embedding = model.(sentence)
  library.map { |step| [step, cosine_similarity(new_embedding, step[:centroid])] }
         .max_by { |_, score| score }
end

def assemble_gherkin(step, values)
  case step[:pattern]
  when 'I fill in {string} with {string}'
    field = values[:capitalized].first || "UNKNOWN_FIELD"
    value = values[:quoted].first || "UNKNOWN_VALUE"
    %(I fill in "#{field}" with "#{value}")
  when 'I click {string}'
    label = values[:capitalized].first || values[:quoted].first || "UNKNOWN_LABEL"
    %(I click "#{label}")
  when 'I should see {string}'
    text = values[:quoted].first || values[:capitalized].join(" ")
    %(I should see "#{text}")
  else
    step[:pattern] # zero-slot steps like "I visit the login page" need no filling
  end
end

def process(model, sentence, library)
  step, score = best_match(model, sentence, library)
  values = extract_values(sentence)
  gherkin_line = assemble_gherkin(step, values)
  { input: sentence, matched_pattern: step[:pattern], score: score, gherkin: gherkin_line }
end

test_sentences = [
  "Type 'tomsmith' into the Username box",
  "Enter \"SuperSecretPassword!\" in the Password field",
  "Press the Login button",
  "Go to the login screen",
  "The page should show \"You logged into a secure area\""
]

test_sentences.each do |sentence|
  result = process(model, sentence, STEP_LIBRARY)
  puts "Input:   #{result[:input]}"
  puts "Matched: #{result[:matched_pattern]}  (score #{result[:score].round(3)})"
  puts "Gherkin: #{result[:gherkin]}"
  puts
end