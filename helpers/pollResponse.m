function resp = pollResponse(config, tOnset, tDeadline)
% POLLRESPONSE  Wait for a Left/Right key press or until tDeadline.
%   resp = pollResponse(config, tOnset, tDeadline)
%
% Returns struct with fields:
%   .pressed  logical, true if Left/Right was pressed
%   .key      "left" | "right" | ""   (participant response)
%   .rt       reaction time in seconds (tPress - tOnset), NaN if none
%   .tPress   GetSecs timestamp of the press, NaN if none
%
% Escape aborts (error 'LMAP:abort').
resp = struct('pressed', false, 'key', "", 'rt', NaN, 'tPress', NaN);
while GetSecs < tDeadline
    [~, secs, keyCode] = KbCheck(-1);
    if keyCode(config.keys.escape)
        error('LMAP:abort', 'Experiment aborted by Escape key.');
    end
    if keyCode(config.keys.left)
        resp.pressed = true; resp.key = "left";
        resp.tPress = secs; resp.rt = secs - tOnset; return;
    elseif keyCode(config.keys.right)
        resp.pressed = true; resp.key = "right";
        resp.tPress = secs; resp.rt = secs - tOnset; return;
    end
    WaitSecs(0.001);
end
end
