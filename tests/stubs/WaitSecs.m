function WaitSecs(s)
% WAITSECS  TEST STUB: advance the virtual clock by s seconds, return at once.
%
%   WaitSecs(s)
global LM_PTB_STUB %#ok<GVMIS>
if isempty(LM_PTB_STUB), ptbStubControl('reset'); end
LM_PTB_STUB.now = LM_PTB_STUB.now + s;
end
