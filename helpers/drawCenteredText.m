function drawCenteredText(win, str, config, sizeOverride)
% DRAWCENTEREDTEXT  Draw wrapped, centred text (does NOT flip).
%   drawCenteredText(win, str, config)               % uses config.textSize
%   drawCenteredText(win, str, config, sizeOverride)  % custom size (px)
if nargin >= 4 && ~isempty(sizeOverride)
    Screen('TextSize', win, sizeOverride);
else
    Screen('TextSize', win, config.textSize);
end
Screen('TextFont', win, config.textFont);
DrawFormattedText(win, str, 'center', 'center', config.textColor, ...
    config.textWrap, [], [], 1.4);
end
