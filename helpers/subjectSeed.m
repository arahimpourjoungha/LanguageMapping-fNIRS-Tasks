function s = subjectSeed(base, subjectID, sessionID)
% SUBJECTSEED  Deterministic per-participant RNG seed.
%
%   s = subjectSeed(base, subjectID, sessionID)
%
% A single fixed seed makes every participant see the identical shuffle:
% the same letter in block 1, the same 24 of 30 sentences, the same 6 always
% dropped. Any order effect is then perfectly confounded with item identity
% across the whole study, which cannot be unpicked at group level.
%
% Deriving the seed from the participant's own IDs counterbalances across
% people while staying exactly reproducible for any one of them -- re-run
% the same subject and session and you get the same sequence back.
%
% djb2, reduced modulo 2^31-1 at every step so it stays inside the exact
% integer range of a double (no overflow, no toolbox needed).

str = [char(string(subjectID)) '|' char(string(sessionID))];
h = 5381;
for i = 1:numel(str)
    h = mod(h * 33 + double(str(i)), 2147483647);
end
s = mod(h + double(base), 2147483647);
if s == 0, s = 1; end
end
