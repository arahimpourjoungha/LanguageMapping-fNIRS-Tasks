function [keyIsDown, secs, keyCode] = KbCheck(varargin)
% KBCHECK  TEST STUB: report the keys listed in the stub's heldKeys.
%
%   [keyIsDown, secs, keyCode] = KbCheck(deviceIndex)
%
% Advances the virtual clock by kbAdvance seconds per call (see
% ptbStubControl) so polling loops always make progress.
global LM_PTB_STUB %#ok<GVMIS>
if isempty(LM_PTB_STUB), ptbStubControl('reset'); end
LM_PTB_STUB.now = LM_PTB_STUB.now + LM_PTB_STUB.kbAdvance;
keyCode = false(1, 256);
keyCode(LM_PTB_STUB.heldKeys) = true;
keyIsDown = any(keyCode);
secs = LM_PTB_STUB.now;
end
