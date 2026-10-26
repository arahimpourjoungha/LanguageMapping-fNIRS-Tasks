function runSentenceCompletion(win, config)
% RUNSENTENCECOMPLETION  Task 4: Sentence Completion (block design).
%
% Active : fill-in-the-blank sentences; participant silently thinks of the
%          completing word.
% Control: length-matched nonsense sentences, half containing one real word;
%          RIGHT = contains a real word, LEFT = all nonsense
%          (config.t4.controlRequiresResponse).
% Active blocks also take a single un-scored keypress when the word comes to
% mind (config.t4.activeRequiresResponse), so the motor demand is matched.
%
% Each item shown for 5.0 s. 4 items/block = 20 s; 12 blocks separated by
% 10 s interleaved rest.

taskName = 'SentenceCompletion';
c = config.t4;

nAct = config.numActiveBlocks  * c.itemsPerBlock;   % 24
nCon = config.numControlBlocks * c.itemsPerBlock;   % 24

% ---- Active sentences ---------------------------------------------------
sent = config.t4.activeSentences;
assert(numel(sent) >= nAct, 'Need >= %d active sentences (have %d).', nAct, numel(sent));
sent = pickItems(sent, nAct, config, 'sentence');
active = struct('str', sent, 'correct', repmat({""}, 1, nAct));
activeBlocks = reshape(active, c.itemsPerBlock, config.numActiveBlocks);

% ---- Control nonsense sentences (generated, reproducible) --------------
% Passive viewing gave the pilot no way to tell attention from drift, so
% half of these now carry exactly one real English word among the nonsense
% and the participant judges which (RIGHT = contains a real word).
% makeNonsenseStrings runs its own RandStream, so it needs the seed passed
% explicitly -- use the per-subject one or every participant sees the same
% nonsense sentences even when everything else is counterbalanced.
if isfield(config,'effectiveSeed'), seedNS = config.effectiveSeed; else, seedNS = config.randomSeed; end
nonsense = makeNonsenseStrings(nCon, seedNS);
control = struct('str', nonsense, 'correct', repmat({""}, 1, nCon));

if c.controlRequiresResponse
    realWords = config.t4.realWordsForControl;
    withWord = false(1, nCon);
    withWord(randperm(nCon, floor(nCon/2))) = true;
    for i = 1:nCon
        if withWord(i)
            control(i).str = embedRealWord(control(i).str, ...
                                           realWords{randi(numel(realWords))});
            control(i).correct = "right";
        else
            control(i).correct = "left";
        end
    end
end
controlBlocks = reshape(control, c.itemsPerBlock, config.numControlBlocks);

% ---- Instructions -------------------------------------------------------
showMessageWaitKey(win, config, config.instr.sentence);

if config.includeRest
    logEvent(config, mkRec(taskName, 'rest', 0, 'restStart', GetSecs, config.restDuration));
    showTimedScreen(win, config, sprintf('Rest\n\nPlease relax and keep still.'), config.restDuration);
end

% ---- Block loop ---------------------------------------------------------
order = buildBlockOrder(config);
aIdx = 0; cIdx = 0;
for b = 1:numel(order)
    isActive = strcmp(order{b}, 'active');
    if isActive
        aIdx = aIdx + 1; items = activeBlocks(:, aIdx);
        blockType = 'active';
        trigBlock = c.trig.activeBlock;  trigTrial = c.trig.activeTrial;
    else
        cIdx = cIdx + 1; items = controlBlocks(:, cIdx);
        blockType = 'control';
        trigBlock = c.trig.controlBlock; trigTrial = c.trig.controlTrial;
    end

    nResponses = 0;   % compliance counter for this block
    tBlock = GetSecs;
    sendTrigger(trigBlock, config);
    logEvent(config, mkRec(taskName, blockType, b, 'blockStart', tBlock, config.blockDuration, ...
                           'triggerCode', trigBlock));

    for k = 1:c.itemsPerBlock
        it = items(k);
        stimOn = tBlock + (k-1) * c.stimDuration;
        waitUntilTime(config, stimOn);   % GetSecs-driven pacing (see note in runVerbGeneration)

        drawCenteredText(win, it.str, config, config.instrTextSize);
        tStim = Screen('Flip', win);
        sendTrigger(trigTrial, config);

        rec = mkRec(taskName, blockType, b, 'stimOnset', tStim, c.stimDuration, ...
                    'trialNumber', k, 'stimulus', string(it.str), ...
                    'triggerCode', trigTrial);

        % Real-word judgement on the nonsense control.
        if ~isActive && c.controlRequiresResponse
            resp = pollResponse(config, tStim, stimOn + c.stimDuration);
            rec.correctAnswer = it.correct;
            if resp.pressed
                rec.participantResponse = resp.key;
                rec.reactionTime = resp.rt;
                rec.accuracy = double(resp.key == it.correct);
                nResponses = nResponses + 1;
            end

        % Matched motor demand in active blocks: any arrow key once the
        % completing word comes to mind. Deliberately un-scored -- there is
        % no correct answer, so accuracy stays NaN and only the press counts.
        elseif isActive && c.activeRequiresResponse
            resp = pollResponse(config, tStim, stimOn + c.stimDuration);
            if resp.pressed
                rec.participantResponse = resp.key;
                rec.reactionTime = resp.rt;
                nResponses = nResponses + 1;
            end
        end
        logEvent(config, rec);

        waitUntilTime(config, stimOn + c.stimDuration);
    end

    % Hold to the shared block length if the items do not fill it exactly.
    waitUntilTime(config, tBlock + config.blockDuration);

    if (~isActive && c.controlRequiresResponse) || (isActive && c.activeRequiresResponse)
        reportResponseRate(config, taskName, blockType, b, nResponses, c.itemsPerBlock);
    end

    if b < numel(order)
        showInterBlockRest(win, config, taskName, b);
    end
end

if config.includeRest
    logEvent(config, mkRec(taskName, 'rest', numel(order)+1, 'restStart', GetSecs, config.restDuration));
    showTimedScreen(win, config, sprintf('Rest\n\nPlease relax and keep still.'), config.restDuration);
end

showBreak(win, config, taskName);
end

% =========================================================================
function s = embedRealWord(s, word)
% Replace one nonsense token with a real word, leaving the blank ('___')
% and the sentence length structure intact.
parts = strsplit(s, ' ');
candidates = find(~strcmp(parts, '___') & ~cellfun(@isempty, parts));
if isempty(candidates), return; end

pick = candidates(randi(numel(candidates)));
% Preserve the trailing full stop if we land on the last token.
if endsWith(parts{pick}, '.')
    parts{pick} = [word '.'];
else
    parts{pick} = word;
end
s = strjoin(parts, ' ');
end

function rec = mkRec(taskName, blockType, blockNumber, eventName, onset, dur, varargin)
% Small builder for a log record with the common fields prefilled.
rec = struct('taskName', string(taskName), 'blockType', string(blockType), ...
    'blockNumber', blockNumber, 'eventName', string(eventName), ...
    'eventOnsetGetSecs', onset, 'eventDuration', dur);
for i = 1:2:numel(varargin)
    rec.(varargin{i}) = varargin{i+1};
end
end
