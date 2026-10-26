function out = KbName(arg)
% KBNAME  TEST STUB of the Psychtoolbox key-name map (small fixed key set).
%
%   code = KbName('LeftArrow')     name -> key code
%   name = KbName(code)            key code -> name
%   KbName('UnifyKeyNames')        no-op
names = {'LeftArrow','RightArrow','space','ESCAPE','Return','a','b','c'};
codes = [37 39 32 27 13 65 66 67];
if ischar(arg) || isstring(arg)
    if strcmpi(arg, 'UnifyKeyNames')
        if nargout > 0, out = []; end
        return
    end
    i = find(strcmpi(names, arg), 1);
    assert(~isempty(i), 'KbName stub: unknown key name "%s".', arg);
    out = codes(i);
else
    i = find(codes == arg(1), 1);
    if isempty(i), out = ''; else, out = names{i}; end
end
end
