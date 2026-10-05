classdef ProtectionBreakers < matlab.System
 properties(Access=private)
  Config
  Scenario
  Closed
  OpenAt
  Commanded
  PV
  PVStopAt
 end
 methods(Access=protected)
  function setupImpl(obj)
   obj.Config=evalin('base','studyConfig'); obj.Scenario=evalin('base','studyScenario');
   resetImpl(obj);
  end
  function y=stepImpl(obj,u)
   u=u(:).'; t=u(1);
   for r=1:4
    if u(r+1)>0.5 && ~obj.Commanded(r)
     obj.Commanded(r)=true;
     if ~ismember(r,obj.Scenario.failedBreaker), obj.OpenAt(r)=t+obj.Config.breakerDelay; end
    end
    if obj.OpenAt(r)<=t+1e-9
     obj.Closed(r)=0; obj.OpenAt(r)=inf;
     if any(r==[1 2 3]) && obj.PV && obj.Scenario.transferTrip
      obj.PVStopAt=min(obj.PVStopAt,t+obj.Config.transferDelay+obj.Config.pvBreakerDelay);
     end
    end
   end
   if obj.PVStopAt<=t+1e-9, obj.PV=false; obj.PVStopAt=inf; end
   y=[obj.Closed double(obj.PV)];
  end
  function resetImpl(obj)
   obj.Closed=ones(1,4); obj.OpenAt=inf(1,4); obj.Commanded=false(1,4); obj.PV=true; obj.PVStopAt=inf;
  end
  function s=getOutputSizeImpl(~), s=[1 5]; end
  function d=getOutputDataTypeImpl(~), d='double'; end
  function b=isOutputComplexImpl(~), b=false; end
  function b=isOutputFixedSizeImpl(~), b=true; end
 end
end
