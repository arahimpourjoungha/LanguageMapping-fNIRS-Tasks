function items = pickItems(pool, nNeeded, config, salt)
% PICKITEMS  Draw a session's stimuli so repeat sessions do not reuse items.
%
%   items = pickItems(pool, nNeeded, config, salt)
%
% THE PROBLEM: shuffling the pool and taking the first nNeeded gives a fresh
% random subset each session, but random subsets overlap heavily. With 55
% sentences and 24 needed, two sessions share about 10 items on average --
% enough for real carry-over on a task that depends on novelty.
%
% THE FIX: order the pool once per SUBJECT (stable across their sessions),
% then hand session k the k-th non-overlapping slice of that order. Session 1
% and session 2 then share nothing at all, and the pool only starts repeating
% once floor(numel(pool)/nNeeded) sessions have been run.
%
% salt is a short string naming the task, so the four tasks get independent
% orderings rather than all being permuted the same way.
%
% Requires config.subjectID and either config.sessionIndex or a Session ID
% ending in a number (see sessionIndexOf below).

if nargin < 4, salt = ''; end
n = numel(pool);
assert(n >= nNeeded, 'pickItems: pool has %d items, need %d.', n, nNeeded);

k = sessionIndexOf(config);

% Subject-derived, session-independent ordering.
rs  = RandStream('twister', 'Seed', subjectSeed(0, config.subjectID, salt));
ord = randperm(rs, n);

start = mod((k-1) * nNeeded, n);
sel   = ord(mod(start + (0:nNeeded-1), n) + 1);
items = pool(sel);

if nNeeded * k > n
    warning('pickItems:wrapped', ...
        ['Session %d of task "%s" has wrapped around the %d-item pool, so some ' ...
         'items repeat from an earlier session. Add more items to avoid this.'], ...
        k, salt, n);
end
end

% ------------------------------------------------------------------------
function k = sessionIndexOf(config)
% Explicit setting wins; otherwise take the trailing number of the Session ID
% typed in the startup dialog, so 'pilot001' -> 1 and 'pilot002' -> 2.
if isfield(config, 'sessionIndex') && ~isempty(config.sessionIndex)
    k = max(1, round(config.sessionIndex));
    return
end
k = 1;
if isfield(config, 'sessionID')
    tok = regexp(char(string(config.sessionID)), '(\d+)\s*$', 'tokens', 'once');
    if ~isempty(tok)
        v = str2double(tok{1});
        if isfinite(v) && v >= 1, k = round(v); end
    end
end
end
