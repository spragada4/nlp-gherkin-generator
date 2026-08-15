## 🚧 WIP: NLP Gherkin Generator 🚧 

A pure Ruby project that turns plain-English test scenarios into runnable
Cucumber `.feature` files — using local, Ruby-native ML (no Python, no
external API calls) to match natural language against your existing
Capybara step definitions.

The goal: a product owner or BA writes something like

```
Type 'tomsmith' into the Username box
```

...and the tool matches it to your existing step definition
`I fill in {string} with {string}`, fills in the right values, and
produces a real, validated Gherkin scenario — reusing your existing
step library instead of generating duplicate step defs every time.

## How it works

```
Plain English sentence
      │
      ▼
[1] Strip quoted text, embed the sentence (informers + MiniLM ONNX)
      │
      ▼
[2] Compare against a "meaning centroid" for each known step pattern
    (averaged embeddings of several paraphrase examples per step)
      │
      ▼
[3] Below confidence threshold (0.25)?  → flag as unmatched, skip
      │ above threshold
      ▼
[4] Extract literal values (quoted strings + capitalized field/button
    names) from the original sentence
      │
      ▼
[5] Assemble a real Gherkin line, e.g. I fill in "Username" with "tomsmith"
      │
      ▼
[6] Write a .feature file, validate with `cucumber --dry-run --strict`
```

Step patterns are read directly from `features/step_definitions/common_steps.rb`
(so they can never drift out of sync with what's actually runnable), and
paired with hand-maintained natural-language paraphrase examples in
`step_meanings.yml` (since "meaning" can't be extracted from code).

## Requirements

- Ruby 3.1+ (developed on 3.3.5, managed via `rbenv`)
- Google Chrome (for the Capybara/Selenium test run)
- Internet access on first run only, to download the MiniLM embedding
  model (~90MB, cached locally afterward)

## Setup

```bash
bundle install
```

## Usage

### 1. Run the core Cucumber suite (hand-written scenario)

```bash
bundle exec cucumber
```

### 2. Generate a `.feature` file from plain English

Edit `scenarios.txt` (one plain-English step per line), then:

```bash
ruby generate_feature.rb
```

Optionally specify a custom input file and scenario title:

```bash
ruby generate_feature.rb scenarios.txt "Valid Login Flow"
```

Any sentence that doesn't confidently match a known step is printed as a
warning and excluded from the output, rather than guessing:

```
WARNING: 1 sentence(s) had no confident match and were skipped:
  (score 0.126) Order a pepperoni pizza
```

### 3. Validate the generated feature file

```bash
bundle exec cucumber features/generated_<title>.feature --dry-run --strict
```

`--dry-run` confirms every generated step resolves to a real step
definition without executing it. Drop `--dry-run` to actually run it
against the browser.

## Project structure

```
features/
  step_definitions/
    common_steps.rb       # Real, runnable Capybara step definitions
  support/
    env.rb                # Capybara/Selenium config
  login.feature            # Hand-written example scenario
  generated_*.feature      # Auto-generated output (gitignored)

pipeline_lib.rb             # Core matching/extraction/assembly logic
generate_feature.rb         # CLI entry point: sentences -> .feature file
step_extractor.rb           # Standalone: extract patterns from step defs
step_meanings.yml           # Paraphrase examples per step pattern
scenarios.txt                # Example plain-English input

embed_test.rb                # Scratch script: sanity-check informers install
sanity_check.rb              # Scratch script: sanity-check embedding model
step_matcher.rb               # Scratch script: matching experiments
value_extractor.rb            # Scratch script: extraction experiments
threshold_check.rb            # Scratch script: view match scores across sentences
```

## Adding a new step

1. Add the step definition to `features/step_definitions/common_steps.rb`
   as usual.
2. Add a handful of natural-language paraphrases for it to
   `step_meanings.yml`, keyed by the exact pattern string. **Keep
   paraphrases action-focused, not domain-flavored** — avoid reusing
   words (e.g. "page", "login") that also appear in another step's
   examples, since shared vocabulary biases the embedding match
   regardless of actual meaning.
3. If you forget step 2, `pipeline_lib.rb` will print an explicit
   warning at load time rather than silently failing to match.
4. Sanity-check with `ruby threshold_check.rb` (add your own test
   sentences to the array) before trusting it on real input.

## Design notes / lessons learned

- **Never embed raw Cucumber patterns** (with `{string}` placeholders)
  — embed natural-language descriptions instead, kept in a separate
  metadata file.
- **Average several paraphrase embeddings into a centroid** per step
  rather than relying on a single example sentence; this is far more
  stable.
- **Strip quoted literal values before embedding for matching** —
  they're only relevant for value extraction, and including them adds
  noise to intent matching.
- **Watch for cross-category vocabulary overlap** in paraphrase
  examples — a shared word between two steps' examples (e.g. "page")
  will bias matches even when it has nothing to do with actual intent.
- **Confidence threshold (0.25)** was chosen from real score data
  (nonsense sentences scored ≤0.145, real matches scored ≥0.394 after
  fixes), not a guess — re-validate with `threshold_check.rb` if the
  step library grows significantly.

## Known limitations / possible next steps

- One scenario per run — no multi-scenario / multi-feature file
  support yet.
- Value extraction is regex-based (quoted strings + capitalized
  phrases) — works for simple form-style sentences but will misfire on
  more free-form phrasing. A POS-tagger (e.g. `engtagger`) could
  improve robustness.
- Step matching is embedding-only; no rule-based pre-filtering layer
  is used to narrow candidates before the ML step.
- Tested against a small step library (4 patterns) on a single sample
  site (`the-internet.herokuapp.com`) — scaling to dozens of step
  types has not been validated, and re-checking for vocabulary overlap
  becomes more important as the library grows.

## Tech stack

| Purpose | Gem |
|---|---|
| BDD test runner | `cucumber` |
| Browser automation | `capybara`, `selenium-webdriver` |
| Sentence embeddings (local ONNX inference) | `informers` |
| Assertions | `rspec-expectations` |