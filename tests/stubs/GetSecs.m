function t = GetSecs()
% GETSECS  TEST STUB of the Psychtoolbox clock: returns the virtual clock.
%
%   t = GetSecs()
%
% Only on the path while the headless tests run (see tests/ptbStubControl.m).
% Time advances only through WaitSecs, KbCheck and Screen('Flip') stubs.
global LM_PTB_STUB %#ok<GVMIS>
if isempty(LM_PTB_STUB), ptbStubControl('reset'); end
t = LM_PTB_STUB.now;
end
