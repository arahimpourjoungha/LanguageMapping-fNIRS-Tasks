function showInterBlockRest(win, config, taskName, blockNumber)
% SHOWINTERBLOCKREST  Rest period between two task blocks.
%
%   showInterBlockRest(win, config, taskName, blockNumber)
%
% blockNumber is the block that just ENDED, so the logged record sits
% between block N and block N+1.
%
% Does nothing unless config.interleaveRest is true and
% config.interRestDuration > 0, so the old back-to-back design is one
% config flag away.
%
% The rest is logged as eventName 'interRest' with blockType 'rest' and
% carries its own trigger (config.trigger.interRest), which means the
% baseline periods can be modelled explicitly rather than being whatever
% is left over between blocks.

if ~isfield(config, 'interleaveRest') || ~config.interleaveRest, return; end
if config.interRestDuration <= 0, return; end

tRest = GetSecs;
sendTrigger(config.trigger.interRest, config);
logEvent(config, struct( ...
    'taskName',          string(taskName), ...
    'blockType',         "rest", ...
    'blockNumber',       blockNumber, ...
    'eventName',         "interRest", ...
    'eventOnsetGetSecs', tRest, ...
    'eventDuration',     config.interRestDuration, ...
    'triggerCode',       config.trigger.interRest));

showTimedScreen(win, config, sprintf('Rest\n\nPlease relax and keep still.'), ...
                config.interRestDuration);
end
