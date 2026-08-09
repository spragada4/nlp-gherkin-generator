require "informers"

model = Informers.pipeline("embedding", "sentence-transformers/all-MiniLM-L6-v2")

def cosine_similarity(a, b)
  dot = a.zip(b).sum { |x, y| x * y }
  mag_a = Math.sqrt(a.sum { |x| x**2 })
  mag_b = Math.sqrt(b.sum { |x| x**2 })
  dot / (mag_a * mag_b)
end

pairs = [
  ["type a value into a field", "type a value into a field"],       # identical -> expect ~1.0
  ["type a value into a field", "enter text into an input box"],     # near-synonym -> expect high
  ["type a value into a field", "click a button"],                   # related but different action
  ["type a value into a field", "the weather is sunny today"],       # unrelated -> expect low
]

pairs.each do |a, b|
  emb_a = model.(a)
  emb_b = model.(b)
  score = cosine_similarity(emb_a, emb_b)
  puts "#{score.round(4)}   \"#{a}\"  vs  \"#{b}\""
end