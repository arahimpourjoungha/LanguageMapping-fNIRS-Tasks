function runSemanticRelatedness(win, config)
% RUNSEMANTICRELATEDNESS  Task 2: Semantic Relatedness Decision (block design).
%
% Active : word pairs; RIGHT = related, LEFT = unrelated.
% Control: symbol-string pairs; RIGHT = same, LEFT = different.
%
% Each trial is a fixed 3.0 s: stimulus up to 2.5 s or until response, then
% fixation fills the remainder. 6 trials/block = 18 s, held to the 20 s
% block; 12 blocks separated by 10 s interleaved rest.

taskName = 'SemanticRelatedness';
c = config.t2;

nActTrials = config.numActiveBlocks  * c.trialsPerBlock;   % 36
nConTrials = config.numControlBlocks * c.trialsPerBlock;   % 36

% ---- Build ACTIVE trials (balanced related / unrelated) ----------------
rel = config.t2.relatedPairs;      % Nx2 cell
unr = config.t2.unrelatedPairs;    % Nx2 cell
nEach = nActTrials/2;              % 18 related + 18 unrelated
assert(size(rel,1) >= nEach && size(unr,1) >= nEach, ...
    'Need >= %d related and unrelated pairs.', nEach);

% Which pairs this session gets. Previously this took the FIRST nEach rows of
% each list, so every session -- and every participant -- saw identical items.
iRel = pickItems((1:size(rel,1))', nEach, config, 'semrel');
iUnr = pickItems((1:size(unr,1))', nEach, config, 'semunr');

active = struct('w1', {}, 'w2', {}, 'correct', {});
for i = iRel(:)'
    active(end+1) = struct('w1', rel{i,1}, 'w2', rel{i,2}, 'correct', "right"); %#ok<AGROW>
end
for i = iUnr(:)'
    active(end+1) = struct('w1', unr{i,1}, 'w2', unr{i,2}, 'correct', "left"); %#ok<AGROW>
end
active = active(randperm(numel(active)));   % trial order within the session
activeBlocks = reshape(active, c.trialsPerBlock, config.numActiveBlocks);

% ---- Build CONTROL trials (balanced same / different) ------------------
control = struct('w1', {}, 'w2', {}, 'correct', {});
syms = config.t2.controlSymbols;   % single-character symbols, e.g. {'%','#',...}
for i = 1:(nConTrials/2)   % SAME pairs: a 4-char string vs. an identical copy
    s = repmat(syms{randi(numel(syms))}, 1, 4);
    control(end+1) = struct('w1', s, 'w2', s, 'correct', "right"); %#ok<AGROW>
end
for i = 1:(nConTrials/2)   % DIFFERENT pairs: change exactly one character
    baseIdx = randi(numel(syms));
    s  = repmat(syms{baseIdx}, 1, 4);
    s2 = s;
    pos = randi(4);
    otherIdx = setdiff(1:numel(syms), baseIdx);   % any symbol != base
    if isempty(otherIdx)
        s2(pos) = '?';                            % fallback if only one symbol
    else
        repl = syms{otherIdx(randi(numel(otherIdx)))};
        s2(pos) = repl(1);
    end
    control(end+1) = struct('w1', s, 'w2', s2, 'correct', "left"); %#ok<AGROW>
end
control = control(randperm(numel(control)));
controlBlocks = reshape(control, c.trialsPerBlock, config.numControlBlocks);

% ---- Instructions -------------------------------------------------------
showMessageWaitKey(win, config, config.instr.semantic);

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
        aIdx = aIdx + 1; trials = activeBlocks(:, aIdx);
        blockType = 'active';
        trigBlock = c.trig.activeBlock;  trigTrial = c.trig.activeTrial;
    else
        cIdx = cIdx + 1; trials = controlBlocks(:, cIdx);
        blockType = 'control';
        trigBlock = c.trig.controlBlock; trigTrial = c.trig.controlTrial;
    end

    nResponses = 0;   % compliance counter for this block
    tBlock = GetSecs;
    sendTrigger(trigBlock, config);
    logEvent(config, mkRec(taskName, blockType, b, 'blockStart', tBlock, config.blockDuration, ...
                           'triggerCode', trigBlock));

    for k = 1:c.trialsPerBlock
        tr = trials(k);
        stimOn = tBlock + (k-1) * c.trialDuration;
        waitUntilTime(config, stimOn);   % GetSecs-driven pacing (see note in runVerbGeneration)
        stimStr = sprintf('%s     %s', tr.w1, tr.w2);

        drawCenteredText(win, stimStr, config);
        tStim = Screen('Flip', win);
        sendTrigger(trigTrial, config);

        % Response window (up to stimMaxDur after onset).
        resp = pollResponse(config, tStim, stimOn + c.stimMaxDur);

        rec = mkRec(taskName, blockType, b, 'stimOnset', tStim, c.trialDuration, ...
                    'trialNumber', k, 'stimulus', string(stimStr), ...
                    'correctAnswer', tr.correct, 'triggerCode', trigTrial);
        if resp.pressed
            rec.participantResponse = resp.key;
            rec.reactionTime = resp.rt;
            rec.accuracy = double(resp.key == tr.correct);
            sendTrigger(c.trig.response, config);
            nResponses = nResponses + 1;
        end
        logEvent(config, rec);

        % Fixation fills the rest of the fixed trial.
        drawFixation(win, config);
        Screen('Flip', win);
        waitUntilTime(config, stimOn + c.trialDuration);
    end

    % Hold the final fixation out to the shared block length (trials fill
    % trialsPerBlock*trialDuration, which may be shorter).
    waitUntilTime(config, tBlock + config.blockDuration);

    % Live compliance readout -- this is the block where the pilot silently
    % stopped responding.
    reportResponseRate(config, taskName, blockType, b, nResponses, c.trialsPerBlock);

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
function rec = mkRec(taskName, blockType, blockNumber, eventName, onset, dur, varargin)
% Small builder for a log record with the common fields prefilled.
rec = struct('taskName', string(taskName), 'blockType', string(blockType), ...
    'blockNumber', blockNumber, 'eventName', string(eventName), ...
    'eventOnsetGetSecs', onset, 'eventDuration', dur);
for i = 1:2:numel(varargin)
    rec.(varargin{i}) = varargin{i+1};
end
end
