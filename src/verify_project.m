function checks=verify_project(c,design,study,out,reference,root)
checks={}; s=default_scenario(); s.pvMW=0; s.loadScale=0; s.unbalance=0;
% Independent sequence-network fault formulas, without loads or PV.
s.zone=3; s.location=0.5; s.faultType='ABC'; s.Rf=2;
n=network_solve(c,s,ones(1,4),false,true);
z1=c.sourceZ1+sum(c.lineZ1(1:2))+s.location*c.lineZ1(3);
z0=c.sourceZ0+sum(c.lineZ0(1:2))+s.location*c.lineZ0(3);
expected=c.Vph/(z1+s.Rf);
assert(abs(n.faultI(1)-expected)/abs(expected)<1e-6,'Balanced fault formula disagreement');
checks{end+1}='PASS: balanced fault current agrees with independent Thevenin calculation (<1e-6 relative error).';
s.faultType='AG'; n=network_solve(c,s,ones(1,4),false,true);
expected=3*c.Vph/(2*z1+z0+3*s.Rf);
assert(abs(n.faultI(1)-expected)/abs(expected)<1e-6,'Ground-fault sequence formula disagreement');
checks{end+1}='PASS: AG fault agrees with independent sequence-network calculation (<1e-6 relative error).';
assert(abs(inverse_time(1000,100,0.1)-0.297059862418)<1e-9,'IEC curve checkpoint failed');
assert(isinf(inverse_time(90,100,0.1)),'Below-pickup relay should not operate');
checks{end+1}='PASS: IEC normal-inverse numerical checkpoint and below-pickup behavior.';
assert(design.maxKCLResidual<1e-6 && design.maxPVLimitError<1e-5,'Circuit residual or PV current-limit violation');
checks{end+1}='PASS: nodal KCL and 1.20 pu inverter current limit across all design cases.';
idx=strcmp(study.static.Scheme,study.schemes{3}.name);
assert(all(study.static.PrimaryDetected(idx)) && all(study.static.CoordinationMargin_s(idx)>=c.cti-1e-9),'Design coordination failed');
checks{end+1}='PASS: improved primary sensitivity and 0.25 s coordination margin across all 7200 design faults.';
dy=study.dynamic(strcmp(study.dynamic.Scheme,study.schemes{3}.name),:);
normal=~strcmp(dy.Mode,'Transfer trip disabled');
assert(all(dy.Selective(normal)),'Improved scheme dynamic selectivity failed');
assert(all(~dy.FaultCleared(~normal)),'Disabled transfer trip should leave PV feeding these isolated faults');
checks{end+1}='PASS: improved sampled faults, independent validation, no-fault profiles and primary-breaker failures.';
checks{end+1}='PASS: disabled transfer-trip tests expose sustained PV contribution rather than claiming fault clearance.';
% The sensitive remote case requires the source relay when TWO breakers fail.
s=default_scenario(); s.zone=3; s.location=0.9; s.faultType='ABC'; s.Rf=10;
s.pvMW=4; s.loadScale=0.25; s.sourceScale=1.5; s.failedBreaker=[2 3];
fallback=simulate_case(c,s,study.schemes{3});
assert(fallback.cleared && fallback.selective && isfinite(fallback.openedAt(1)),'Two-level backup failed');
writetable(fallback.events,fullfile(root,'results','two_breaker_failure_events.csv'));
checks{end+1}='PASS: source backup clears the sensitive remote fault when B2 and B3 both fail.';
M=timeseries_matrix(out.measurements); B=timeseries_matrix(out.breakerLog);
L=timeseries_matrix(out.relayLog); t=out.measurements.Time;
previous=[]; expected=[]; maxDifference=0;
for k=1:numel(t)
 if k==1, state=ones(1,5); else, state=B(k-1,:); end
 s=default_scenario(); active=s.faultEnabled && t(k)>=c.faultOn-1e-9;
 key=[state double(active)];
 if ~isequal(key,previous)
  n=network_solve(c,s,state(1:4),logical(state(5)),active); expected=pack_measurements(n); previous=key;
 end
 maxDifference=max(maxDifference,max(abs(M(k,:)-expected)));
end
assert(maxDifference<1e-7,'Simulink measurement/reference mismatch');
checks{end+1}='PASS: every Simulink measurement matches the independent circuit solve, including delayed topology feedback.';
for r=1:4
 first=find(L(:,1+(r-1)*5)>0.5,1); opened=find(B(:,r)<0.5,1);
 if isnan(reference.tripAt(r)), assert(isempty(first),'Unexpected Simulink relay trip');
 else, assert(~isempty(first) && abs(t(first)-reference.tripAt(r))<=2*c.dt+1e-8,'Simulink trip-time mismatch'); end
 if isnan(reference.openedAt(r)), assert(isempty(opened),'Unexpected Simulink breaker opening');
 else, assert(~isempty(opened) && abs(t(opened)-reference.openedAt(r))<=2*c.dt+1e-8,'Simulink breaker-time mismatch'); end
end
assert(all(isfinite(M),'all') && all(isfinite(L),'all'),'Nonfinite Simulink outputs');
checks{end+1}='PASS: Simulink relay and breaker times agree with event-driven reference within two 1 ms steps.';
checks{end+1}='PASS: all Simulink measurement and relay output values are finite.';
checks{end+1}=verify_simulink_scenarios(root,c,study.schemes);
fid=fopen(fullfile(root,'results','verification.txt'),'w');
for j=1:numel(checks), fprintf(fid,'%s\n',checks{j}); fprintf('%s\n',checks{j}); end; fclose(fid);
end
