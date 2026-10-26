function showTimedScreen(win, config, msg, duration, allowSkip)
% SHOWTIMEDSCREEN  Display a message for a fixed duration.
%   showTimedScreen(win, config, msg, duration)            % passive, no skip
%   showTimedScreen(win, config, msg, duration, allowSkip)  % SPACE skips if true
% Escape aborts (error 'LMAP:abort').
if nargin < 5, allowSkip = false; end
drawCenteredText(win, msg, config, config.instrTextSize);
Screen('Flip', win);
tEnd = GetSecs + duration;
while GetSecs < tEnd
    [~, ~, keyCode] = KbCheck(-1);
    if keyCode(config.keys.escape)
        error('LMAP:abort', 'Experiment aborted by Escape key.');
    end
    if allowSkip && keyCode(config.keys.space)
        break;
    end
    WaitSecs(0.005);
end
end
