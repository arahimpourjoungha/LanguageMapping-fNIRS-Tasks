function k = sessionIndexReport(config)
% SESSIONINDEXREPORT  The visit number pickItems will use, for logging.
% Mirrors the rule in pickItems: explicit config.sessionIndex wins, otherwise
% the trailing number of the Session ID ('pilot002' -> 2).
if isfield(config, 'sessionIndex') && ~isempty(config.sessionIndex)
    k = max(1, round(config.sessionIndex)); return
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
