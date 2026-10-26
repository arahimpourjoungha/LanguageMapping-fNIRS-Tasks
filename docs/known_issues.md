# Known issues

Issues noticed while preparing this release. Apart from the syntax fix
listed first, none of them has been changed in the code, so timing, block
structure, counterbalancing, seeds, triggers and logging match the pilot
battery exactly.

## Fixed

- **`main_language_mapping_fNIRS.m` did not parse.** Line 1 had stray text
  in front of the `function` keyword, and the help text had stray spaces
  inside "Decision". Both removed; no other change to the entry point's
  behaviour.

## Behaviour

1. **Reproducibility depends on the task order.** Item *selection*
   (`pickItems`) uses its own per-subject random stream, so the same subject
   always gets the same nouns, pairs, letters and sentences. But the
   control-condition strings (Tasks 1 and 2), the trial order of Task 2 and
   the real-word embedding of Task 4 use the global `rng`, which is seeded
   once in `main` and then consumed task by task. Running tasks `24` gives
   different control sequences and trial orders than running `1234` for the
   same subject and session.
2. **Task 2 is not balanced within blocks.** The 18 related and 18 unrelated
   active trials are shuffled across the whole session and then cut into
   blocks of 6, so a block can hold anything from 0 to 6 related pairs.
   (A comment in the pilot config said "~3 related / ~3 unrelated per
   block"; that was never enforced.)
3. **Task 3 control prompts repeat across sessions.** The pool holds 6
   prompts and a session needs 6, so session 2 gets the same prompts in the
   same order, and `pickItems:wrapped` is printed for every session after
   the first.
4. **Session number comes from the trailing digits of the Session ID.** A
   Session ID that ends in a date (`..._YYYYMMDD`) or another large number
   becomes a huge session index, and the slice wraps around
   the pool (a warning is printed). A Session ID with no trailing digits is
   always session 1, so a repeat visit silently reuses session 1's items.
   Set `config.sessionIndex` explicitly to avoid both.
5. **Typed-word check records modifier and arrow keys as letters.**
   `typeWord` keeps the first character of any key name, so Shift
   (`LeftShift`), arrow keys (`LeftArrow`, `RightArrow`), `Tab`, `CapsLock`
   etc. are typed as `l`, `r`, `t`, `c`. Typing a capital letter therefore
   inserts an extra character.
6. **Rest periods are not on the time grid.** Pre-task, post-task and
   interleaved rest screens last `duration` seconds from the moment they are
   drawn, so each adds about one frame plus up to 5 ms of polling. Over a
   task this accumulates to roughly 0.2-0.4 s. Block and trial onsets are
   logged, so analysis based on the logs is unaffected.
7. **Block length is not enforced for Tasks 2 and 4.** Task 1 uses
   `max(trial time, blockDuration)`; Tasks 2 and 4 wait for
   `blockDuration` after the trials. If trials are configured to take longer
   than `blockDuration`, the block silently overruns while the log still
   records `eventDuration = blockDuration`.
8. **Task 2 needs an even number of active trials.**
   `numActiveBlocks * t2.trialsPerBlock` must be even (half related, half
   unrelated); an odd product fails with a dimension error rather than a
   clear message.
9. **Output file names use the IDs unchanged.** A Subject or Session ID
   containing `/`, `\` or `:` produces an invalid path.

## Documentation inconsistencies in the code

- `config_language_mapping.m`, Task 3 section: "One cue per 30 s block"
  (blocks are 20 s).
- `runPhonemicFluency.m`: "Optional compliance check (kept OFF by default
  for clean timing)"; `config.t3.fluencyPostBlockCheck` is `true`.
- With the typed check on, Task 3 lasts about 30 s longer than the other
  tasks (6 active blocks x 5 s), i.e. about 7 min rather than 6.5 min.

The pilot README also stated that `config.skipSyncTests` defaults to 1 and
that `config.t1.verbActiveRequiresResponse` defaults to off; both are wrong
(the defaults are 0 and on). The README in this repository is corrected.

## Notes for whoever supplies the real stimulus lists

- The loader checks counts, shapes and the `___` blank, but not duplicates.
  The pilot's Task 2 lists reused several words: some words appear in two
  related pairs, some in two unrelated pairs, and some words occur in both
  lists. Task 1 nouns also overlapped with Task 2 words. Consider whether
  that matters for your design.
- Two of the pilot's Task 4 sentences share the same expected answer; if
  the shuffle puts both in one block, expect a repetition effect.
