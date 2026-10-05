function export_results(root,c,design,study,out,reference,checks)
schemes=study.schemes; labels={'Conventional','Directional only','DER coordinated'};
settings=table(string(c.relayNames'),c.CTprimary',schemes{3}.phasePickup,...
 schemes{3}.groundPickup,schemes{3}.phasePickup./c.CTprimary',...
 schemes{3}.groundPickup./c.CTprimary',schemes{1}.tms,schemes{3}.tms,...
 schemes{3}.voltageRestraint,'VariableNames',{'Relay','CTprimary_A','PhasePickupPrimary_A','ResidualPickupPrimary_A',...
 'PhasePickupSecondary_A','ResidualPickupSecondary_A','BaselineTMS','DERcoordinatedTMS','VoltageRestraintEnabled'});
writetable(settings,fullfile(root,'results','relay_settings.csv'));
summaryRows=cell(3,11); summary=struct();
for q=1:3
 st=study.static(strcmp(study.static.Scheme,schemes{q}.name),:);
 dy=study.dynamic(strcmp(study.dynamic.Scheme,schemes{q}.name),:);
 finite=isfinite(st.CoordinationMargin_s); finiteMargins=st.CoordinationMargin_s(finite);
 validation=strcmp(dy.Partition,'Independent validation'); faults=strcmp(dy.Mode,'Fault');
 healthy=strcmp(dy.Mode,'No fault'); failed=strcmp(dy.Mode,'Primary breaker fails');
 summaryRows(q,:)={schemes{q}.name,height(st),sum(st.CoordinationMargin_s<c.cti),sum(isinf(st.CoordinationMargin_s)&st.CoordinationMargin_s<0),...
  min(finiteMargins),max(st.PrimaryTripDelay_s),sum(~dy.Selective(healthy)),...
  100*mean(dy.Selective(validation)),100*mean(dy.Selective(faults)),sum(dy.Selective(failed)),sum(failed)};
 summary(q).scheme=schemes{q}.name; summary(q).designFaults=height(st);
 summary(q).coordinationViolations=sum(st.CoordinationMargin_s<c.cti);
 summary(q).missingRequiredPrimaryOrBackup=sum(st.CoordinationMargin_s==-inf);
 summary(q).minimumFiniteCoordinationMargin_s=min(finiteMargins);
 summary(q).maximumDesignPrimaryTripDelay_s=max(st.PrimaryTripDelay_s);
 summary(q).validationFaults=sum(validation); summary(q).validationSelective=sum(dy.Selective(validation));
 summary(q).healthyProfiles=sum(healthy); summary(q).healthyNuisanceCases=sum(~dy.Selective(healthy));
 summary(q).breakerFailureCases=sum(failed); summary(q).breakerFailureSelective=sum(dy.Selective(failed));
end
metrics=struct('matlab',version,'seed',c.seed,'VLL_V',c.VLL,'pvCurrentLimit_pu',c.pvCurrentLimit,...
 'designScenarios',numel(design.cases),'dynamicScenariosPerScheme',numel(study.dynamicCases),...
 'independentValidationScenarios',c.validationCount,'requiredCTI_s',c.cti,'breakerDelay_s',c.breakerDelay,...
 'maxDesignKCLResidual_A',design.maxKCLResidual,'schemes',summary);
fid=fopen(fullfile(root,'results','summary.json'),'w'); fprintf(fid,'%s',jsonencode(metrics,PrettyPrint=true)); fclose(fid);
summaryTable=cell2table(summaryRows,'VariableNames',{'Scheme','DesignFaults','CoordinationViolations','MissingRequiredRelay',...
 'MinFiniteMargin_s','MaxPrimaryTripDelay_s','NoFaultNuisanceCases','ValidationSelective_pct','FaultSelective_pct','BreakerFailurePasses','BreakerFailureCases'});
writetable(summaryTable,fullfile(root,'results','summary.csv')); disp(summaryTable);
save(fullfile(root,'results','study_metrics.mat'),'metrics','settings','checks');
% Single-line topology, with explicit relay/breaker positions.
fig=figure('Color','w','Position',[60 60 1300 660]); ax=axes(fig); hold(ax,'on'); axis(ax,[0 12 -1 6]); axis(ax,'off');
axis(ax,[0 13.5 -1 6]);
plot([1 3 6 9],[4 4 4 4],'k-','LineWidth',2); plot([3 3 6],[4 1 1],'k-','LineWidth',2);
scatter([3 6 9 6],[4 4 4 1],130,'k','filled');
plot([1.8 4.5 7.5 3],[4 4 4 2],'ks','MarkerSize',10,'MarkerFaceColor','w','LineWidth',1.5);
text(0.4,5.1,{'Utility source','11 kV, 60 Hz','Grounded Thevenin'},'FontSize',12);
text(1.5,4.3,{'R1 / B1','Section 1'},'FontSize',11); text(4,4.3,{'R2 / B2','Section 2'},'FontSize',11);
text(7,4.3,{'R3 / B3','Section 3'},'FontSize',11); text(3.3,1.5,{'R4 / B4','Section 4'},'FontSize',11);
for b=1:3
 xx=[3 6 9];
 if b==1
  plot([3 3.6 3.6],[4 3.6 3.1],'k-'); tx=3.7;
 else
  plot([xx(b) xx(b)],[4 3.1],'k-'); tx=xx(b)-0.5;
 end
 text(tx,2.8,sprintf('Bus %d\n%.1f MW load',b,real(c.loadVA(b))/1e6),'FontSize',11);
end
text(6.2,0.9,{'Bus 4','1.4 MW load'},'FontSize',11);
plot([9 10.5 10.5],[4 4 2.4],'Color',[0 .5 .25],'LineWidth',2);
text(9.8,2,{'PV intertie breaker','0-4 MW inverter','1.20 pu current limit'},'FontSize',12,'Color',[0 .4 .2]);
text(0.5,-0.3,{'Faults at 10%, 50%, and 90% of each section; faulted line is split at the fault node.',...
 'R1 backs up R2 and R4; R2 backs up R3. Opening B1/B2/B3 initiates direct PV transfer trip.'},'FontSize',12);
title('Distribution feeder single-line diagram','FontSize',18); exportFig(fig,'single_line_diagram');
% Nominal TCCs; grounding pickup is residual 3I0, not I0.
fig=figure('Color','w','Position',[40 40 1400 750]); tiledlayout(1,2,'TileSpacing','compact'); colors=lines(4);
for element=1:2
 nexttile; hold on;
 if element==1, pickups=schemes{3}.phasePickup; heading='Phase elements'; else, pickups=schemes{3}.groundPickup; heading='Residual earth elements (3I_0)'; end
 for r=1:4
  amp=logspace(log10(pickups(r)*1.02),4.2,400);
  loglog(amp,inverse_time(amp,pickups(r),schemes{3}.tms(r)),'Color',colors(r,:),'LineWidth',1.8,'DisplayName',c.relayNames{r});
  loglog(amp,inverse_time(amp,pickups(r),schemes{1}.tms(r)),'--','Color',colors(r,:),'HandleVisibility','off');
 end
 if element==1
  amp=logspace(log10(pickups(1)*0.85^2*1.02),4.2,400);
  loglog(amp,inverse_time(amp,pickups(1)*0.85^2,schemes{3}.tms(1)),':k','LineWidth',1.6,'DisplayName','R1 at 0.85 pu voltage');
 end
 set(gca,'XScale','log','YScale','log'); grid on; ylim([0.025 50]); xlabel('Primary current (A RMS)'); ylabel('Relay trip delay (s)'); title(heading); legend('Location','southwest');
end
sgtitle('Time-current curves | solid: DER coordinated; dashed: original | breaker delay excluded'); exportFig(fig,'time_current_curves');
% Design vs independent validation outcomes.
fig=figure('Color','w','Position',[50 50 1400 850]); tiledlayout(2,2,'TileSpacing','compact');
nexttile; hold on;
for q=1:3
 rates=zeros(size(c.solarMW)); st=study.static(strcmp(study.static.Scheme,schemes{q}.name),:);
 for j=1:numel(c.solarMW), selected=st.Solar_MW==c.solarMW(j); rates(j)=100*mean(st.CoordinationMargin_s(selected)>=c.cti & st.PrimaryDetected(selected)); end
 plot(c.solarMW,rates,'-o','LineWidth',1.7,'DisplayName',labels{q});
end
ylim([0 105]); grid on; xlabel('Installed PV (MW)'); ylabel('Design cases passing (%)'); title('Primary/backup sensitivity and 0.25 s grading'); legend('Location','southwest');
nexttile; bar(cell2mat(summaryRows(:,8))); xticks(1:3); xticklabels(labels); ylim([0 105]); ylabel('Selective fault clearing (%)'); title(sprintf('%d independent validation faults',c.validationCount)); grid on;
nexttile; bar(cell2mat(summaryRows(:,7))); xticks(1:3); xticklabels(labels); ylabel('No-fault profiles with nuisance trips'); title('Normal load and PV operating envelope'); grid on;
nexttile; bar([cell2mat(summaryRows(:,10)) cell2mat(summaryRows(:,11))-cell2mat(summaryRows(:,10))],'stacked'); xticks(1:3); xticklabels(labels); ylabel('Primary-breaker failure cases'); title('Backup protection performance'); legend('Selective','Not selective','Location','northwest'); grid on;
sgtitle('Protection coordination and selectivity study'); exportFig(fig,'validation_summary');
% Solar contribution, using a specified fixed fault rather than pooled averages.
s=default_scenario(); s.faultType='ABC'; s.zone=3; s.location=0.5; s.Rf=2;
P=linspace(0,4,41); contribution=zeros(numel(P),3);
for k=1:numel(P), s.pvMW=P(k); n=network_solve(c,s,ones(1,4),true,true); contribution(k,:)=[abs(n.I(1,1)) abs(n.pvI(1)) abs(n.faultI(1))]; end
fig=figure('Color','w','Position',[70 70 1200 650]); plot(P,contribution,'LineWidth',1.8); grid on; xlabel('Installed PV (MW)'); ylabel('Phase A current (A RMS)'); legend('Source relay R1','PV inverter','Fault branch','Location','best');
title('PV fault contribution | section 3, midpoint ABC-G fault, R_f = 2 ohms'); exportFig(fig,'solar_fault_contribution');
% Actual main Simulink traces.
M=timeseries_matrix(out.measurements); B=timeseries_matrix(out.breakerLog); L=timeseries_matrix(out.relayLog); t=out.measurements.Time;
count=numel(t); phaseCurrent=zeros(count,4); busVoltage=zeros(count,4); faultCurrent=zeros(count,1); pvCurrent=zeros(count,1);
for k=1:count, n=unpack_measurements(M(k,:)); phaseCurrent(k,:)=max(abs(n.I),[],2).'; busVoltage(k,:)=min(abs(n.V(1:4,:)),[],2).'/c.Vph; faultCurrent(k)=max(abs(n.faultI)); pvCurrent(k)=max(abs(n.pvI)); end
window=[0 min(c.duration,max(c.faultOn+0.5,reference.clearingTime+0.25))];
fig=figure('Color','w','Position',[30 30 1450 1100]); tiledlayout(5,1,'TileSpacing','compact');
nexttile; plot(t,busVoltage,'LineWidth',1.4); ylabel('Bus voltage (pu)'); grid on; legend('Bus 1','Bus 2','Bus 3','Bus 4','Location','eastoutside'); title('Actual Simulink run | section 3 AG fault | 4 MW solar');
nexttile; plot(t,phaseCurrent,'LineWidth',1.4); ylabel('Max phase current (A)'); grid on; legend(c.relayNames,'Location','eastoutside');
nexttile; plot(t,L(:,[2 7 12 17]),'LineWidth',1.4); yline(1,'k--'); ylabel('Relay operate accumulator'); grid on;
nexttile; stairs(t,B,'LineWidth',1.5); ylim([-0.1 1.1]); ylabel('Breaker closed = 1'); grid on; legend('B1','B2','B3','B4','PV intertie','Location','eastoutside');
nexttile; plot(t,[faultCurrent pvCurrent],'LineWidth',1.5); ylabel('Current (A RMS)'); xlabel('Time (s)'); grid on; legend('Fault current','PV contribution','Location','eastoutside');
axs=findall(fig,'Type','axes'); set(axs,'XLim',window); exportFig(fig,'simulink_fault_results');
writetable(table(t,phaseCurrent(:,1),phaseCurrent(:,2),phaseCurrent(:,3),phaseCurrent(:,4),B(:,1),B(:,2),B(:,3),B(:,4),B(:,5),faultCurrent,pvCurrent,...
 'VariableNames',{'Time_s','R1PhaseCurrent_A','R2PhaseCurrent_A','R3PhaseCurrent_A','R4PhaseCurrent_A','B1Closed','B2Closed','B3Closed','B4Closed','PVClosed','FaultCurrent_A','PVCurrent_A'}),fullfile(root,'results','simulink_traces.csv'));
% Select an actual sympathetic-trip case from the dynamic sweep.
dy=study.dynamic; bad=dy.CaseID(strcmp(dy.Scheme,schemes{1}.name)&strcmp(dy.Mode,'Fault')&dy.UnrelatedRelayTrip);
assert(~isempty(bad),'Expected at least one conventional sympathetic-trip case');
s=study.dynamicCases(bad(1)); conventional=simulate_case(c,s,schemes{1}); coordinated=simulate_case(c,s,schemes{3});
writetable(conventional.events,fullfile(root,'results','conventional_comparison_events.csv'));
writetable(coordinated.events,fullfile(root,'results','coordinated_comparison_events.csv'));
save(fullfile(root,'results','comparison_case.mat'),'s','conventional','coordinated');
fig=figure('Color','w','Position',[80 80 1300 850]); tiledlayout(3,1,'TileSpacing','compact');
nexttile; h=conventional.history; stairs(h(:,1),h(:,2:5),'LineWidth',1.4); ylabel('Relay current (A)'); grid on; legend(c.relayNames,'Location','eastoutside'); title(sprintf('Actual sympathetic-trip comparison | section %d %s | PV %.1f MW',s.zone,s.faultType,s.pvMW));
nexttile; stairs(conventional.history(:,1),conventional.history(:,14:17),'LineWidth',1.5); ylim([-0.1 1.1]); ylabel('Conventional breakers'); grid on; legend('B1','B2','B3','B4','Location','eastoutside');
nexttile; stairs(coordinated.history(:,1),coordinated.history(:,14:17),'LineWidth',1.5); ylim([-0.1 1.1]); ylabel('Coordinated breakers'); xlabel('Time (s)'); grid on;
window=[0 max([c.faultOn+0.4 conventional.clearingTime coordinated.clearingTime])+0.15]; axs=findall(fig,'Type','axes'); set(axs,'XLim',window); exportFig(fig,'protection_comparison');
write_engineering_report(root,c,design,study,metrics,settings,reference);
 function exportFig(fig,name)
  axs=findall(fig,'Type','axes'); for ax=axs', ax.Toolbar.Visible='off'; end
  exportgraphics(fig,fullfile(root,'results',[name '.png']),'Resolution',160);
  exportgraphics(fig,fullfile(root,'results',[name '.pdf']),'ContentType','vector');
 end
end
