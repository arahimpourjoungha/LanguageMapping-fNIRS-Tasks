function config = config_language_mapping(opts)
% CONFIG_LANGUAGE_MAPPING  Central configuration for the fNIRS language battery.
%
%   config = config_language_mapping()
%   config = config_language_mapping(opts)
%
% opts (optional struct; every field optional):
%   .dryRun           true/false, overrides config.dryRun set below
%   .useLocalStimuli  false = keep the built-in PLACEHOLDER lists even if a
%                     local stimulus file exists (default true)
%   .stimulusFile     path of a stimulus file to load instead of the default
%                     config/stimuli_local.m (see config/stimuli_local_template.m)
%
% Edit ANYTHING in this file to change subjects, timing, stimuli, colours,
% triggers, etc. Nothing here talks to Psychtoolbox directly, so it is safe
% to open and read even without PTB installed.
%
% Design summary (per task, block design):
%   12 blocks x 20 s = 240 s of task
%   6 active + 6 control blocks, alternating,
%   separated by 10 s interleaved rest (11 x 10 s = 110 s),
%   plus 15 s rest before the first and after the last block.
%   ~6.5 min per task including the end-of-task break.
%
% STIMULUS LISTS: the word and sentence lists below are PLACEHOLDERS with the
% same counts and structure as the study lists, which are not distributed.
% Real lists are read from a local, git-ignored file (config/stimuli_local.m)
% by helpers/loadStimulusLists.m at the end of this function.
%
% Returns a single struct `config` consumed by main_language_mapping_fNIRS.

if nargin < 1 || isempty(opts), opts = struct(); end

% =========================================================================
% 1. SESSION / SUBJECT  (edit for each run)
% =========================================================================
config.subjectID = 'test001';    % <- default; editable, or set in the startup dialog
config.sessionID = 'pilot001';   % <- default; editable, or set in the startup dialog
config.randomSeed = 1;           % base seed for deterministic randomisation

% With seedPerSubject false, EVERY participant gets the identical shuffle --
% same cue letter in block 1, same 24 of the 30 sentences, same 6 never shown.
% Order effects are then perfectly confounded with item identity across the
% whole study. True derives the actual seed from subjectID + sessionID, which
% counterbalances across people while staying exactly reproducible for any one
% of them (re-run the same subject and you get the same sequence back).
config.seedPerSubject = true;

% Which visit this is for this participant. Session 2 uses a different slice of
% every stimulus pool than session 1, so repeat visits carry no items over.
%
% LEAVE THIS EMPTY. It is read from the trailing number of the Session ID typed
% in the startup dialog, so 'pilot001' -> 1, 'pilot002' -> 2, and nobody has to
% remember to edit this file between visits. Set it to a number here only to
% override that. See helpers/pickItems.m.
%
% Two full sessions are available at the current pool sizes before items repeat.
config.sessionIndex = [];

% ---- Participant demographics -------------------------------------------
% Collected in the startup dialog and written to <subj>_<sess>_subject_*.csv.
% These were blank for the pilot, which is why its 95%-left-lateralised
% reference figure could not be applied: that base rate is for RIGHT-handers.
% Handedness in particular is not optional for a lateralisation study.
%   sex        : M | F | O  (O = other / prefer not to say)
%   handedness : L | R | A  (A = ambidextrous)
%   handScore  : Edinburgh Handedness Inventory laterality quotient,
%                -100 (pure left) .. +100 (pure right). NaN if not measured.
%   language   : native language(s), other languages + age of acquisition.
config.demographics.age        = NaN;
config.demographics.sex        = '';
config.demographics.handedness = '';
config.demographics.handScore  = NaN;
config.demographics.language   = '';

% Require age/sex/handedness before the session can start. Leave true for
% real data collection; set false only for equipment tests.
config.requireDemographics = true;

% If true, a GUI dialog at launch asks the experimenter for subjectID,
% sessionID, and which tasks to run (digit string, e.g. 1234 = all, 12 =
% tasks 1&2, 3 = task 3 only). The values above/below are the dialog
% defaults. Set false to skip the dialog and run fully code-driven.
config.promptAtStartup = true;

% Which tasks to run and in what order (1..4). e.g. [1 2 3 4] or [2 4].
%   1 = Covert Verb Generation
%   2 = Semantic Relatedness Decision
%   3 = Phonemic / Letter Fluency
%   4 = Sentence Completion
config.taskOrder = [1 2 3 4];

% =========================================================================
% 2. SCREEN / DISPLAY
% =========================================================================
% DRY RUN: quick windowed test with shortened timings and fewer blocks.
% Set true to click through all four tasks in ~a minute total; set false
% for real sessions. (Overrides are applied at the very bottom of this file.)
config.dryRun = false;
if isfield(opts, 'dryRun'), config.dryRun = logical(opts.dryRun); end
config.dryRunWindowRect = [100 100 1000 750];  % [x1 y1 x2 y2] windowed size

config.skipSyncTests = 0;        % 1 = skip PTB timing tests (DEV ONLY).
                                 % SET TO 0 for real data collection!
config.screenNumber  = [];       % [] = use max(Screen('Screens')); or set an index
config.backgroundColor = [0 0 0];      % RGB 0-255 (black)
config.textColor       = [255 255 255];% RGB 0-255 (white)
config.fixationColor   = [255 255 255];
config.textFont  = 'Arial';
config.textSize  = 60;           % main stimulus text size (px)
config.instrTextSize = 40;       % instruction / message text size (px)
config.textWrap  = 60;           % wrap instructions at N characters

% =========================================================================
% 3. GENERAL BLOCK-DESIGN TIMING
% =========================================================================
% More, shorter blocks (pilot review): 6 of each at 20 s rather
% than 5 at 30 s. More block onsets = better GLM efficiency for the same
% time on task.
config.numActiveBlocks  = 6;
config.numControlBlocks = 6;
config.blockDuration    = 20;    % seconds per block (informational; timing is per-trial)
config.startWithActive  = true;  % true = A C A C...; false = C A C A... (counterbalance)

config.includeRest   = true;     % show a rest screen before first / after last block
config.restDuration  = 15;       % seconds

% INTERLEAVED REST (pilot review). A rest period between every
% pair of blocks, so the haemodynamic response can return toward baseline
% and the active and control estimates stop bleeding into each other.
% Set interRestDuration = 0 to go back to back-to-back blocks.
config.interleaveRest     = true;
config.interRestDuration  = 10;  % seconds of rest BETWEEN blocks

config.breakDuration = 8;        % end-of-task break screen (seconds; SPACE skips)

% =========================================================================
% 3b. LIVE COMPLIANCE MONITORING
% =========================================================================
% In the pilot the participant stopped responding to the semantic control
% after two blocks and nothing flagged it until analysis. Response rate is
% now printed to the console after every block that collects responses, and
% falling below this fraction prints a loud warning and logs a
% 'lowResponseRate' event you can filter on later.
config.minResponseRate = 0.50;   % 0-1; warn below this

% =========================================================================
% 4. RESPONSE KEYS
% =========================================================================
KbName('UnifyKeyNames');
config.keys.left   = KbName('LeftArrow');   % no / unrelated / different
config.keys.right  = KbName('RightArrow');  % yes / related / same
config.keys.space  = KbName('space');       % continue
config.keys.escape = KbName('ESCAPE');      % abort + save partial data

% =========================================================================
% 5. OUTPUT / LOGGING
% =========================================================================
config.dataFolder = 'data';
config.startTimestamp = datestr(now, 'yyyymmdd_HHMMSS'); %#ok<TNOW1,DATST>

% =========================================================================
% 6. TRIGGERS  (see sendTrigger.m for hardware integration placeholders)
% =========================================================================
config.trigger.method = 'console';   % 'console' | 'lsl' | 'serial' | 'parallel'

% Session-level sync markers. The sessionStart trigger defines t0: every
% eventOnsetRelative in the logs is measured from it, so send it while the
% fNIRS system is already recording (see the sync .txt written next to the
% data). sessionEnd lets you check for clock drift across the session.
config.trigger.sessionStart = 1;
config.trigger.sessionEnd   = 2;
config.trigger.interRest    = 3;   % onset of an interleaved rest period

config.trigger.writeToLog = true;    % also append triggers to a text log file
config.trigger.logFile = fullfile(config.dataFolder, ...
    sprintf('%s_%s_triggers_%s.txt', config.subjectID, config.sessionID, config.startTimestamp));
% Hardware settings (used later; harmless placeholders for now):
config.trigger.serialPort   = 'COM3';   % e.g. 'COM3' (Win) or '/dev/tty.usbserial' (mac)
config.trigger.serialBaud   = 115200;
config.trigger.parallelAddr = hex2dec('0378'); % typical LPT1 base address
config.trigger.lslStreamName = 'LanguageMapping_Markers';

% =========================================================================
% TASK 1 : COVERT VERB GENERATION
% =========================================================================
config.t1.stimDuration = 2.0;   % noun / symbol on-screen time (s)
config.t1.fixDuration  = 2.5;   % inter-stimulus fixation / ITI (s)
config.t1.itemsPerBlock = 4;    % 4 x 4.5 s = 18 s, padded to the 20 s block

% Perceptual-decision control (pilot review): the symbol blocks
% now ask for a same/different judgement, so the control condition demands
% attention instead of passive viewing.
config.t1.verbControlRequiresResponse = true;

% CONFOUND CONTROL: with the line above true on its own, only the CONTROL
% blocks would involve a button press, so the active-control contrast would
% carry a motor component pointing the wrong way -- the pilot already showed
% control > active in right IFG/vlPFC, which abuts ventral premotor. With
% this true, active blocks press ANY arrow key once a verb comes to mind:
% motor demand is matched across conditions AND the press is the only
% compliance evidence a covert task can give.
config.t1.verbActiveRequiresResponse = true;

% Trigger codes
config.t1.trig.activeBlock  = 101;
config.t1.trig.controlBlock = 102;
config.t1.trig.activeTrial  = 111;
config.t1.trig.controlTrial = 112;

% Nouns: 6 blocks x 4 = 24 per session; 60 supplied so that two sessions
% draw non-overlapping sets (see helpers/pickItems.m).
% PLACEHOLDER items -- replace via config/stimuli_local.m.
config.t1.nouns = placeholderList('NOUN', 60);

% Symbol strings for the control condition (cycled to fill the control items).
% With verbControlRequiresResponse on, runVerbGeneration corrupts half of
% them by one character so "all same" vs "one differs" is a real judgement.
config.t1.symbolStimuli = {'####','%%%%','++++','XXXX','@@@@','===='};

% =========================================================================
% TASK 2 : SEMANTIC RELATEDNESS DECISION
% =========================================================================
config.t2.trialDuration = 3.0;  % total fixed trial length (s)
config.t2.stimMaxDur    = 2.5;  % max response window; fixation fills the rest
config.t2.trialsPerBlock = 6;   % 6 x 3 s = 18 s, padded to the 20 s block

% Trigger codes
config.t2.trig.activeBlock   = 201;
config.t2.trig.controlBlock  = 202;
config.t2.trig.activeTrial   = 211;
config.t2.trig.controlTrial  = 212;
config.t2.trig.response      = 221;

% Active word pairs: 40 related + 40 unrelated (Nx2 cell, one pair per row).
% The design needs 6 blocks x 6 trials = 36 active trials per session, i.e.
% 18 related + 18 unrelated, so two sessions draw non-overlapping sets.
% RightArrow = related (yes); LeftArrow = unrelated (no).
% PLACEHOLDER items -- replace via config/stimuli_local.m.
config.t2.relatedPairs   = [placeholderList('RELA', 40)', placeholderList('RELB', 40)'];
config.t2.unrelatedPairs = [placeholderList('UNRA', 40)', placeholderList('UNRB', 40)'];

% Control symbol pairs are GENERATED in runSemanticRelatedness.m (same/different).
config.t2.controlSymbols = {'%','#','+','X','@','&'};

% =========================================================================
% TASK 3 : PHONEMIC / LETTER FLUENCY
% =========================================================================
% One cue per 30 s block (the whole block shows a single cue).
% Compliance check (pilot review): a 5 s type-a-word screen after
% each active block. This is the only evidence that a covert task was
% actually performed, so it is now ON by default. It sits AFTER the block
% has ended, so block timing is unaffected.
config.t3.fluencyPostBlockCheck = true;
config.t3.postBlockCheckDuration = 5;   % seconds allowed for the typed word

% VISUAL MATCHING (pilot review). Active blocks show one large cue letter for
% the whole block; control blocks used to show a two-line instruction for the
% whole block, so the control condition was sustained READING -- a language
% task, engaging the very network being mapped, on top of a large low-level
% visual mismatch. Now the control prompt is shown only as a brief lead-in,
% after which the block body is a single large glyph, matching the active
% block. Set promptLeadIn to the block duration to restore the old behaviour.
config.t3.promptLeadIn  = 6;     % seconds the control instruction stays up
                                 % (3 s was too short to read it -- pilot feedback)
config.t3.controlGlyph  = '+';   % shown large for the rest of a control block

% Trigger codes
config.t3.trig.activeBlock  = 301;
config.t3.trig.controlBlock = 302;
config.t3.trig.activeCue    = 311;
config.t3.trig.controlCue   = 312;

% Active cue letters (one per active block; 6 needed per session). F, A and S
% are the validated COWAT triad and are listed first; the rest are comparable
% consonants so a second or third session need not reuse the same cues.
config.t3.letters = {'F','A','S','M','P','C','T','B','L','R','D','G'};

% Control prompts (one per control block; 6 needed). Silent counting /
% repetition.
% Wrapped in sprintf so '\n' becomes a real newline for on-screen wrapping.
config.t3.controlPrompts = { ...
    sprintf('Silently count:\n1, 2, 3, 4, 5 ...'), ...
    sprintf('Silently repeat the days\nof the week.'), ...
    sprintf('Silently count backwards\nfrom 20: 20, 19, 18 ...'), ...
    sprintf('Silently repeat the months\nof the year.'), ...
    sprintf('Silently count by twos:\n2, 4, 6, 8 ...'), ...
    sprintf('Silently repeat the four\nseasons.') };

% =========================================================================
% TASK 4 : SENTENCE COMPLETION
% =========================================================================
config.t4.stimDuration = 5.0;   % each sentence on screen (s)
config.t4.itemsPerBlock = 4;    % 4 x 5 s = 20 s per block

% Perceptual-decision control (pilot review). The nonsense
% sentences were passive viewing; now half of them contain one real English
% word and the participant judges which.
%   RIGHT arrow = contains a real word,  LEFT arrow = all nonsense.
% Same motor-confound caveat as Task 1 (see config.t1 notes above).
config.t4.controlRequiresResponse = true;

% Matched motor demand in active blocks (same reasoning as Task 1): press
% ANY arrow key once the completing word comes to mind. No correct answer --
% it keeps the button press out of the active-control contrast and doubles
% as compliance evidence for an otherwise covert task.
config.t4.activeRequiresResponse = true;
config.t4.realWordsForControl = { ...
    'table','river','window','pocket','garden','pencil','summer','yellow', ...
    'basket','candle','mirror','carpet','silver','forest','button','ticket' };

% Trigger codes
config.t4.trig.activeBlock  = 401;
config.t4.trig.controlBlock = 402;
config.t4.trig.activeTrial  = 411;
config.t4.trig.controlTrial = 412;

% Active fill-in-the-blank sentences (each contains the blank '___').
% Need 6 blocks x 4 items = 24 per session; 55 supplied so that two sessions
% draw non-overlapping sets.
% PLACEHOLDER items -- replace via config/stimuli_local.m.
config.t4.activeSentences = cellfun(@(x) ['PLACEHOLDER sentence ' x(end-1:end) ' ___.'], ...
    placeholderList('S', 55), 'UniformOutput', false);

% Control (nonsense) sentences: generated in runSentenceCompletion.m using
% makeNonsenseStrings(). A couple of hand-written examples are kept here so
% students can see the intended visual style / length.
config.t4.controlExamples = { ...
    'XQJ lormept zav ___ nush.', ...
    'Ral mipten sova ___ drel.' };

% =========================================================================
% INSTRUCTION TEXTS (shown to participants; SPACE continues)
% Each is wrapped in sprintf so the '\n' sequences become real newlines.
% =========================================================================
config.instr.verb = sprintf([ ...
    'COVERT VERB GENERATION\n\n' ...
    'You will see nouns on the screen.\n' ...
    'For each noun, silently think of action words\n' ...
    '(verbs) related to that noun.\n\n' ...
    'Sometimes you will see symbols instead (e.g. ####).\n' ...
    'For those, press the RIGHT arrow if all the symbols\n' ...
    'are the SAME, or the LEFT arrow if one is DIFFERENT.\n\n' ...
    'Please do NOT speak out loud.\n' ...
    'Keep your head still.\n\n' ...
    'Press SPACE to begin.']);

config.instr.semantic = sprintf([ ...
    'SEMANTIC RELATEDNESS\n\n' ...
    'You will see two words.\n\n' ...
    'Press the RIGHT arrow if they are RELATED in meaning.\n' ...
    'Press the LEFT arrow if they are NOT related.\n\n' ...
    'Respond as quickly and accurately as you can.\n\n' ...
    'Press SPACE to begin.']);

config.instr.fluency = sprintf([ ...
    'PHONEMIC / LETTER FLUENCY\n\n' ...
    'You will see a letter.\n' ...
    'Silently think of as many words as you can\n' ...
    'that begin with that letter.\n\n' ...
    'After each letter you will be asked to TYPE\n' ...
    'one of the words you thought of.\n\n' ...
    'Please do NOT speak out loud.\n' ...
    'Keep your head still.\n\n' ...
    'Press SPACE to begin.']);

config.instr.sentence = sprintf([ ...
    'SENTENCE COMPLETION\n\n' ...
    'You will see sentences with a blank.\n' ...
    'Silently think of the word that best\n' ...
    'completes the sentence.\n\n' ...
    'Some sentences are made of nonsense words.\n' ...
    'For those, press the RIGHT arrow if you spot a\n' ...
    'REAL word, or the LEFT arrow if there is none.\n\n' ...
    'Please do NOT speak out loud.\n' ...
    'Keep your head still.\n\n' ...
    'Press SPACE to begin.']);

config.instr.control = sprintf([ ...
    'Follow the instructions on the screen.\n' ...
    'Keep your eyes on the screen and keep your head still.']);

% =========================================================================
% LOCAL STIMULUS LISTS (replace the placeholders above, if present)
% =========================================================================
% Validated against the FULL design before any dry-run shrinking below.
if ~isfield(opts, 'useLocalStimuli') || opts.useLocalStimuli
    if isfield(opts, 'stimulusFile')
        config = loadStimulusLists(config, opts.stimulusFile);
    else
        config = loadStimulusLists(config);
    end
else
    config.stimulusSource = "placeholder";
end

% =========================================================================
% DRY-RUN OVERRIDES  (applied last so they win over everything above)
% =========================================================================
% NOT for real data: this just shrinks the design so you can eyeball the
% whole battery quickly in a window. Stimulus balancing/counterbalancing
% logic is unchanged; only counts and durations shrink.
if config.dryRun
    config.skipSyncTests   = 1;
    config.numActiveBlocks = 2;
    config.numControlBlocks= 2;
    config.blockDuration   = 3;    % used by Task 3 cue blocks
    config.restDuration    = 2;
    config.interRestDuration = 1;  % keep interleaved rest visible but short
    config.breakDuration   = 1;
    config.requireDemographics = false;  % don't block equipment tests
    config.t3.postBlockCheckDuration = 3;

    config.t1.itemsPerBlock = 3; config.t1.stimDuration = 0.4; config.t1.fixDuration = 0.1;
    config.t2.trialsPerBlock = 2; config.t2.trialDuration = 1.0; config.t2.stimMaxDur = 0.8;
    config.t4.itemsPerBlock = 2; config.t4.stimDuration = 0.6;
    config.t3.promptLeadIn = 1;    % keep the glyph visible in the short dry-run block
    % Task 3 has one cue per block and follows config.blockDuration above.
end

end

% =========================================================================
function c = placeholderList(prefix, n)
% PLACEHOLDERLIST  1xn cell of labelled placeholder items, e.g. NOUN01..NOUN60.
c = arrayfun(@(k) sprintf('%s%02d', prefix, k), 1:n, 'UniformOutput', false);
end
