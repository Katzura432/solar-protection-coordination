function [margin,detected,times]=coordination_metrics(c,s,settings)
n=network_solve(c,s,ones(1,4),true,true);
unit=relay_characteristic(c,n,settings); times=unit.*settings.tms;
chain=relay_path(s.zone); primary=chain(end); detected=isfinite(times(primary));
margin=inf;
for k=1:numel(chain)-1
 if ~isfinite(times(chain(k))) || ~isfinite(times(chain(k+1))), margin=-inf;
 else, margin=min(margin,times(chain(k))-times(chain(k+1))-c.breakerDelay); end
end
end
