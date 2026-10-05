function out=simulate_case(c,s,settings)
% Event-driven reference: same nodal circuit/relay integrator as Simulink.
% Network is stationary between fault, relay, breaker and transfer-trip events.
t=0; closed=ones(1,4); pv=true; commanded=false(1,4); progress=zeros(4,4);
openAt=inf(1,4); tripAt=nan(1,4); openedAt=nan(1,4); pvStopAt=inf;
history=[]; eventText={}; eventTime=[]; active=false; faultWasCleared=false;
clearingTime=NaN; wrongTrips=false; maxPV=0; maxKCL=0;
while t<=c.duration+1e-9
 active=s.faultEnabled && t>=c.faultOn-1e-9;
 n=network_solve(c,s,closed,pv,active);
 [~,forward,p,g,channels]=relay_characteristic(c,n,settings); operating=channels.*settings.tms;
 rates=1./operating; rates(commanded,:)=0;
 progress(~isfinite(operating) & repmat(~commanded.',1,4))=0;
 maxPV=max(maxPV,max(abs(n.pvI))); maxKCL=max(maxKCL,n.kclResidual);
 history(end+1,:)=[t p.' g.' max(progress,[],2).' closed double(pv) max(abs(n.faultI)) double(active) forward.'];
 if active && max(abs(n.faultI))<0.1 && ~faultWasCleared
  faultWasCleared=true; clearingTime=t;
 end
 % Nothing further will trip after clearing; retain a final settled sample.
 if faultWasCleared && all(rates==0,'all') && all(isinf(openAt)) && isinf(pvStopAt), break; end
 remaining=inf(4,4); eligible=rates>0;
 remaining(eligible)=max(0,1-progress(eligible))./rates(eligible);
 candidate=t+min(remaining,[],2).';
 nextFault=inf; if ~active && s.faultEnabled, nextFault=c.faultOn; end
 next=min([candidate openAt pvStopAt nextFault c.duration]);
 if next<=t+1e-10 && next>=c.duration-1e-9, break; end
 dt=max(0,next-t); progress=progress+rates*dt; t=next;
 for r=find(candidate<=t+1e-8)
  commanded(r)=true; tripAt(r)=t;
  eventText{end+1,1}=sprintf('R%d trip command',r); eventTime(end+1,1)=t;
  if ~ismember(r,s.failedBreaker), openAt(r)=t+c.breakerDelay;
  else, eventText{end+1,1}=sprintf('B%d fails to open',r); eventTime(end+1,1)=t; end
 end
 for r=find(openAt<=t+1e-8)
  closed(r)=0; openedAt(r)=t; openAt(r)=inf;
  eventText{end+1,1}=sprintf('B%d opens',r); eventTime(end+1,1)=t;
  if any(r==[1 2 3]) && pv && s.transferTrip
   pvStopAt=min(pvStopAt,t+c.transferDelay+c.pvBreakerDelay);
  end
 end
 if pvStopAt<=t+1e-8
  pv=false; pvStopAt=inf;
  eventText{end+1,1}='PV intertie opens after direct transfer trip'; eventTime(end+1,1)=t;
 end
 if t>=c.duration-1e-9, break; end
end
chain=relay_path(s.zone); primary=s.zone;
if ~s.faultEnabled
 selective=~any(commanded); expected=0;
else
 expected=primary;
 if ismember(primary,s.failedBreaker) && numel(chain)>1
  available=chain(~ismember(chain,s.failedBreaker));
  if ~isempty(available), expected=available(end); end
 end
 unrelated=setdiff(1:4,chain); wrongTrips=any(commanded(unrelated));
 expectedPath=chain(find(chain==expected,1):end);
 selective=faultWasCleared && ~wrongTrips && ~any(commanded(setdiff(1:4,expectedPath))) && closed(expected)==0;
 if all(s.failedBreaker==0), selective=selective && all(closed(setdiff(1:4,primary))==1); end
end
out=struct('history',history,'tripAt',tripAt,'openedAt',openedAt,'cleared',faultWasCleared,...
 'clearingTime',clearingTime,'selective',selective,'wrongTrips',wrongTrips,...
 'expectedBreaker',expected,'events',table(eventTime,eventText,'VariableNames',{'Time_s','Event'}),...
 'maxPVCurrentA',maxPV,'maxKCLResidualA',maxKCL);
end
