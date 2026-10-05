function open_demo(mode,zone,faultType,pvMW,failedBreaker)
% Open the built model. Example: open_demo('coordinated',3,'AG',4,3)
if nargin<1, mode='coordinated'; end
if nargin<2, zone=3; end
if nargin<3, faultType='AG'; end
if nargin<4, pvMW=4; end
if nargin<5, failedBreaker=0; end
root=fileparts(mfilename('fullpath')); addpath(fullfile(root,'src'));
designPath=fullfile(root,'data','design.mat');
assert(isfile(designPath),'Run run_project first, or download the complete repository.');
d=load(designPath,'c','baseline','directional','improved');
switch lower(mode)
 case 'coordinated', settings=d.improved;
 case 'conventional', settings=d.baseline;
 case 'directional', settings=d.directional;
 otherwise, error('Mode must be coordinated, conventional, or directional.');
end
validateattributes(zone,{'numeric'},{'scalar','integer','>=',1,'<=',4});
validateattributes(pvMW,{'numeric'},{'scalar','>=',0,'<=',4});
assert(any(strcmp(faultType,d.c.faultTypes)),'Unsupported fault type');
validateattributes(failedBreaker,{'numeric'},{'vector','integer','>=',0,'<=',4});
s=default_scenario(); s.zone=zone; s.faultType=faultType; s.pvMW=pvMW; s.failedBreaker=failedBreaker;
assignin('base','studyConfig',d.c); assignin('base','studyScenario',s); assignin('base','studySettings',settings);
modelPath=fullfile(root,'models','solar_feeder_protection.slx'); open_system(modelPath);
if any(failedBreaker>0), stop=d.c.duration; else, stop=max(d.c.demoDuration,3); end
set_param('solar_feeder_protection','StopTime',num2str(stop));
fprintf('Ready: %s, section %d %s, PV %.1f MW. Click Run in Simulink.\n',settings.name,zone,faultType,pvMW);
end
