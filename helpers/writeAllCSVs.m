function writeAllCSVs(config)
% WRITEALLCSVS  Write one CSV per task from the global event log (EXPLOG).
% Safe to call multiple times (e.g. on normal end AND on abort). Does
% nothing if the log is empty.
global EXPLOG %#ok<GVMIS>
if isempty(EXPLOG), return; end

T = struct2table(EXPLOG);
tasks = unique(T.taskName, 'stable');
for i = 1:numel(tasks)
    tname = tasks(i);
    if strlength(tname) == 0, continue; end
    sub = T(T.taskName == tname, :);
    fname = fullfile(config.dataFolder, sprintf('%s_%s_%s_%s.csv', ...
        config.subjectID, config.sessionID, char(tname), config.startTimestamp));
    try
        writetable(sub, fname);
    catch ME
        warning('writeAllCSVs:fail', 'Could not write %s (%s).', fname, ME.message);
    end
end
end
