function typed = typeWord(win, config, promptStr, deadline)
% TYPEWORD  Collect a short typed response, redrawing every frame.
%
%   typed = typeWord(win, config, promptStr, deadline)
%
% Replaces Psychtoolbox's GetEchoString, which had two problems here:
%   * it calls GetKbChar, which BLOCKS until a key is pressed and released,
%     so nothing redraws mid-keystroke -- typing felt laggy and there was no
%     caret to show the participant anything was being registered; and
%   * on timeout it returns an empty string, throwing away everything the
%     participant had already typed.
%
% This polls without blocking, redraws each frame with a caret, and on
% timeout returns whatever has been typed so far.
%
% Enter/Return finishes. Backspace deletes. Escape aborts the session, as
% everywhere else in the battery.

typed = '';
Screen('TextSize', win, config.instrTextSize);
Screen('TextFont', win, config.textFont);

prevKeys = false(1, 256);

while GetSecs < deadline
    % ---- draw ----
    caretOn = mod(floor((deadline - GetSecs) * 2), 2) == 0;   % ~2 Hz blink
    caret = ''; if caretOn, caret = '_'; end
    drawCenteredText(win, sprintf('%s\n\n%s%s', promptStr, typed, caret), ...
                     config, config.instrTextSize);
    Screen('Flip', win);

    % ---- poll ----
    [~, ~, keyCode] = KbCheck(-1);
    newKeys = find(keyCode & ~prevKeys);
    prevKeys = keyCode;
    if isempty(newKeys), continue, end

    name = KbName(newKeys(1));
    if iscell(name), name = name{1}; end

    switch lower(string(name))
        case {"escape"}
            error('LMAP:abort', 'Experiment aborted by Escape key.');
        case {"return", "enter", "kp_enter"}
            return
        case {"backspace", "delete"}
            if ~isempty(typed), typed(end) = []; end
        case "space"
            typed = [typed ' ']; %#ok<AGROW>
        otherwise
            % Single characters, plus names like '1!' where the first
            % character is the unshifted key.
            c = char(name);
            if ~isempty(c) && isstrprop(c(1), 'alphanum')
                typed = [typed lower(c(1))]; %#ok<AGROW>
            end
    end
end
end
