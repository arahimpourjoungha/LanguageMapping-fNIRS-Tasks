function waitUntilTime(config, tEnd)
% WAITUNTILTIME  Busy-wait until GetSecs >= tEnd, watching for Escape.
% Throws error 'LMAP:abort' if the Escape key is pressed so the caller's
% try/catch can save partial data and close the screen cleanly.
while GetSecs < tEnd
    [~, ~, keyCode] = KbCheck(-1);
    if keyCode(config.keys.escape)
        error('LMAP:abort', 'Experiment aborted by Escape key.');
    end
    WaitSecs(0.005);
end
end
