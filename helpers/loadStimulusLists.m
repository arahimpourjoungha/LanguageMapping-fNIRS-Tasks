function config = loadStimulusLists(config, stimFile)
% LOADSTIMULUSLISTS  Replace the placeholder stimulus lists with local ones.
%
%   config = loadStimulusLists(config)            % uses config/stimuli_local.m
%   config = loadStimulusLists(config, stimFile)  % any file in the same format
%
% The study's word and sentence lists are not distributed with this code.
% config_language_mapping.m ships PLACEHOLDER lists of the right size; a
% user who has the real lists puts them in a local, git-ignored MATLAB file
% (default: config/stimuli_local.m) that defines a function returning a
% struct. See config/stimuli_local_template.m for the format; copy it to
% config/stimuli_local.m, rename the function on its first line to
% stimuli_local, and replace the items.
%
% Required fields of the returned struct:
%   nouns            1xN cellstr   Task 1 nouns
%   relatedPairs     Nx2 cellstr   Task 2 related word pairs
%   unrelatedPairs   Nx2 cellstr   Task 2 unrelated word pairs
%   activeSentences  1xN cellstr   Task 4 sentences, each containing '___'
% Optional fields (the built-in defaults are kept if absent):
%   letters, controlPrompts (Task 3), realWordsForControl (Task 4)
%
% Every list is checked against what one session of the current design
% needs; fewer items is an error. Fewer than two sessions' worth is a
% warning, because session 2 would then repeat items (see pickItems).
%
% If the file does not exist, config is returned unchanged with
% config.stimulusSource = "placeholder" and a warning.

if nargin < 2 || isempty(stimFile)
    root = fileparts(fileparts(mfilename('fullpath')));
    stimFile = fullfile(root, 'config', 'stimuli_local.m');
end
stimFile = char(stimFile);

if ~exist(stimFile, 'file')
    config.stimulusSource = "placeholder";
    warning('loadStimulusLists:placeholder', ...
        ['Using PLACEHOLDER stimulus lists (no %s found).\n' ...
         'The battery runs, but participants will see labels such as NOUN01.\n' ...
         'See config/stimuli_local_template.m to supply the real lists.'], stimFile);
    return
end

[folder, name, ext] = fileparts(stimFile);
if ~strcmpi(ext, '.m')
    error('loadStimulusLists:format', 'Stimulus file must be a MATLAB .m function file: %s', stimFile);
end
oldPath = addpath(folder);
restorePath = onCleanup(@() path(oldPath));
s = feval(name);
clear restorePath
if ~isstruct(s) || ~isscalar(s)
    error('loadStimulusLists:format', '%s must return a scalar struct.', stimFile);
end

% ---- Required counts for ONE session of the current design --------------
nA = config.numActiveBlocks;
nC = config.numControlBlocks;
need.nouns           = nA * config.t1.itemsPerBlock;
need.relatedPairs    = nA * config.t2.trialsPerBlock / 2;
need.unrelatedPairs  = need.relatedPairs;
need.activeSentences = nA * config.t4.itemsPerBlock;
need.letters         = nA;
need.controlPrompts  = nC;
need.realWordsForControl = 1;

% field name -> {task struct, required?, is a pair list?}
spec = { ...
    'nouns',               't1', true,  false; ...
    'relatedPairs',        't2', true,  true;  ...
    'unrelatedPairs',      't2', true,  true;  ...
    'activeSentences',     't4', true,  false; ...
    'letters',             't3', false, false; ...
    'controlPrompts',      't3', false, false; ...
    'realWordsForControl', 't4', false, false};

for i = 1:size(spec, 1)
    [f, task, required, isPair] = spec{i, :};
    if ~isfield(s, f)
        if required
            error('loadStimulusLists:missingField', '%s: required field "%s" is missing.', stimFile, f);
        end
        continue
    end
    v = s.(f);
    if isstring(v), v = cellstr(v); end
    if ~iscellstr(v)
        error('loadStimulusLists:type', '%s: field "%s" must be a cell array of text.', stimFile, f);
    end
    if isPair
        if size(v, 2) ~= 2
            error('loadStimulusLists:shape', '%s: field "%s" must be an Nx2 cell (one pair per row).', stimFile, f);
        end
        n = size(v, 1);
    else
        v = v(:)';                        % tasks build struct arrays from 1xN lists
        n = numel(v);
    end
    if strcmp(f, 'activeSentences') && ~all(contains(v, '___'))
        error('loadStimulusLists:blank', '%s: every activeSentences item must contain ''___''.', stimFile);
    end
    if n < need.(f)
        error('loadStimulusLists:tooFew', '%s: "%s" has %d items; one session needs %d.', ...
            stimFile, f, n, need.(f));
    end
    if n < 2 * need.(f) && ~strcmp(f, 'realWordsForControl')
        warning('loadStimulusLists:fewForTwoSessions', ...
            '%s: "%s" has %d items; two non-overlapping sessions need %d.', ...
            stimFile, f, n, 2 * need.(f));
    end
    config.(task).(f) = v;
end

config.stimulusSource = string(stimFile);
fprintf('Stimulus lists loaded from %s\n', stimFile);
end
