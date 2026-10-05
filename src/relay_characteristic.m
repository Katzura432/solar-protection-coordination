function [unitTime,forward,phaseA,residualA,channelTime]=relay_characteristic(c,n,settings)
phaseA=max(abs(n.I),[],2); residualA=abs(sum(n.I,2));
a=exp(2i*pi/3); memory=c.Vph*[1 a^2 a];
torque=real(memory.*conj(n.I)*exp(-1i*c.directionAngle));
denominator=abs(memory).*abs(n.I);
phaseForward=torque./max(denominator,1)>0.05;
% Zero-sequence voltage polarization for residual ground protection.
polar=-sum(n.V(c.child,:),2); residual=sum(n.I,2);
groundTorque=real(polar.*conj(residual)*exp(-1i*c.directionAngle));
groundForward=groundTorque./max(abs(polar).*abs(residual),1)>0.05;
forward=any(phaseForward,2);
factor=ones(4,1);
if isfield(settings,'voltageRestraint')
 restrained=settings.voltageRestraint(:);
 voltage=min(abs(n.V(c.child,:)),[],2)/c.Vph;
 factor(restrained)=max(0.50,min(1,voltage(restrained)).^2);
end
phaseTimes=inverse_time(abs(n.I),repmat(settings.phasePickup.*factor,1,3),1);
groundTimes=inverse_time(residualA,settings.groundPickup,1);
if settings.directional
 phaseTimes(~phaseForward)=inf; groundTimes(~groundForward)=inf;
end
channelTime=[phaseTimes groundTimes]; unitTime=min(channelTime,[],2);
end
