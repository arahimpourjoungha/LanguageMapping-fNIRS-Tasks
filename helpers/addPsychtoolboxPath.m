function ok = addPsychtoolboxPath(ptbDir)
% ADDPSYCHTOOLBOXPATH  Make sure Psychtoolbox is on the MATLAB path and runs.
%
%   ok = addPsychtoolboxPath()
%   ok = addPsychtoolboxPath(ptbDir)
%
% Psychtoolbox (PTB) is NOT shipped with this repository; install it from
% http://psychtoolbox.org/download. It is found, in order:
%
%   1. already on the MATLAB path (the normal case after DownloadPsychtoolbox
%      / SetupPsychtoolbox, or after a previous call);
%   2. the folder given as ptbDir;
%   3. the folder named by the environment variable PSYCHTOOLBOX_DIR, e.g.
%        setenv('PSYCHTOOLBOX_DIR', '<path to your Psychtoolbox folder>')
%
% Returns true if PTB is usable; otherwise throws an error that says why.
%
% genpath alone is NOT safe when adding a PTB folder. Psychtoolbox ships mex
% files for several language/platform combinations, and PsychBasic/Octave*/
% contains Octave builds of Screen, GetSecs and friends. Adding those lets an
% Octave binary shadow the MATLAB one and you get cryptic "invalid mex file"
% errors instead of a clean failure. The Octave folders and any hidden
% (.git/.svn) folders are therefore filtered out, which is the same rule
% Psychtoolbox's own setup applies.

if nargin < 1 || isempty(ptbDir)
    ptbDir = getenv('PSYCHTOOLBOX_DIR');
end

% Already on the path? Skip the addpath, but still run the runnability check
% below: a PTB that is present but unusable should fail here with a clear
% message, not much later inside PTB itself.
alreadyThere = ~isempty(which('KbName')) && ~isempty(which('GetSecs'));
if alreadyThere
    ok = local_verify(ptbDir);
    return
end

if isempty(ptbDir) || ~exist(ptbDir, 'dir')
    error('addPsychtoolboxPath:notFound', ...
        ['Psychtoolbox is not on the MATLAB path.\n' ...
         'Install it (http://psychtoolbox.org/download) and run SetupPsychtoolbox,\n' ...
         'or point the environment variable PSYCHTOOLBOX_DIR at an existing\n' ...
         'Psychtoolbox folder, e.g.  setenv(''PSYCHTOOLBOX_DIR'', ''<folder>'').']);
end

p = strsplit(genpath(ptbDir), pathsep);
p = p(~cellfun(@isempty, p));
drop = contains(p, [filesep 'Octave']) | ...          % Octave mex would shadow MATLAB's
       contains(p, [filesep '.']);                     % .git, .svn, .DS_Store dirs
addpath(strjoin(p(~drop), pathsep));

ok = ~isempty(which('KbName')) && ~isempty(which('GetSecs'));
if ~ok
    error('addPsychtoolboxPath:broken', ...
        ['Added %s to the path but KbName/GetSecs still do not resolve.\n' ...
         'That copy may lack mex files for this platform (%s).'], ptbDir, computer);
end
fprintf('Psychtoolbox: %s\n', ptbDir);
ok = local_verify(ptbDir);
end

% ------------------------------------------------------------------------
function ok = local_verify(ptbDir)
% LOCAL_VERIFY  Check that PTB can actually run, activating a licence if needed.
% Resolving on the path is not the same as being able to run: Screen.m and
% GetSecs.m are placeholder .m files that error out when the matching mex is
% missing or refuses. Calling one here turns that into a single clear message
% now, rather than a crash deep inside PsychDefaultSetup later.
try
    GetSecs;
    ok = true;
    return
catch err
    % fall through: try activation, then diagnose
end

% Not licensed yet on this machine? Try activating once with the configured
% key (see ptbLicenceKey) before giving up. Activation is per machine +
% operating system, so this runs once per computer and is a no-op later.
key = ptbLicenceKey();
if ~isempty(key) && ~isempty(which('PsychLicenseHandling'))
    fprintf('Psychtoolbox is not licensed on this machine. Activating...\n');
    try
        PsychLicenseHandling('Activate', key);
    catch actErr
        fprintf(2, 'Activation attempt failed: %s\n', actErr.message);
    end
    try
        clear GetSecs           % drop the cached placeholder before retrying
        GetSecs;
        fprintf('Psychtoolbox activated on this machine.\n');
        ok = true;
        return
    catch err
        % fall through to the diagnostics below
    end
end

% Distinguish the two ways this fails, because the fixes are different.
mexName = ['Screen.' mexext];
haveMex = ~isempty(which(mexName));
if ~haveMex && ~isempty(ptbDir)
    haveMex = ~isempty(dir(fullfile(ptbDir, 'PsychBasic', mexName)));
end

if ~haveMex
    error('addPsychtoolboxPath:wrongArchitecture', ...
        ['Psychtoolbox %s has no mex files for this MATLAB (%s -- it needs %s).\n\n' ...
         'Psychtoolbox releases old enough to be free predate Apple Silicon support,\n' ...
         'and the releases that support Apple Silicon need a paid licence.\n' ...
         'Run the battery on a machine with a working Psychtoolbox install.\n' ...
         'The headless test suite (tests/run_tests.m) needs no Psychtoolbox.'], ...
        local_ptbver(), computer('arch'), mexName);
else
    error('addPsychtoolboxPath:notLicensed', ...
        ['Psychtoolbox %s is installed for this architecture but will not run:\n' ...
         '    %s\n\n' ...
         'Since 3.0.19 it requires a paid licence on macOS and Windows.\n' ...
         'Automatic activation was skipped or did not succeed. Options:\n' ...
         '  * set PTB_LICENCE_KEY (see helpers/ptbLicenceKey.m) and retry\n' ...
         '  * activate manually:  PsychLicenseHandling(''Setup'')\n' ...
         '  * if the licence has no activations left, free one with\n' ...
         '    PsychLicenseHandling(''Deactivate'') on a machine you no longer need'], ...
        local_ptbver(), err.message);
end
end

function v = local_ptbver()
% LOCAL_PTBVER  Installed Psychtoolbox version as a short string.
try
    v = PsychtoolboxVersion;
    v = ['version ' strtrim(strtok(v, '-'))];
catch
    v = 'version unknown';
end
end
