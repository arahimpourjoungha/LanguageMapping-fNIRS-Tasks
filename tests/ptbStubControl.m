function out = ptbStubControl(action, varargin)
% PTBSTUBCONTROL  Configure the headless Psychtoolbox stubs in tests/stubs.
%
%   ptbStubControl('reset')                 clock to 0, hold SPACE, defaults
%   ptbStubControl('hold', codes)           key codes KbCheck reports as down
%   s = ptbStubControl('state')             current stub state struct
%
% The stubs (GetSecs, WaitSecs, KbCheck, KbName, KbReleaseWait, Screen,
% DrawFormattedText) share one virtual clock. Holding SPACE lets every
% "press SPACE to continue" screen pass at once and skips the end-of-task
% break; arrow keys are never reported unless asked for, so no responses
% are recorded by default.
global LM_PTB_STUB %#ok<GVMIS>
switch lower(action)
    case 'reset'
        LM_PTB_STUB = struct('now', 1000, 'frame', 1/60, 'kbAdvance', 0, ...
            'heldKeys', 32, 'nFlips', 0, 'lastText', '');
    case 'hold'
        LM_PTB_STUB.heldKeys = varargin{1};
    case 'state'
    otherwise
        error('ptbStubControl:action', 'Unknown action "%s".', action);
end
if nargout > 0, out = LM_PTB_STUB; end
end
