function main_language_mapping_fNIRS()
% MAIN_LANGUAGE_MAPPING_FNIRS  fNIRS language-lateralization pilot battery.
%
% Runs up to four covert language tasks (block design) with Psychtoolbox 3:
%   1. Covert Verb Generation
%   2. Semantic Relatedness Decision
%   3. Phonemic / Letter Fluency
%   4. Sentence Completion
%
% All editable parameters live in config_language_mapping.m. The stimulus
% lists shipped there are placeholders; real lists are read from the local
% file config/stimuli_local.m (see config/stimuli_local_template.m).
% No command-window input is required during the experiment.
%
% Keys:  LeftArrow = no/unrelated/different   RightArrow = yes/related/same
%        Space = continue                     Escape = abort + save partial data
%
% Data is written to data/<subjectID>/<sessionID>/ (one CSV per task + one
% combined .mat). Requires Psychtoolbox 3 (see helpers/addPsychtoolboxPath.m).
%
% Usage:  >> cd to this folder, then  >> main_language_mapping_fNIRS

% ---- Make helpers visible ----------------------------------------------
thisDir = fileparts(mfilename('fullpath'));
addpath(fullfile(thisDir, 'helpers'));

% ---- Psychtoolbox ------------------------------------------------------
% config_language_mapping calls KbName, so PTB has to be on the path BEFORE
% the config is loaded. PTB is not bundled: it must already be on the path,
% or the environment variable PSYCHTOOLBOX_DIR must name its folder.
addPsychtoolboxPath();

% ---- Load configuration -------------------------------------------------
config = config_language_mapping();

% ---- Optional startup dialog (subjectID / sessionID / task selection) ---
% Uses a GUI dialog, not command-window input. Skipped automatically if no
% Java GUI is available (e.g. matlab -nodisplay), falling back to defaults.
if config.promptAtStartup && usejava('awt')
    [sid, ses, torder, demo, ok] = promptSessionInfo(config);
    if ~ok
        fprintf('Session setup cancelled. Nothing was run.\n');
        return;
    end
    config.subjectID    = sid;
    config.sessionID    = ses;
    config.taskOrder    = torder;
    config.demographics = demo;
elseif config.requireDemographics
    % No dialog available: demographics must already be filled in by hand in
    % config_language_mapping.m, or the session would silently record none.
    if isnan(config.demographics.age) || isempty(config.demographics.handedness)
        error('main:missingDemographics', ...
            ['Demographics are required but no startup dialog is available.\n' ...
             'Either set config.demographics.* in config_language_mapping.m ' ...
             'or set config.requireDemographics = false.']);
    end
end

% ---- Reproducible randomisation ----------------------------------------
% Reproducible per participant, but different between participants -- see
% config.seedPerSubject and helpers/subjectSeed.m for why that matters.
if isfield(config, 'seedPerSubject') && config.seedPerSubject
    config.effectiveSeed = subjectSeed(config.randomSeed, config.subjectID, config.sessionID);
else
    config.effectiveSeed = config.randomSeed;
end
rng(config.effectiveSeed);
fprintf('Randomisation seed: %d\n', config.effectiveSeed);
fprintf('Session %d for this participant (from Session ID "%s") -- stimuli drawn accordingly.\n', ...
        sessionIndexReport(config), config.sessionID);

% ---- Prepare data folder + fresh log -----------------------------------
% Output is organised as:  data/<subjectID>/<sessionID>/
% (mkdir creates the intermediate folders as needed).
config.dataFolder = fullfile(thisDir, config.dataFolder, config.subjectID, config.sessionID);
if ~exist(config.dataFolder, 'dir')
    mkdir(config.dataFolder);
end
config.trigger.logFile = fullfile(config.dataFolder, ...
    sprintf('%s_%s_triggers_%s.txt', config.subjectID, config.sessionID, config.startTimestamp));
initExperimentLog();

% ---- Everything in one try/catch so the screen always closes -----------
try
    % --- Psychtoolbox / screen setup ---
    PsychDefaultSetup(1);                 % unify key names, keep 0-255 colours
    Screen('Preference', 'SkipSyncTests', config.skipSyncTests);
    if config.skipSyncTests
        warning('SkipSyncTests is ON. Set config.skipSyncTests=0 for real data!');
    end

    if isempty(config.screenNumber)
        screenNo = max(Screen('Screens'));
    else
        screenNo = config.screenNumber;
    end

    if config.dryRun
        % Windowed mode for quick testing (see config.dryRun).
        [win, ~] = Screen('OpenWindow', screenNo, config.backgroundColor, config.dryRunWindowRect);
    else
        [win, ~] = Screen('OpenWindow', screenNo, config.backgroundColor);
    end
    Screen('BlendFunction', win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Priority(MaxPriority(win));
    HideCursor(win);
    ListenChar(2);                        % suppress keystrokes to command window

    % --- Welcome screen ---
    welcome = sprintf(['Language Mapping\n\n' ...
        'Keep your head still and stay silent (covert task).\n\n' ...
        'Press SPACE to begin.']);
    showMessageWaitKey(win, config, welcome);

    % --- Synchronisation anchor (t0) ---
    % GetSecs counts from machine boot, so its absolute value is meaningless
    % offline. Here we pin it to wall clock ONCE: the two reads below are
    % adjacent so they refer to the same instant (sub-ms apart). Every
    % eventOnsetRelative in the logs is then seconds from this point, and
    % absolute time = tZeroPosix + eventOnsetRelative.
    tZeroGetSecs = GetSecs;
    tZeroClock   = datetime('now', 'TimeZone', 'local');
    config.sync = struct( ...
        'tZeroGetSecs', tZeroGetSecs, ...
        'tZeroPosix',   posixtime(tZeroClock), ...
        'tZeroClock',   string(tZeroClock, 'yyyy-MM-dd HH:mm:ss.SSS'), ...
        'timeZone',     string(tZeroClock.TimeZone));
    sendTrigger(config.trigger.sessionStart, config);
    logEvent(config, struct('taskName', "Session", 'eventName', "sessionStart", ...
        'eventOnsetGetSecs', tZeroGetSecs, 'eventDuration', 0, ...
        'triggerCode', config.trigger.sessionStart));

    % --- Run tasks in configured order ---
    for t = config.taskOrder(:)'
        switch t
            case 1, runVerbGeneration(win, config);
            case 2, runSemanticRelatedness(win, config);
            case 3, runPhonemicFluency(win, config);
            case 4, runSentenceCompletion(win, config);
            otherwise
                warning('main:unknownTask', 'Ignoring unknown task id %d.', t);
        end
    end

    % --- Done ---
    % Closing marker: its wall-clock vs. relative time lets you check drift
    % between the stimulus PC and the fNIRS clock over the whole session.
    tEnd = GetSecs;
    sendTrigger(config.trigger.sessionEnd, config);
    logEvent(config, struct('taskName', "Session", 'eventName', "sessionEnd", ...
        'eventOnsetGetSecs', tEnd, 'eventDuration', 0, ...
        'triggerCode', config.trigger.sessionEnd));

    showTimedScreen(win, config, sprintf('All tasks complete.\n\nThank you!'), 3, true);
    saveAll(config);

    cleanup();
    fprintf('Experiment finished normally. Data in: %s\n', config.dataFolder);

catch ME
    % --- Abort / error path: always save partial data + close screen ---
    cleanup();
    try
        saveAll(config);
    catch
    end
    if strcmp(ME.identifier, 'LMAP:abort')
        fprintf('\n*** Experiment ABORTED by user. Partial data saved to %s ***\n', config.dataFolder);
    else
        fprintf(2, '\n*** ERROR: %s ***\n', ME.message);
        fprintf(2, 'Partial data (if any) saved to %s\n', config.dataFolder);
        rethrow(ME);   % show full stack for debugging
    end
end
end

% =========================================================================
function cleanup()
% Restore keyboard/cursor and close all PTB windows. Each guarded so a
% failure in one restore step never blocks the others or the final sca.
restore = {@() ListenChar(0), @() ShowCursor, @() Priority(0), @() sca};
for i = 1:numel(restore)
    try
        restore{i}();
    catch
        % Deliberately swallowed. cleanup() runs on the error path, so a
        % throw here would replace the real failure with a confusing one --
        % which is exactly what an unguarded sca used to do when Screen was
        % unavailable and no window had been opened yet.
    end
end
end
