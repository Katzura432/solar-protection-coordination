function build_protection_model(root,c)
name='solar_feeder_protection'; if bdIsLoaded(name), close_system(name,0); end
new_system(name); set_param(name,'Solver','FixedStepDiscrete','FixedStep',num2str(c.dt),...
 'StopTime',num2str(c.demoDuration),'ReturnWorkspaceOutputs','on');
add_block('simulink/Sources/Digital Clock',[name '/Time'],'SampleTime',num2str(c.dt),'Position',[25 240 70 280]);
add_block('simulink/Signal Routing/Vector Concatenate',[name '/Network inputs'],'NumInputs','2','Mode','Vector','Position',[120 225 140 305]);
add_block('simulink/User-Defined Functions/MATLAB System',[name '/Three-phase feeder and limited PV'],...
 'System','ProtectionNetwork','SimulateUsing','Interpreted execution','Position',[185 210 420 310]);
for r=1:4
 block=[name '/R' num2str(r) ' phase and earth protection'];
 y=90+(r-1)*135;
 add_block('simulink/User-Defined Functions/MATLAB System',block,'System','ProtectionRelay',...
  'SimulateUsing','Interpreted execution','RelayIndex',num2str(r),'Position',[490 y 710 y+70]);
 add_line(name,'Three-phase feeder and limited PV/1',['R' num2str(r) ' phase and earth protection/1'],'autorouting','on');
end
add_block('simulink/Signal Routing/Vector Concatenate',[name '/Relay outputs'],'NumInputs','4','Mode','Vector','Position',[770 115 795 520]);
for r=1:4, add_line(name,['R' num2str(r) ' phase and earth protection/1'],['Relay outputs/' num2str(r)],'autorouting','on'); end
add_block('simulink/Signal Routing/Selector',[name '/Trip commands'],'NumberOfDimensions','1','IndexOptionArray',{'Index vector (dialog)'},'Indices','[1 6 11 16]','InputPortWidth','20','Position',[850 150 950 190]);
add_block('simulink/Signal Routing/Vector Concatenate',[name '/Breaker inputs'],'NumInputs','2','Mode','Vector','Position',[1000 160 1020 240]);
add_block('simulink/User-Defined Functions/MATLAB System',[name '/Breakers and PV transfer trip'],...
 'System','ProtectionBreakers','SimulateUsing','Interpreted execution','Position',[1080 150 1310 250]);
add_block('simulink/Discrete/Unit Delay',[name '/Topology feedback'],'SampleTime',num2str(c.dt),'InitialCondition','ones(1,5)','Position',[510 660 650 710]);
add_block('simulink/Sinks/To Workspace',[name '/Measurement log'],'VariableName','measurements','SaveFormat','Timeseries','Position',[210 440 390 485]);
add_block('simulink/Sinks/To Workspace',[name '/Relay log'],'VariableName','relayLog','SaveFormat','Timeseries','Position',[850 370 980 415]);
add_block('simulink/Sinks/To Workspace',[name '/Breaker log'],'VariableName','breakerLog','SaveFormat','Timeseries','Position',[1120 370 1260 415]);
add_block('simulink/Sinks/Scope',[name '/Breaker status scope'],'Position',[1120 460 1260 515]);
add_line(name,'Time/1','Network inputs/1','autorouting','on');
add_line(name,'Topology feedback/1','Network inputs/2','autorouting','on');
add_line(name,'Network inputs/1','Three-phase feeder and limited PV/1','autorouting','on');
add_line(name,'Three-phase feeder and limited PV/1','Measurement log/1','autorouting','on');
add_line(name,'Relay outputs/1','Trip commands/1','autorouting','on');
add_line(name,'Relay outputs/1','Relay log/1','autorouting','on');
add_line(name,'Time/1','Breaker inputs/1','autorouting','on');
add_line(name,'Trip commands/1','Breaker inputs/2','autorouting','on');
add_line(name,'Breaker inputs/1','Breakers and PV transfer trip/1','autorouting','on');
add_line(name,'Breakers and PV transfer trip/1','Topology feedback/1','autorouting','on');
add_line(name,'Breakers and PV transfer trip/1','Breaker log/1','autorouting','on');
add_line(name,'Breakers and PV transfer trip/1','Breaker status scope/1','autorouting','on');
Simulink.Annotation(name,sprintf('11 kV four-section feeder | phase-domain RMS network | IEC normal inverse 51/51N and directional 67/67N\nLive breaker feedback, failed-breaker scenarios and direct transfer trip. Run open_demo or run_project before simulation.'));
save_system(name,fullfile(root,'models',[name '.slx']));
print(['-s' name],'-dpng','-r140',fullfile(root,'results','simulink_model.png'));
end
