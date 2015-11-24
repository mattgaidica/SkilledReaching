function idx = detectZeroCrossings(x)

zerotol = 1e-10;

test_sig = x .* circshift(x,1);

idx = find(test_sig < 0);   % find points where the signal changes sign

if diff(idx) == 1   % if identify adjacent points, this means it's really a tangent point
    idx = idx(1);
end

zero_idx = find(abs(x) < zerotol);

idx = [zero_idx;idx];
idx = unique(idx);
idx = sort(idx);