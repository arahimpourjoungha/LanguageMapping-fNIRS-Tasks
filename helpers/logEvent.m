function logEvent(config, rec)
% LOGEVENT  Append one event to the global experiment log (EXPLOG).
%
%   logEvent(config, rec)
%
% `rec` is a struct with any subset of the fields defined in defaultRecord.
% Missing fields take their defaults. Text fields are coerced to string and
% numeric fields to double so that struct2table/writetable stay happy.
global EXPLOG %#ok<GVMIS>

d = defaultRecord(config);

% Merge provided fields over the defaults.
fn = fieldnames(rec);
for i = 1:numel(fn)
    if isfield(d, fn{i})
        d.(fn{i}) = rec.(fn{i});
    else
        warning('logEvent:unknownField', 'Ignoring unknown log field "%s".', fn{i});
    end
end

% Derive the synchronisation column: seconds since the session t0 anchor
% (set in main just before the first task; see config.sync). Callers never
% set this by hand -- raw GetSecs in, relative time out.
if isfield(config, 'sync') && ~isnan(d.eventOnsetGetSecs)
    d.eventOnsetRelative = d.eventOnsetGetSecs - config.sync.tZeroGetSecs;
end

% Coerce types so every column is homogeneous across records.
textFields = {'subjectID','sessionID','taskName','blockType','stimulus', ...
              'correctAnswer','participantResponse','eventName'};
numFields  = {'blockNumber','trialNumber','accuracy','reactionTime', ...
              'eventOnsetGetSecs','eventOnsetRelative','eventDuration','triggerCode'};
for i = 1:numel(textFields), d.(textFields{i}) = string(d.(textFields{i})); end
for i = 1:numel(numFields),  d.(numFields{i})  = double(d.(numFields{i})); end

if isempty(EXPLOG)
    EXPLOG = d;
else
    EXPLOG(end+1) = d;
end
end
