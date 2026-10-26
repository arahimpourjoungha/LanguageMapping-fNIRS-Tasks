function order = buildBlockOrder(config)
% BUILDBLOCKORDER  Alternating active/control block order.
%   order = buildBlockOrder(config)  -> 1xN cell of 'active'/'control'
% Counterbalanced by config.startWithActive.
nTotal = config.numActiveBlocks + config.numControlBlocks;
if config.startWithActive
    first = 'active'; second = 'control';
else
    first = 'control'; second = 'active';
end
order = cell(1, nTotal);
for i = 1:nTotal
    if mod(i, 2) == 1
        order{i} = first;
    else
        order{i} = second;
    end
end
end
