function showMessageWaitKey(win, config, msg)
% SHOWMESSAGEWAITKEY  Display a message and wait for SPACE (Escape aborts).
drawCenteredText(win, msg, config, config.instrTextSize);
Screen('Flip', win);

% Wait for all keys to be released first (avoid an earlier press carrying over).
KbReleaseWait(-1);
while true
    [~, ~, keyCode] = KbCheck(-1);
    if keyCode(config.keys.escape)
        error('LMAP:abort', 'Experiment aborted by Escape key.');
    end
    if keyCode(config.keys.space)
        break;
    end
    WaitSecs(0.005);
end
KbReleaseWait(-1);
end
