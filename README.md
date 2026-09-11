# PictoDia

An iOS app that turns a caregiver's spoken or written description of the day
into an ordered sequence of pictograms, so that a person with autism can see
what is going to happen.

Built with SwiftUI as my first Swift project.

---

## The problem

Visual schedules are one of the most established tools in autism support:
knowing what comes next reduces anxiety about the unknown. Tools to build them
already exist, but they all require the caregiver to search and drag each
pictogram by hand. That friction is why many people stop using them.

PictoDia removes the manual step. The caregiver says or types the plan in one
or two sentences; the app extracts the individual events, finds a matching
pictogram for each, and lays them out vertically in chronological order.

## How it works

```
"Vi ska äta frukost, sedan gå till skolan och på eftermiddagen till läkaren"
                              ↓
          LLM extracts discrete events, ordered logically
                              ↓
              ["frukost", "skola", "läkare"]
                              ↓
          ARASAAC lookup (Swedish, falling back to English)
                              ↓
        LLM picks the best candidate for each event
                              ↓
              Vertical pictogram schedule
```

Results are cached, so repeated routines cost neither an API call nor a wait.

## Features

- **Speech or text input** — dictate in Swedish or type; live transcription
  with automatic stop on silence
- **Automatic event extraction** — an LLM splits the sentence into discrete
  steps and infers chronological order even when it isn't stated
- **Pictogram matching** — ARASAAC lookup with Swedish-to-English fallback,
  and an LLM choosing among candidates
- **Visual schedule** — vertical, chronological, low sensory noise, read-only
- **Saved schedules** — reuse a routine without regenerating it
- **Person profile** — free-text notes for anyone working with the child
- **Persistent cache** — event-to-pictogram decisions survive between sessions

## Architecture

Layered MVVM, with dependencies pointing one way only:

```
Views (SwiftUI)      →  what the user sees
ViewModels           →  screen state, @MainActor
Services             →  network, parsing, persistence — nonisolated
Models               →  plain data
```

Every service takes its collaborators through an initializer with a default
value:

```swift
init(client: NetworkClient = URLSessionClient())
```

In the app that reads as `ArasaacService()`. In tests it becomes
`ArasaacService(client: fake)`. That single decision is what makes the
business logic testable without a network, without a simulator, and in
milliseconds — including the offline and rate-limit paths, which are otherwise
awkward to reproduce.

The same pattern is applied to the cache (`PictogramCache`) and to the
schedule store, so a single set of test doubles covers the whole app.

**Concurrency:** models and network services are `nonisolated`; view models are
`@MainActor`. The boundary is explicit rather than incidental, which is what
Swift's strict concurrency checking is for.

## Process

The app was built spec-first. Before writing code for a feature, I wrote a
short specification: numbered requirements in EARS format ("When X, the system
shall Y" / "If X, then the system shall Y"), an explicit out-of-scope list, and
completion criteria. Then a technical plan naming the components and the order
to build them.

Thirty-nine numbered requirements across five features. The `// RF-14`-style
comments in the source point back to the requirement that motivated each piece
of logic, so the reasoning behind a given branch is traceable rather than
folklore.

Two decisions worth mentioning, because they were trade-offs rather than wins:

- **Pictogram selection is batched.** The first design asked the LLM to choose
  a pictogram per event, which meant up to seven extra calls per schedule. It
  became one call carrying all candidates.
- **The cache cannot be cleared in v1.** Entries persist and there is no UI to
  remove them, so a bad mapping is permanent for that user. This was recorded
  as a known limitation at spec time rather than discovered later.

## Testing

26 unit tests covering the network services, the cache, and the schedule store.

The interesting one is `testUsesCacheWithoutHittingTheNetwork`: it injects a network
client that always fails, and passes. That is unambiguous proof the cache
prevented the call, rather than a test that happens to be green.

Speech recognition is verified manually on a physical device — the iOS
simulator cannot initialize a recognizer, so those paths are not unit tested.

## Running it

Requires Xcode 16+ and an Anthropic API key.

```bash
git clone https://github.com/Ilias-mk/PictoDia.git
cd PictoDia
cp Secrets.xcconfig.example Secrets.xcconfig
# add your key to Secrets.xcconfig, then open PictoDia.xcodeproj
```

The key is read from the build configuration rather than hardcoded. Note that
this protects the repository, not the binary — a shipped app would need a
backend proxy. For a portfolio prototype the distinction is documented rather
than solved.

## Limitations

Stated plainly, because a prototype that claims to be finished is less useful
than one that says what it isn't:

- **Swedish only.** The extraction prompt and pictogram lookup both assume it.
- **Not validated with practitioners.** The design follows published guidance
  on visual schedules, but no speech therapist or occupational therapist has
  reviewed it.
- **Not commercially usable as-is.** ARASAAC pictograms are CC BY-NC-SA;
  non-commercial use only.
- **No backend.** The API key ships in the binary.
- **Similar tools exist** — DictaPicto and Pictogramas.arg cover comparable
  ground in Spanish. This one targets Swedish, which appears underserved.

## Credits

Pictograms: [ARASAAC](https://arasaac.org), author Sergio Palao, property of
the Government of Aragón, licensed under CC BY-NC-SA.

---

Built by Ilias, computer and systems science student at Stockholm University
(DSV).
