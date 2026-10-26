function runPhonemicFluency(win, config)
% RUNPHONEMICFLUENCY  Task 3: Phonemic / Letter Fluency (block design).
%
% Active : one cue LETTER shown for the whole block; participant silently
%          generates words beginning with that letter.
% Control: silent counting / repetition. The prompt is shown for a brief
%          lead-in (config.t3.promptLeadIn) and the block body is then a
%          single large glyph, so the sustained visual input matches the
%          active block instead of being a paragraph of text to read.
%
% 1 cue per block x 12 blocks x 20 s, separated by 10 s interleaved rest.
% 5 s post-active-block compliance check (config.t3.fluencyPostBlockCheck),
% which runs AFTER the block so it never perturbs block timing.

taskName = 'PhonemicFluency';
c = config.t3;

letters = config.t3.letters;          % one per active block
prompts = config.t3.controlPrompts;   % one per control block
assert(numel(letters) >= config.numActiveBlocks,  'Need >= %d cue letters.',  config.numActiveBlocks);
assert(numel(prompts) >= config.numControlBlocks, 'Need >= %d control prompts.', config.numControlBlocks);

% Shuffle assignment deterministically.
letters = pickItems(letters, config.numActiveBlocks,  config, 'fluency');
prompts = pickItems(prompts, config.numControlBlocks, config, 'fluencyctl');

% ---- Instructions -------------------------------------------------------
showMessageWaitKey(win, config, config.instr.fluency);

if config.includeRest
    logEvent(config, mkRec(taskName, 'rest', 0, 'restStart', GetSecs, config.restDuration));
    showTimedScreen(win, config, sprintf('Rest\n\nPlease relax and keep still.'), config.restDuration);
end

% ---- Block loop ---------------------------------------------------------
order = buildBlockOrder(config);
aIdx = 0; cIdx = 0;
for b = 1:numel(order)
    isActive = strcmp(order{b}, 'active');
    tBlock = GetSecs;

    if isActive
        aIdx = aIdx + 1;
        cue = letters{aIdx};
        blockType = 'active';
        sendTrigger(c.trig.activeBlock, config);
        logEvent(config, mkRec(taskName, blockType, b, 'blockStart', tBlock, config.blockDuration, ...
                               'triggerCode', c.trig.activeBlock));

        % Show a big cue letter for the whole block.
        drawCenteredText(win, cue, config, round(config.textSize*2.5));
        tCue = Screen('Flip', win);
        sendTrigger(c.trig.activeCue, config);
        logEvent(config, mkRec(taskName, blockType, b, 'cueOnset', tCue, config.blockDuration, ...
                               'trialNumber', 1, 'stimulus', string(cue), ...
                               'triggerCode', c.trig.activeCue));

        waitUntilTime(config, tBlock + config.blockDuration);

        % Optional compliance check (kept OFF by default for clean timing).
        if config.t3.fluencyPostBlockCheck
            doPostBlockCheck(win, config, taskName, b);
        end
    else
        cIdx = cIdx + 1;
        prompt = prompts{cIdx};
        blockType = 'control';
        sendTrigger(c.trig.controlBlock, config);
        logEvent(config, mkRec(taskName, blockType, b, 'blockStart', tBlock, config.blockDuration, ...
                               'triggerCode', c.trig.controlBlock));

        drawCenteredText(win, prompt, config, config.instrTextSize);
        tCue = Screen('Flip', win);
        sendTrigger(c.trig.controlCue, config);
        logEvent(config, mkRec(taskName, blockType, b, 'cueOnset', tCue, config.blockDuration, ...
                               'trialNumber', 1, 'stimulus', string(strrep(prompt, newline, ' ')), ...
                               'triggerCode', c.trig.controlCue));

        % Swap the instruction for a large glyph so the rest of the block is
        % visually matched to the active cue letter. The participant keeps
        % doing the counting/repetition task from memory.
        lead = min(c.promptLeadIn, config.blockDuration);
        waitUntilTime(config, tBlock + lead);
        drawCenteredText(win, c.controlGlyph, config, round(config.textSize*2.5));
        Screen('Flip', win);

        waitUntilTime(config, tBlock + config.blockDuration);
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
function doPostBlockCheck(win, config, taskName, b)
% "Type one word you generated" screen -- the only evidence that a covert
% block was actually performed.
%
% Uses helpers/typeWord rather than Psychtoolbox's GetEchoString: the latter
% blocks on each keystroke (laggy, no caret) and discards the whole string on
% timeout. typeWord redraws every frame and keeps whatever was typed when the
% deadline arrives, so a slow typist still leaves evidence of compliance.
tCheck = GetSecs;
deadline = tCheck + config.t3.postBlockCheckDuration;
typed = typeWord(win, config, 'Type ONE word you generated, then press Enter:', deadline);
% Clear before moving on: without this, whatever is drawn next (the Rest
% screen) appears on top of the typing prompt and both are visible at once.
Screen('FillRect', win, config.backgroundColor);
Screen('Flip', win);

logEvent(config, struct('taskName', string(taskName), 'blockType', "active", ...
    'blockNumber', b, 'eventName', "postBlockCheck", 'eventOnsetGetSecs', tCheck, ...
    'eventDuration', config.t3.postBlockCheckDuration, ...
    'participantResponse', string(typed)));

% Compliance: 1 word expected per active block, 0 if the deadline passed.
reportResponseRate(config, taskName, 'active', b, double(~isempty(typed)), 1);
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
