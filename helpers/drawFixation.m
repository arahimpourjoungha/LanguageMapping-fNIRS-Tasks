function drawFixation(win, config)
% DRAWFIXATION  Draw a central '+' fixation mark (does NOT flip).
Screen('TextSize', win, config.textSize);
Screen('TextFont', win, config.textFont);
DrawFormattedText(win, '+', 'center', 'center', config.fixationColor);
end
