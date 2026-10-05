function extra=verify_simulink_scenarios(root,c,schemes)
% Check saved-model behavior beyond the default demonstration.
scenarios=repmat(default_scenario(),6,1); selection=[3 1 3 3 3 3];
scenarios(1).failedBreaker=3;
scenarios(2).zone=4; scenarios(2).faultType='ABC'; scenarios(2).loadScale=0.25;
scenarios(3)=scenarios(2);
scenarios(4).faultEnabled=false; scenarios(4).loadScale=0.25;
scenarios(5).zone=1; scenarios(5).faultType='ABC';
scenarios(6).transferTrip=false;
rows=cell(6,7); name='solar_feeder_protection';
for j=1:6
 s=scenarios(j); settings=schemes{selection(j)};
 ref=simulate_case(c,s,settings);
 eventEnd=0; if ~isempty(ref.events), eventEnd=max(ref.events.Time_s); end
 stop=max(c.demoDuration,eventEnd+0.3);
 assignin('base','studyConfig',c); assignin('base','studyScenario',s); assignin('base','studySettings',settings);
 out=sim(name,'StopTime',num2str(stop,17));
 B=timeseries_matrix(out.breakerLog); L=timeseries_matrix(out.relayLog); t=out.breakerLog.Time;
 for r=1:4
  tr=find(L(:,1+(r-1)*5)>0.5,1); op=find(B(:,r)<0.5,1);
  if isnan(ref.tripAt(r)), assert(isempty(tr),'Unexpected relay trip in extra Simulink test');
  else, assert(~isempty(tr) && abs(t(tr)-ref.tripAt(r))<=2*c.dt+1e-8,'Extra Simulink relay timing mismatch'); end
  if isnan(ref.openedAt(r)), assert(isempty(op),'Unexpected breaker opening in extra Simulink test');
  else, assert(~isempty(op) && abs(t(op)-ref.openedAt(r))<=2*c.dt+1e-8,'Extra Simulink breaker timing mismatch'); end
 end
 last=timeseries_matrix(out.measurements); n=unpack_measurements(last(end,:));
 if s.faultEnabled, assert((max(abs(n.faultI))<0.1)==ref.cleared,'Extra Simulink fault-clearance mismatch'); end
 assert(all(isfinite(last),'all'),'Nonfinite measurements in extra model test');
 rows(j,:)={j,settings.name,s.zone,s.faultType,s.pvMW,s.failedBreaker,true};
 fprintf('PASS: additional saved-model scenario %d/6\n',j);
end
writetable(cell2table(rows,'VariableNames',{'TestID','Scheme','Zone','FaultType','Solar_MW','FailedBreaker','Passed'}),fullfile(root,'results','simulink_scenario_checks.csv'));
assignin('base','studyConfig',c); assignin('base','studyScenario',default_scenario()); assignin('base','studySettings',schemes{3});
extra='PASS: six additional saved-model scenarios cover breaker failure, conventional sympathetic trip, directional selectivity, no-fault export, source-zone isolation and disabled transfer trip.';
end
