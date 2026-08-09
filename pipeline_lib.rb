require "informers"

module GherkinGen
  MODEL = Informers.pipeline("embedding", "sentence-transformers/all-MiniLM-L6-v2")

  STEP_LIBRARY = [
    {
      pattern: "I visit the login page",
      examples: ["go to a page", "navigate to a screen", "open a URL", "browse to a page in the app"]
    },
    {
      pattern: 'I fill in {string} with {string}',
      examples: ["type a value into a field", "enter text into an input box",
                 "fill in a form field with a value", "type something into a text box"]
    },
    {
      pattern: 'I click {string}',
      examples: ["click a button", "press a button", "click on a link", "tap on an element"]
    },
    {
      pattern: 'I should see {string}',
      examples: ["check that some text appears on the page", "verify a message is displayed",
                 "the page should show certain text", "confirm text is visible"]
    }
  ].freeze

  def self.cosine_similarity(a, b)
    dot = a.zip(b).sum { |x, y| x * y }
    mag_a = Math.sqrt(a.sum { |x| x**2 })
    mag_b = Math.sqrt(b.sum { |x| x**2 })
    dot / (mag_a * mag_b)
  end

  def self.average_vector(vectors)
    length = vectors.first.length
    sums = Array.new(length, 0.0)
    vectors.each { |v| v.each_with_index { |val, i| sums[i] += val } }
    sums.map { |s| s / vectors.length }
  end

  def self.extract_values(sentence)
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

  def self.best_match(sentence, library)
    new_embedding = MODEL.(sentence)
    library.map { |step| [step, cosine_similarity(new_embedding, step[:centroid])] }
           .max_by { |_, score| score }
  end

  def self.assemble_gherkin(step, values)
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
      step[:pattern]
    end
  end

  def self.setup!
    STEP_LIBRARY.each do |step|
      step[:centroid] = average_vector(MODEL.(step[:examples]))
    end
  end

  def self.process(sentence)
    step, score = best_match(sentence, STEP_LIBRARY)
    values = extract_values(sentence)
    gherkin_line = assemble_gherkin(step, values)
    { input: sentence, matched_pattern: step[:pattern], score: score, gherkin: gherkin_line }
  end
end

GherkinGen.setup!