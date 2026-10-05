classdef ProtectionNetwork < matlab.System
 % Live three-phase RMS network; recalculated whenever topology changes.
 properties(Access=private)
  Config
  Scenario
  PreviousKey
  Measurements
 end
 methods(Access=protected)
  function setupImpl(obj)
   obj.Config=evalin('base','studyConfig'); obj.Scenario=evalin('base','studyScenario');
   obj.PreviousKey=[]; obj.Measurements=zeros(1,66);
  end
  function y=stepImpl(obj,u)
   u=u(:).'; active=obj.Scenario.faultEnabled && u(1)>=obj.Config.faultOn-1e-9;
   key=[u(2:6) double(active)];
   if ~isequal(key,obj.PreviousKey)
    n=network_solve(obj.Config,obj.Scenario,u(2:5),logical(u(6)),active);
    obj.Measurements=pack_measurements(n); obj.PreviousKey=key;
   end
   y=obj.Measurements;
  end
  function resetImpl(obj), obj.PreviousKey=[]; end
  function s=getOutputSizeImpl(~), s=[1 66]; end
  function d=getOutputDataTypeImpl(~), d='double'; end
  function b=isOutputComplexImpl(~), b=false; end
  function b=isOutputFixedSizeImpl(~), b=true; end
 end
end
