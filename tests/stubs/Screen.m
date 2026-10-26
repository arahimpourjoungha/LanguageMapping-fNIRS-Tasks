function varargout = Screen(cmd, varargin)
% SCREEN  TEST STUB of Psychtoolbox Screen: no window, virtual clock only.
%
%   t = Screen('Flip', win)     advances the virtual clock by one frame
%   n = Screen('Screens')       returns 0
%   Screen(<anything else>)     no-op
global LM_PTB_STUB %#ok<GVMIS>
if isempty(LM_PTB_STUB), ptbStubControl('reset'); end
switch lower(cmd)
    case 'flip'
        LM_PTB_STUB.now = LM_PTB_STUB.now + LM_PTB_STUB.frame;
        LM_PTB_STUB.nFlips = LM_PTB_STUB.nFlips + 1;
        varargout = {LM_PTB_STUB.now};
    case 'screens'
        varargout = {0};
    case 'openwindow'
        varargout = {10, [0 0 1024 768]};
    otherwise
        varargout = cell(1, nargout);
end
end
