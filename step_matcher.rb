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

# Each step now has several paraphrases of the SAME action.
# Averaging their embeddings gives a more robust "meaning centroid"
# than any single sentence can.
STEP_LIBRARY = [
    {
      pattern: "I visit the login page",
      examples: [
        "go to a page",
        "navigate to a screen",
        "open a URL",
        "browse to a page in the app"
      ]
    },
    {
      pattern: 'I fill in {string} with {string}',
      examples: [
        "type a value into a field",
        "enter text into an input box",
        "fill in a form field with a value",
        "type something into a text box"
      ]
    },
    {
      pattern: 'I click {string}',
      examples: [
        "click a button",
        "press a button",
        "click on a link",
        "tap on an element"
      ]
    },
    {
      pattern: 'I should see {string}',
      examples: [
        "check that some text appears on the page",
        "verify a message is displayed",
        "the page should show certain text",
        "confirm text is visible"
      ]
    }
  ].freeze

# Precompute a single averaged embedding per step.
STEP_LIBRARY.each do |step|
  embeddings = model.(step[:examples])
  step[:centroid] = average_vector(embeddings)
end

def match(model, sentence, library)
  new_embedding = model.(sentence)
  scored = library.map { |step| [step, cosine_similarity(new_embedding, step[:centroid])] }
  scored.sort_by! { |_, score| -score }
  scored
end

test_sentences = [
  "Type 'tomsmith' into the Username box",
  "Go to the login screen",
  "Press the Login button",
  "The page should display a welcome message"
]

test_sentences.each do |sentence|
  puts "Input: #{sentence}"
  results = match(model, sentence, STEP_LIBRARY)
  results.each do |step, score|
    puts "  #{score.round(4)}  #{step[:pattern]}"
  end
  puts
end