function initExperimentLog()
% INITEXPERIMENTLOG  Reset the global event log used by logEvent/saveAll.
% The log is a global struct array so that partial data is recoverable even
% if the experiment aborts mid-task (Escape) or errors out.
global EXPLOG %#ok<GVMIS>
EXPLOG = [];
end
