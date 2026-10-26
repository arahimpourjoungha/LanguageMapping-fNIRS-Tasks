function strs = makeNonsenseStrings(n, seed)
% MAKENONSENSESTRINGS  Deterministically generate pronounceable-looking
% nonsense sentences that contain a blank ('___'), matched roughly in length
% to real sentences. Used for the Sentence Completion control condition.
%
%   strs = makeNonsenseStrings(n, seed)  -> 1xn cell of char rows
%
% Uses its own RNG stream so it does not disturb the global rng state.
rs = RandStream('twister', 'Seed', seed);
cons = 'bcdfghjklmnpqrstvwxz';
vow  = 'aeiou';

strs = cell(1, n);
for k = 1:n
    nWords = 3 + randi(rs, 2);          % 4-5 tokens plus the blank
    blankPos = 2 + randi(rs, nWords-2); % blank somewhere in the middle
    words = cell(1, nWords);
    for w = 1:nWords
        if w == blankPos
            words{w} = '___';
        else
            words{w} = randWord(rs, cons, vow);
        end
    end
    s = strjoin(words, ' ');
    strs{k} = [s '.'];
end
end

function w = randWord(rs, cons, vow)
% 2-3 consonant-vowel syllables -> a short nonsense word.
nSyl = 1 + randi(rs, 2);
w = '';
for s = 1:nSyl
    w = [w cons(randi(rs, numel(cons))) vow(randi(rs, numel(vow)))]; %#ok<AGROW>
    if rand(rs) < 0.35   % occasional closing consonant
        w = [w cons(randi(rs, numel(cons)))]; %#ok<AGROW>
    end
end
end
