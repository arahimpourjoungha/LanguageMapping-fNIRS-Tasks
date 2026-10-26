# LanguageMapping-fNIRS-Tasks

A MATLAB + Psychtoolbox 3 battery of four **covert (silent) language tasks**
in a **block design**, for language lateralization with fNIRS. Covert
performance keeps speech and jaw-motion artifacts out of the signal. No
command-window input is needed during a run.

**Status: pilot task battery, work in progress.** This repository holds the
task code only. Analysis code: in progress, will be added.

**Stimulus lists are not included; the task runs with placeholder items.
Contact the author for the stimulus lists.** See
[Stimulus lists](#stimulus-lists) for how to plug them in.

## Tasks

| # | Task | Active condition | Control condition |
|---|------|------------------|-------------------|
| 1 | Covert Verb Generation | Silently generate verbs for each noun; press any arrow once a verb comes to mind | Symbol strings: all same (RIGHT) / one different (LEFT) |
| 2 | Semantic Relatedness | Word pairs: related (RIGHT) / unrelated (LEFT) | Symbol pairs: same (RIGHT) / different (LEFT) |
| 3 | Phonemic / Letter Fluency | Silently generate words starting with a cue letter, then type one (5 s) | Silent counting / repetition; instruction for 6 s, then a single glyph |
| 4 | Sentence Completion | Silently complete the blank; press any arrow once the word comes to mind | Nonsense sentences: contains a real word (RIGHT) / none (LEFT) |

Per task: 6 active + 6 control blocks of 20 s, alternating (12 x 20 s =
240 s), separated by 10 s of interleaved rest (11 x 10 s = 110 s), with 15 s
of rest before the first and after the last block, then an 8 s break:
about **6.5 min per task** (Task 3 is ~30 s longer because of the typed
check after each active block). Every block that collects responses prints
its response rate to the console during the session and logs a
`lowResponseRate` event when it falls below `config.minResponseRate`.

## Requirements

- MATLAB (developed with R2024b).
- [Psychtoolbox 3](http://psychtoolbox.org) for running the battery. It is
  **not** included. Install it so it is on the MATLAB path, or set the
  environment variable `PSYCHTOOLBOX_DIR` to its folder
  (`helpers/addPsychtoolboxPath.m`). Psychtoolbox 3.0.19+ needs a paid
  licence on macOS and Windows; to let the battery activate it
  automatically, set `PTB_LICENCE_KEY` or put the key in the git-ignored
  file `helpers/ptb_licence_key.local.txt` (`helpers/ptbLicenceKey.m`). No
  key is shipped.
- The test suite needs no Psychtoolbox.

## Running

```matlab
cd LanguageMapping-fNIRS-Tasks
main_language_mapping_fNIRS
```

A startup dialog asks for Subject ID, Session ID, demographics (age, sex,
handedness, Edinburgh score, language history; required unless
`config.requireDemographics = false`) and which tasks to run (digits, e.g.
`1234`, `24`). Without a GUI the defaults in `config_language_mapping.m`
are used, and the demographics must then be filled in there (or
`config.requireDemographics` set to false).

- **Session ID**: its trailing number is the visit number (`ses01` -> 1,
  `ses02` -> 2). Session 2 gets items that session 1 did not use; set
  `config.sessionIndex` to override.
- **Quick test**: `config.dryRun = true` (or
  `config_language_mapping(struct('dryRun', true))`) runs the whole battery
  in a window with 2 + 2 short blocks per task.
- `config.skipSyncTests` is `0` by default; keep it at 0 for real data.

## Response keys

| Key | Meaning |
|-----|---------|
| LeftArrow | no / unrelated / different |
| RightArrow | yes / related / same |
| Space | continue past instruction and break screens |
| Escape | abort and save partial data |

## Output

Written to `data/<subjectID>/<sessionID>/` (git-ignored):

- one CSV per task: `<subj>_<sess>_<TaskName>_<timestamp>.csv`
- `<subj>_<sess>_combined_<timestamp>.mat` (`events`, `eventsTable`, `config`)
- `<subj>_<sess>_triggers_<timestamp>.txt` (`getSecs  secondsSinceT0  code`)
- `<subj>_<sess>_sync_<timestamp>.txt` (t0 anchor, see below)
- `<subj>_<sess>_subject_<timestamp>.csv` (demographics, one row)

Each event row has: `subjectID, sessionID, taskName, blockNumber,
blockType (active/control/rest), trialNumber, stimulus, correctAnswer,
participantResponse, accuracy, reactionTime, eventName, eventOnsetGetSecs,
eventOnsetRelative, eventDuration, triggerCode`.

### Synchronising with the fNIRS recording

Right after the welcome screen, `main` reads `GetSecs` and the wall clock
back to back (t0), sends trigger `1` and logs `sessionStart`.
`eventOnsetRelative` is seconds since t0 and is the column to align on; the
sync file gives `absolute_time = tZeroPosix + eventOnsetRelative`. Trigger
`2` / `sessionEnd` closes the session, so drift between the two clocks can
be checked. Best practice: start the fNIRS recording first so trigger 1 is
in the fNIRS file, and take that marker as time 0.

## Trigger codes

| Task | Active block | Control block | Active trial | Control trial | Other |
|------|:---:|:---:|:---:|:---:|:---:|
| Session | | | | | 1 = start (t0), 2 = end, 3 = interleaved rest |
| 1 Verb Generation | 101 | 102 | 111 | 112 | |
| 2 Semantic | 201 | 202 | 211 | 212 | 221 = response |
| 3 Fluency | 301 | 302 | 311 = letter cue | 312 = control cue | |
| 4 Sentence | 401 | 402 | 411 | 412 | |

`helpers/sendTrigger.m` prints each code and appends it to the trigger log
(`config.trigger.method = 'console'`). Commented templates for LSL, serial
and parallel-port output are in the same file; set `config.trigger.method`
to `'lsl'`, `'serial'` or `'parallel'` and fill in the matching block.

## Stimulus lists

`config_language_mapping.m` ships labelled PLACEHOLDER lists with the same
counts and structure as the study lists (`NOUN01`..`NOUN60`, `RELA01`/`RELB01`
pairs, `PLACEHOLDER sentence 01 ___.` ...). To use real lists:

1. Copy `config/stimuli_local_template.m` to `config/stimuli_local.m`
   (git-ignored) and change its first line to `function s = stimuli_local()`.
2. Replace the items. The template documents the fields and counts:

   | Field | Shape | One session | Two sessions without repeats |
   |-------|-------|:---:|:---:|
   | `nouns` | 1xN | 24 | 48 |
   | `relatedPairs` | Nx2 | 18 | 36 |
   | `unrelatedPairs` | Nx2 | 18 | 36 |
   | `activeSentences` (each with `___`) | 1xN | 24 | 48 |

   Optional: `letters`, `controlPrompts`, `realWordsForControl`.

`helpers/loadStimulusLists.m` loads the file when the config is built,
checks counts and shapes, and prints which source is in use; without the
file it warns that placeholders are being used.

## Layout

```
main_language_mapping_fNIRS.m   entry point
config_language_mapping.m       all settings (timing, keys, triggers, placeholder lists)
runVerbGeneration.m             Task 1
runSemanticRelatedness.m        Task 2
runPhonemicFluency.m            Task 3
runSentenceCompletion.m         Task 4
helpers/                        block order, item selection, seeds, drawing,
                                triggers, logging, saving, PTB setup, stimulus loader
config/stimuli_local_template.m format of the local stimulus file
tests/                          headless matlab.unittest suite + Psychtoolbox stubs
docs/known_issues.md            known issues and limitations
```

## Tests

```matlab
run tests/run_tests.m
```

or `matlab -batch "run('tests/run_tests.m')"`. The suite checks block order
and counterbalancing, per-subject and per-session item selection (no
overlap between sessions 1 and 2), seeds, nonsense-string generation,
config timing and pool sizes, the stimulus loader, log/CSV columns, and runs
all four tasks end to end (full and dry-run designs) against stub versions
of the Psychtoolbox functions in `tests/stubs/` with a virtual clock. The
stubs are added to the path only while the tests run.

## Known issues

See [docs/known_issues.md](docs/known_issues.md).

## Citation and licence

See [CITATION.cff](CITATION.cff). MIT licence, see [LICENSE](LICENSE).
