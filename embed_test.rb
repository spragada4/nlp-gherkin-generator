require "informers"

puts "Loading model (first run will download it, may take a minute)..."
model = Informers.pipeline("embedding", "sentence-transformers/all-MiniLM-L6-v2")

sentences = [
  "I fill in a field with a value",
  "Type text into an input box",
  "Click the login button"
]

embeddings = model.(sentences)

puts "Got #{embeddings.length} embeddings, each of length #{embeddings.first.length}"
puts "First few values of embedding 1: #{embeddings[0][0..4]}"