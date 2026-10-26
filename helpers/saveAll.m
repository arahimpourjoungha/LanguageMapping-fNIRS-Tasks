function saveAll(config)
% SAVEALL  Persist everything: per-task CSVs + one combined .mat file.
% Called at the normal end of the experiment and again from the abort/error
% handler so partial data is never lost.
global EXPLOG %#ok<GVMIS>

if ~exist(config.dataFolder, 'dir')
    mkdir(config.dataFolder);
end

% Per-task CSVs.
writeAllCSVs(config);

% Participant demographics: one row per session, so a cohort table is just
% a concatenation of these files across subjects.
if isfield(config, 'demographics')
    subjFile = fullfile(config.dataFolder, sprintf('%s_%s_subject_%s.csv', ...
        config.subjectID, config.sessionID, config.startTimestamp));
    d = config.demographics;
    try
        fid = fopen(subjFile, 'w');
        if fid > 0
            fprintf(fid, ['subjectID,sessionID,age,sex,handedness,' ...
                          'handednessScore,languageHistory,sessionDate\n']);
            fprintf(fid, '%s,%s,%s,%s,%s,%s,"%s",%s\n', ...
                config.subjectID, config.sessionID, ...
                num2str(d.age), d.sex, d.handedness, num2str(d.handScore), ...
                strrep(d.language, '"', ''''), config.startTimestamp);
            fclose(fid);
            fprintf('Saved subject info: %s\n', subjFile);
        end
    catch ME
        warning('saveAll:subject', 'Could not write subject file (%s).', ME.message);
    end
end

% Sync anchor: the one file that makes the timestamps meaningful offline.
% Absent if the run aborted before the anchor was taken.
if isfield(config, 'sync')
    syncFile = fullfile(config.dataFolder, sprintf('%s_%s_sync_%s.txt', ...
        config.subjectID, config.sessionID, config.startTimestamp));
    try
        fid = fopen(syncFile, 'w');
        if fid > 0
            fprintf(fid, '# Synchronisation anchor for %s / %s\n', ...
                config.subjectID, config.sessionID);
            fprintf(fid, '# absolute_time = tZeroPosix + eventOnsetRelative\n');
            fprintf(fid, 'tZeroClock\t%s\n',   config.sync.tZeroClock);
            fprintf(fid, 'timeZone\t%s\n',     config.sync.timeZone);
            fprintf(fid, 'tZeroPosix\t%.6f\n', config.sync.tZeroPosix);
            fprintf(fid, 'tZeroGetSecs\t%.6f\n', config.sync.tZeroGetSecs);
            fprintf(fid, 'sessionStartTrigger\t%d\n', config.trigger.sessionStart);
            fclose(fid);
            fprintf('Saved sync anchor: %s\n', syncFile);
        end
    catch ME
        warning('saveAll:sync', 'Could not write sync file (%s).', ME.message);
    end
end

% Combined .mat (raw struct array + table + config).
matFile = fullfile(config.dataFolder, sprintf('%s_%s_combined_%s.mat', ...
    config.subjectID, config.sessionID, config.startTimestamp));
events = EXPLOG;
if ~isempty(EXPLOG)
    eventsTable = struct2table(EXPLOG);
else
    eventsTable = table();
end
try
    save(matFile, 'events', 'eventsTable', 'config');
    fprintf('Saved combined data: %s\n', matFile);
catch ME
    warning('saveAll:mat', 'Could not save combined .mat (%s).', ME.message);
end
end
