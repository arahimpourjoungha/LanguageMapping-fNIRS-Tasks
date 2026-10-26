function [subjectID, sessionID, taskOrder, demographics, ok] = promptSessionInfo(config)
% PROMPTSESSIONINFO  Pop a GUI dialog to collect run info before the experiment.
%
%   [subjectID, sessionID, taskOrder, demographics, ok] = promptSessionInfo(config)
%
% Uses a graphical inputdlg (NOT a command-window prompt), so it does not
% interfere with the experiment and honours the "no command-window input"
% design goal. Pre-filled with the defaults from config.
%
% Collects participant demographics alongside the IDs. The pilot left age,
% sex, handedness and language history blank, which made its lateralisation
% result impossible to place against the ~95% left-dominance base rate --
% that figure is specific to right-handers. Handedness is therefore
% validated, not merely requested.
%
% Task selection is a string of digits 1-4 (the experimenter's shorthand):
%   '1234' -> run all four tasks in order
%   '12'   -> run tasks 1 then 2
%   '3'    -> run task 3 only
%   '4213' -> run in that custom order
% Digits outside 1-4 (and repeats) are ignored; if nothing valid is entered,
% the config default order is used.
%
% Re-prompts (keeping what was typed) if config.requireDemographics is true
% and age/sex/handedness are missing or unparseable.
%
% Returns ok=false if the experimenter pressed Cancel/closed the dialog.

defaultTasks = strrep(num2str(config.taskOrder), ' ', '');

taskLegend = sprintf(['Tasks to run (digits, e.g. 1234=all, 12=tasks 1&2, 3=task 3):\n' ...
                      '   1 = Covert Verb Generation\n' ...
                      '   2 = Semantic Relatedness Decision\n' ...
                      '   3 = Phonemic / Letter Fluency\n' ...
                      '   4 = Sentence Completion']);
prompt   = { 'Subject ID:', ...
             'Session ID:', ...
             'Age (years):', ...
             'Sex  (M / F / O):', ...
             'Handedness  (L / R / A = ambidextrous):', ...
             'Edinburgh Handedness score (-100..100, blank if not measured):', ...
             'Language history (native language; other languages + age learned):', ...
             taskLegend };
dlgTitle = 'Language Mapping — Session Setup';
numLines = [1 70];

answer = { config.subjectID, config.sessionID, ...
           numOrEmpty(config.demographics.age), ...
           config.demographics.sex, ...
           config.demographics.handedness, ...
           numOrEmpty(config.demographics.handScore), ...
           config.demographics.language, ...
           defaultTasks };

while true
    answer = inputdlg(prompt, dlgTitle, numLines, answer);

    if isempty(answer)
        ok = false;
        subjectID = ''; sessionID = ''; taskOrder = []; demographics = struct();
        return;
    end

    subjectID = strtrim(answer{1});
    sessionID = strtrim(answer{2});
    taskStr   = strtrim(answer{8});

    % Fall back to defaults if either ID is left blank.
    if isempty(subjectID), subjectID = config.subjectID; end
    if isempty(sessionID), sessionID = config.sessionID; end

    % ---- Demographics ---------------------------------------------------
    demographics = struct( ...
        'age',        str2double(strtrim(answer{3})), ...   % NaN if blank/bad
        'sex',        upper(strtrim(answer{4})), ...
        'handedness', upper(strtrim(answer{5})), ...
        'handScore',  str2double(strtrim(answer{6})), ...
        'language',   strtrim(answer{7}));

    problems = validateDemographics(demographics);
    if isempty(problems) || ~config.requireDemographics
        if ~isempty(problems)
            warning('promptSessionInfo:incomplete', ...
                'Proceeding with incomplete demographics: %s', strjoin(problems, '; '));
        end
        break;
    end

    uiwait(errordlg([{'Please correct the following:'; ''}; problems(:)], ...
                    'Missing participant information', 'modal'));
end

% Parse the task digit-string into an order vector.
taskOrder = [];
for i = 1:numel(taskStr)
    d = str2double(taskStr(i));
    if ~isnan(d) && d >= 1 && d <= 4
        taskOrder(end+1) = d; %#ok<AGROW>
    end
end
if isempty(taskOrder)
    taskOrder = config.taskOrder;   % nothing valid typed -> use default
end

ok = true;
end

% =========================================================================
function problems = validateDemographics(d)
% Collect every problem at once so the experimenter fixes them in one pass.
problems = {};

if isnan(d.age) || d.age < 5 || d.age > 120
    problems{end+1} = 'Age must be a number between 5 and 120.';
end
if ~ismember(d.sex, {'M','F','O'})
    problems{end+1} = 'Sex must be M, F or O.';
end
if ~ismember(d.handedness, {'L','R','A'})
    problems{end+1} = 'Handedness must be L, R or A.';
end
% Handedness score is optional, but if given it must be in range.
if ~isnan(d.handScore) && (d.handScore < -100 || d.handScore > 100)
    problems{end+1} = 'Edinburgh Handedness score must be between -100 and 100 (or blank).';
end
if isempty(d.language)
    problems{end+1} = 'Language history must not be blank.';
end
end

function s = numOrEmpty(v)
% Numeric default -> dialog text ('' for NaN so the field starts empty).
if isnan(v)
    s = '';
else
    s = num2str(v);
end
end
