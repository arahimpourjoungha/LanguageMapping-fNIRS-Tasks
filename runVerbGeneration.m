function runVerbGeneration(win, config)
% RUNVERBGENERATION  Task 1: Covert Verb Generation (block design).
%
% Active : nouns, one at a time; participant silently generates verbs.
% Control: matched symbol strings (####, ##%# ...) with an L/R same/different
%          judgement (config.t1.verbControlRequiresResponse).
%
% Timing per item: stimDuration + fixDuration (default 2.0 + 2.5 = 4.5 s).
% 4 items/block = 18 s, held to the 20 s block; 12 blocks separated by 10 s
% interleaved rest.

taskName = 'VerbGeneration';
c = config.t1;

% ---- Build stimulus lists (deterministic given config.randomSeed) -------
nAct = config.numActiveBlocks  * c.itemsPerBlock;   % 24 nouns
nCon = config.numControlBlocks * c.itemsPerBlock;   % 24 symbol strings

nouns = config.t1.nouns;
if numel(nouns) < nAct
    error('runVerbGeneration:tooFewNouns', ...
        'Need %d nouns but config.t1.nouns has %d.', nAct, numel(nouns));
end
nouns = pickItems(nouns, nAct, config, 'verbgen');   % session-aware draw
activeBlocks = reshape(nouns, c.itemsPerBlock, config.numActiveBlocks); % col = block

symSet  = config.t1.symbolStimuli;
symList = symSet(mod(0:nCon-1, numel(symSet)) + 1);   % cycle to fill the blocks
symList = symList(randperm(nCon));                    % shuffle

% Every entry in config.t1.symbolStimuli is four IDENTICAL characters, so a
% same/different judgement over them would have one answer for every trial.
% Corrupt a random half by one character to make the decision real.
if c.verbControlRequiresResponse
    corrupt = false(1, nCon);
    corrupt(randperm(nCon, floor(nCon/2))) = true;
    for i = find(corrupt)
        s = symList{i};
        pos = randi(numel(s));
        alt = setdiff(symSet, symList(i));            % a different symbol set
        replacement = alt{randi(numel(alt))};
        s(pos) = replacement(1);
        symList{i} = s;
    end
end
controlBlocks = reshape(symList, c.itemsPerBlock, config.numControlBlocks);

% ---- Instructions -------------------------------------------------------
showMessageWaitKey(win, config, config.instr.verb);

% ---- Optional pre-task rest --------------------------------------------
if config.includeRest
    logEvent(config, mkRec(taskName, 'rest', 0, 'restStart', GetSecs, config.restDuration));
    showTimedScreen(win, config, sprintf('Rest\n\nPlease relax and keep still.'), config.restDuration);
end

% ---- Block loop ---------------------------------------------------------
order = buildBlockOrder(config);
% Trials fill itemsPerBlock*(stim+fix); the block is held to at least
% config.blockDuration so all four tasks share one block length.
blockDur = max(c.itemsPerBlock * (c.stimDuration + c.fixDuration), config.blockDuration);
aIdx = 0; cIdx = 0;
for b = 1:numel(order)
    isActive = strcmp(order{b}, 'active');
    if isActive
        aIdx = aIdx + 1;
        items = activeBlocks(:, aIdx);
        blockType = 'active';
        trigBlock = c.trig.activeBlock;  trigTrial = c.trig.activeTrial;
    else
        cIdx = cIdx + 1;
        items = controlBlocks(:, cIdx);
        blockType = 'control';
        trigBlock = c.trig.controlBlock; trigTrial = c.trig.controlTrial;
    end

    % Block-start marker.
    nResponses = 0;   % compliance counter for this block
    tBlock = GetSecs;
    sendTrigger(trigBlock, config);
    logEvent(config, mkRec(taskName, blockType, b, 'blockStart', tBlock, blockDur, ...
                           'triggerCode', trigBlock));

    % Trials on an absolute time grid. Pacing is driven by GetSecs
    % (waitUntilTime), NOT by Screen('Flip','when'), so timing stays correct
    % even when the display backend cannot schedule flips precisely
    % (e.g. macOS Vulkan/desktop-compositor quirks).
    for k = 1:c.itemsPerBlock
        stimOn = tBlock + (k-1) * (c.stimDuration + c.fixDuration);
        waitUntilTime(config, stimOn);

        % --- Stimulus ---
        drawCenteredText(win, items{k}, config);
        tStim = Screen('Flip', win);
        sendTrigger(trigTrial, config);

        rec = mkRec(taskName, blockType, b, 'stimOnset', tStim, c.stimDuration, ...
                    'trialNumber', k, 'stimulus', string(items{k}), 'triggerCode', trigTrial);

        % Perceptual decision during control blocks (same/different).
        if ~isActive && config.t1.verbControlRequiresResponse
            % Correct answer: 'right' if all symbols identical, else 'left'.
            correct = allSameChars(items{k});   % "right"/"left"
            resp = pollResponse(config, tStim, stimOn + c.stimDuration);
            rec.correctAnswer = correct;
            if resp.pressed
                rec.participantResponse = resp.key;
                rec.reactionTime = resp.rt;
                rec.accuracy = double(resp.key == correct);
                nResponses = nResponses + 1;
            end

        % Optional matched motor demand in active blocks: press any arrow
        % once a verb comes to mind. No correct answer -- it exists to keep
        % the button press out of the active-control contrast, and to prove
        % the covert task was actually being done.
        elseif isActive && config.t1.verbActiveRequiresResponse
            resp = pollResponse(config, tStim, stimOn + c.stimDuration);
            if resp.pressed
                rec.participantResponse = resp.key;
                rec.reactionTime = resp.rt;
                nResponses = nResponses + 1;
            end
        end
        logEvent(config, rec);

        % --- Fixation (held until the next stimulus grid point) ---
        waitUntilTime(config, stimOn + c.stimDuration);
        drawFixation(win, config);
        Screen('Flip', win);
    end

    % Hold final fixation until the block boundary.
    waitUntilTime(config, tBlock + blockDur);

    % Live compliance readout for whichever blocks took responses.
    if (~isActive && config.t1.verbControlRequiresResponse) || ...
       ( isActive && config.t1.verbActiveRequiresResponse)
        reportResponseRate(config, taskName, blockType, b, nResponses, c.itemsPerBlock);
    end

    % Interleaved rest between blocks (not after the last one -- the
    % post-task rest follows there).
    if b < numel(order)
        showInterBlockRest(win, config, taskName, b);
    end
end

% ---- Optional post-task rest -------------------------------------------
if config.includeRest
    logEvent(config, mkRec(taskName, 'rest', numel(order)+1, 'restStart', GetSecs, config.restDuration));
    showTimedScreen(win, config, sprintf('Rest\n\nPlease relax and keep still.'), config.restDuration);
end

showBreak(win, config, taskName);
end

% =========================================================================
function ans_ = allSameChars(str)
% Return "right" if every character in str is identical, else "left".
if all(str == str(1))
    ans_ = "right";
else
    ans_ = "left";
end
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
