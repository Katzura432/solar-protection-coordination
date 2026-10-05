function study=analyze_study(c,baseline,directional,improved,design)
schemes={baseline,directional,improved}; cases=design.cases; N=numel(cases);
rows=cell(N*3,12); cursor=0;
for j=1:N
 s=cases(j); chain=relay_path(s.zone);
 for q=1:3
  if q==1, K=design.nonDirectionalUnitTimes(j,:); elseif q==2, K=design.directionalUnitTimes(j,:); else, K=design.unitTimes(j,:); end
  times=K.*schemes{q}.tms.'; margin=inf;
  for k=1:numel(chain)-1
   if ~isfinite(times(chain(k))) || ~isfinite(times(chain(k+1))), margin=-inf;
   else, margin=min(margin,times(chain(k))-times(chain(k+1))-c.breakerDelay); end
  end
  cursor=cursor+1;
  rows(cursor,:)={j,schemes{q}.name,s.zone,s.faultType,s.location,s.Rf,s.pvMW,s.loadScale,s.sourceScale,times(s.zone),margin,isfinite(times(s.zone))};
 end
end
static=cell2table(rows,'VariableNames',{'CaseID','Scheme','Zone','FaultType','Location','FaultResistance_ohm','Solar_MW','LoadScale','SourceImpedanceScale','PrimaryTripDelay_s','CoordinationMargin_s','PrimaryDetected'});
rng(c.seed,'twister'); holdout=repmat(default_scenario(),c.validationCount,1);
for j=1:c.validationCount
 s=default_scenario(); s.zone=randi(4); s.faultType=c.faultTypes{randi(numel(c.faultTypes))};
 s.location=0.15+0.70*rand; s.Rf=0.2+9.6*rand; s.pvMW=4*rand;
 s.loadScale=0.35+0.80*rand; s.sourceScale=0.85+0.50*rand;
 s.unbalance=0.05*rand; s.irradiance=0.4+0.6*rand; holdout(j)=s;
end
indices=randperm(N,min(360,N)); selected=cases(indices);
dynamicCases=[selected;holdout]; partition=[repmat({'Design sample'},numel(selected),1);repmat({'Independent validation'},numel(holdout),1)];
mode=repmat({'Fault'},numel(dynamicCases),1);
for loadScale=[0.25 0.75 1.2]
 for pv=c.solarMW
  s=default_scenario(); s.faultEnabled=false; s.loadScale=loadScale; s.pvMW=pv; s.unbalance=0.05;
  dynamicCases(end+1,1)=s; partition{end+1,1}='Operating envelope'; mode{end+1,1}='No fault';
 end
end
for zone=2:4
 for type={'AG','ABC'}
  for pv=[0 4]
   s=default_scenario(); s.zone=zone; s.failedBreaker=zone; s.faultType=type{1}; s.pvMW=pv;
   dynamicCases(end+1,1)=s; partition{end+1,1}='Failure test'; mode{end+1,1}='Primary breaker fails';
  end
 end
end
for zone=1:3
 s=default_scenario(); s.zone=zone; s.pvMW=4; s.transferTrip=false;
 dynamicCases(end+1,1)=s; partition{end+1,1}='Failure test'; mode{end+1,1}='Transfer trip disabled';
end
M=numel(dynamicCases); rows=cell(M*3,19); cursor=0;
for j=1:M
 s=dynamicCases(j);
 for q=1:3
  out=simulate_case(c,s,schemes{q});
  if s.faultEnabled, [margin,detected]=coordination_metrics(c,s,schemes{q}); else, margin=NaN; detected=false; end
  cursor=cursor+1;
  rows(cursor,:)={j,partition{j},mode{j},schemes{q}.name,s.zone,s.faultType,s.pvMW,s.Rf,s.location,s.failedBreaker,...
   margin,detected,out.cleared,out.selective,out.wrongTrips,out.clearingTime-c.faultOn,...
   sum(isfinite(out.tripAt)),out.maxPVCurrentA,out.maxKCLResidualA};
 end
 if mod(j,75)==0, fprintf('  Simulated %d/%d dynamic scenarios (three schemes)\n',j,M); end
end
dynamic=cell2table(rows,'VariableNames',{'CaseID','Partition','Mode','Scheme','Zone','FaultType','Solar_MW','FaultResistance_ohm','Location','FailedBreaker','CoordinationMargin_s','PrimaryDetected','FaultCleared','Selective','UnrelatedRelayTrip','ClearingDelay_s','RelayTripCount','MaxPVCurrent_A','MaxKCLResidual_A'});
study=struct('static',static,'dynamic',dynamic,'dynamicCases',dynamicCases,'holdout',holdout,'schemes',{schemes},'designSampleIndices',indices);
end
