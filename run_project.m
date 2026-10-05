% Complete deterministic design, validation, Simulink simulation and reporting.
clear; close all; clc; root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'src'));
for folder={'src','data','models','results','docs'}, if ~isfolder(fullfile(root,folder{1})), mkdir(fullfile(root,folder{1})); end; end
c=study_config(); rng(c.seed,'twister'); fprintf('Building design fault envelope...\n');
cases=design_cases(c); fprintf('%d design scenarios\n',numel(cases));
[baseline,directional,improved,design]=coordinate_settings(c,cases);
save(fullfile(root,'data','design.mat'),'c','baseline','directional','improved','design');
disp(table(string(c.relayNames'),improved.phasePickup,improved.groundPickup,baseline.tms,improved.tms,...
 'VariableNames',{'Relay','PhasePickup_A','ResidualPickup_A','BaselineTMS','DERcoordinatedTMS'}));
fprintf('Evaluating static coordination and event-driven breaker cases...\n');
study=analyze_study(c,baseline,directional,improved,design);
save(fullfile(root,'data','study.mat'),'study','c','baseline','directional','improved');
writetable(study.static,fullfile(root,'results','coordination_sweep.csv'));
writetable(study.dynamic,fullfile(root,'results','dynamic_validation.csv'));
studyConfig=c; studyScenario=default_scenario(); studySettings=improved;
assignin('base','studyConfig',studyConfig); assignin('base','studyScenario',studyScenario); assignin('base','studySettings',studySettings);
fprintf('Building and executing live Simulink protection model...\n');
build_protection_model(root,c); out=sim('solar_feeder_protection');
save(fullfile(root,'results','simulink_demo.mat'),'out','studyConfig','studyScenario','studySettings');
reference=simulate_case(c,studyScenario,studySettings); writetable(reference.events,fullfile(root,'results','demo_event_log.csv'));
verification=verify_project(c,design,study,out,reference,root);
export_results(root,c,design,study,out,reference,verification);
fprintf('COMPLETE. Project: %s\n',root);
