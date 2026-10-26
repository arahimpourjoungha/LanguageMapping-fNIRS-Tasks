function DrawFormattedText(varargin)
% DRAWFORMATTEDTEXT  TEST STUB: records the last drawn string, draws nothing.
%
%   DrawFormattedText(win, str, ...)
global LM_PTB_STUB %#ok<GVMIS>
if isempty(LM_PTB_STUB), ptbStubControl('reset'); end
if numel(varargin) >= 2
    LM_PTB_STUB.lastText = varargin{2};
end
end
