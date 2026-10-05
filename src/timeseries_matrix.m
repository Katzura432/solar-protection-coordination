function m=timeseries_matrix(ts)
m=squeeze(ts.Data);
if size(m,1)~=numel(ts.Time), m=m.'; end
assert(size(m,1)==numel(ts.Time),'Unexpected timeseries dimensions');
end
