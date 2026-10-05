function n=network_solve(c,s,closed,pvEnabled,faultActive)
% Three-phase nodal RMS circuit. Five unknown buses; bus 5 splits faulted line.
a=exp(2i*pi/3); A=[1 1 1;1 a^2 a;1 a a^2];
E=c.Vph*[1;a^2;a]; Y=complex(zeros(15)); rhs=complex(zeros(15,1));
segments=struct('from',{},'to',{},'Y',{},'relay',{});
for r=1:4
 z=A*diag([c.lineZ0(r),c.lineZ1(r),c.lineZ1(r)])/A;
 zs=A*diag([c.sourceZ0,c.sourceZ1,c.sourceZ1])/A*s.sourceScale;
 if faultActive && r==s.zone
  zFirst=s.location*z; if r==1, zFirst=zFirst+zs; end
  if closed(r), addSegment(c.parent(r),5,zFirst,r); end
  addSegment(5,c.child(r),(1-s.location)*z,0);
 else
  if r==1, z=z+zs; end
  if closed(r), addSegment(c.parent(r),c.child(r),z,r); end
 end
end
for b=1:4
 phaseScale=[1 1-s.unbalance 1+s.unbalance];
 gl=conj(c.loadVA(b))*s.loadScale/(3*c.Vph^2)*phaseScale;
 idx=busidx(b); Y(idx,idx)=Y(idx,idx)+diag(gl);
end
if faultActive, idx=busidx(5); Y(idx,idx)=Y(idx,idx)+fault_admittance(s.faultType,s.Rf); end
% Numerical shunts are 1e-10 S; bound their influence in verification.
Y=Y+eye(15)*1e-10;
pv=complex(zeros(3,1)); rating=s.pvMW*1e6/(3*c.Vph);
maximum=c.pvCurrentLimit*rating; converged=true; iterations=0;
% Each iteration solves the exact linear network for the inverter command.
if pvEnabled && rating>0
 converged=false;
 for iterations=1:250
  b=rhs; b(busidx(c.pvBus))=b(busidx(c.pvBus))+pv;
  V=reshape(Y\b,3,5).'; local=V(c.pvBus,:).';
  positive=(local(1)+a*local(2)+a^2*local(3))/3;
  sag=min(abs(local))/c.Vph;
  % Ideal synchronized angle reference; no PLL or negative-sequence control.
  iq=min(maximum,c.reactiveGain*max(0,0.95-sag)*rating);
  idDemand=s.irradiance*s.pvMW*1e6/(3*max(abs(positive),0.1*c.Vph));
  id=min(idDemand,sqrt(max(0,maximum^2-iq^2)));
  command=(id-1i*iq)*[1;a^2;a];
  if norm(command-pv)<1e-7*max(1,maximum), pv=command; converged=true; break; end
  pv=0.7*pv+0.3*command;
 end
end
b=rhs; b(busidx(c.pvBus))=b(busidx(c.pvBus))+pv;
vector=Y\b; V=reshape(vector,3,5).'; I=complex(zeros(4,3));
for k=1:numel(segments)
 edge=segments(k); if edge.relay==0, continue; end
 if edge.from==0, upstream=E; else, upstream=V(edge.from,:).'; end
 I(edge.relay,:)=(edge.Y*(upstream-V(edge.to,:).')).';
end
if faultActive, If=fault_admittance(s.faultType,s.Rf)*V(5,:).'; else, If=zeros(3,1); end
n=struct('V',V,'I',I,'pvI',pv,'faultI',If,'converged',converged,...
 'iterations',iterations,'kclResidual',norm(Y*vector-b,inf),'pvLimitA',maximum);
if ~converged, error('Inverter/network fixed point failed to converge.'); end
 function idx=busidx(bus), idx=(bus-1)*3+(1:3); end
 function addSegment(from,to,z,relay)
  yy=inv(z); toidx=busidx(to); Y(toidx,toidx)=Y(toidx,toidx)+yy;
  if from==0
   rhs(toidx)=rhs(toidx)+yy*E;
  else
   fromidx=busidx(from); Y(fromidx,fromidx)=Y(fromidx,fromidx)+yy;
   Y(fromidx,toidx)=Y(fromidx,toidx)-yy; Y(toidx,fromidx)=Y(toidx,fromidx)-yy;
  end
  segments(end+1)=struct('from',from,'to',to,'Y',yy,'relay',relay);
 end
end
