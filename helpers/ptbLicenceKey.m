function key = ptbLicenceKey()
% PTBLICENCEKEY  Psychtoolbox licence key for automatic activation, or ''.
%
%   key = ptbLicenceKey()
%
% Psychtoolbox 3.0.19+ needs a paid licence on macOS and Windows. No key is
% shipped with this repository. The key is looked up, in order, from:
%
%   1. the environment variable PTB_LICENCE_KEY, e.g. before starting MATLAB
%        export PTB_LICENCE_KEY=XXXXX-XXXXX-...      (macOS / Linux)
%      or inside MATLAB:  setenv('PTB_LICENCE_KEY', 'XXXXX-XXXXX-...')
%   2. a local, git-ignored text file  helpers/ptb_licence_key.local.txt
%      holding only the key on its first line.
%
% If neither is present, '' is returned and a warning explains how to set
% one; addPsychtoolboxPath then reports that a licence is needed instead of
% trying to activate.
%
% ACTIVATION IS PER MACHINE + OPERATING SYSTEM. Each computer that runs the
% battery consumes one activation from the licence. Free one with
%   PsychLicenseHandling('Deactivate')
% on a machine that no longer needs it.
%
% Never commit a key to the repository. The local file name above is listed
% in .gitignore.

key = strtrim(getenv('PTB_LICENCE_KEY'));
if ~isempty(key)
    return
end

localFile = fullfile(fileparts(mfilename('fullpath')), 'ptb_licence_key.local.txt');
if exist(localFile, 'file')
    lines = strsplit(strtrim(fileread(localFile)), newline);
    key = strtrim(lines{1});
    if ~isempty(key)
        return
    end
end

key = '';
warning('ptbLicenceKey:missing', ...
    ['No Psychtoolbox licence key found. Set the environment variable ' ...
     'PTB_LICENCE_KEY, or put the key on the first line of\n  %s\n' ...
     '(that file is git-ignored). Without a key, automatic activation ' ...
     'is skipped.'], localFile);
end
