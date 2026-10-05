classdef ProtectionRelay < matlab.System
 properties(Nontunable)
  RelayIndex=1
 end
 properties(Access=private)
  Config
  Settings
  Progress
  Tripped
 end
 methods(Access=protected)
  function setupImpl(obj)
   obj.Config=evalin('base','studyConfig'); obj.Settings=evalin('base','studySettings');
   obj.Progress=zeros(1,4); obj.Tripped=false;
  end
  function y=stepImpl(obj,u)
   n=unpack_measurements(u);
   [~,forward,p,g,channels]=relay_characteristic(obj.Config,n,obj.Settings);
   times=channels(obj.RelayIndex,:)*obj.Settings.tms(obj.RelayIndex);
   if ~obj.Tripped
    obj.Progress(~isfinite(times))=0;
    obj.Progress=obj.Progress+obj.Config.dt./times;
    obj.Tripped=any(obj.Progress>=1-1e-10);
   end
   y=[double(obj.Tripped),max(obj.Progress),p(obj.RelayIndex),g(obj.RelayIndex),double(forward(obj.RelayIndex))];
  end
  function resetImpl(obj), obj.Progress=zeros(1,4); obj.Tripped=false; end
  function s=getOutputSizeImpl(~), s=[1 5]; end
  function d=getOutputDataTypeImpl(~), d='double'; end
  function b=isOutputComplexImpl(~), b=false; end
  function b=isOutputFixedSizeImpl(~), b=true; end
 end
end
