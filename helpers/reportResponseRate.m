function reportResponseRate(config, taskName, blockType, blockNumber, nResponses, nTrials)
% REPORTRESPONSERATE  Live compliance readout for a block that took responses.
%
%   reportResponseRate(config, taskName, blockType, blockNumber, nResponses, nTrials)
%
% Prints the block's response rate to the console so the experimenter can
% see disengagement WHILE the session is running, and logs a
% 'lowResponseRate' event when the rate falls below config.minResponseRate
% so it is also recoverable offline.
%
% Motivated by the pilot, where the participant stopped responding to the
% semantic control after two blocks and it only surfaced during analysis.

if nTrials <= 0, return; end
rate = nResponses / nTrials;

if isfield(config, 'minResponseRate')
    threshold = config.minResponseRate;
else
    threshold = 0.5;
end

if rate < threshold
    % Doubled up because a single line scrolls past unnoticed.
    fprintf(2, '\n*** LOW RESPONSE RATE  %s block %d (%s): %d/%d = %.0f%% ***\n', ...
        taskName, blockNumber, blockType, nResponses, nTrials, 100*rate);
    fprintf(2, '*** Check the participant is still engaged. ***\n\n');
    logEvent(config, struct( ...
        'taskName',          string(taskName), ...
        'blockType',         string(blockType), ...
        'blockNumber',       blockNumber, ...
        'eventName',         "lowResponseRate", ...
        'eventOnsetGetSecs', GetSecs, ...
        'accuracy',          rate));
else
    fprintf('[COMPLIANCE] %s block %d (%s): %d/%d responded (%.0f%%)\n', ...
        taskName, blockNumber, blockType, nResponses, nTrials, 100*rate);
end
end
