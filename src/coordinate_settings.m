function [baseline,directional,improved,design]=coordinate_settings(c,cases)
% Fixed pickups from a forward-load envelope. Shared phase/earth TMS permits
% exact, transparent bottom-up minimization on this radial relay hierarchy.
phaseEnvelope=zeros(4,1); earthEnvelope=zeros(4,1);
for loadScale=[0.25 0.75 1.2]
 for pv=c.solarMW
  s=default_scenario(); s.loadScale=loadScale; s.pvMW=pv; s.unbalance=0.05;
  n=network_solve(c,s,ones(1,4),true,false);
  tmp=struct('phasePickup',ones(4,1),'groundPickup',ones(4,1),'directional',true);
  [~,forward,p,g]=relay_characteristic(c,n,tmp);
  phaseEnvelope=max(phaseEnvelope,p.*forward); earthEnvelope=max(earthEnvelope,g.*forward);
 end
end
base=struct('phasePickup',ceil(1.20*phaseEnvelope/5)*5,...
 'groundPickup',max([30;25;20;15],ceil(1.50*earthEnvelope/5)*5),...
 'tms',c.minTMS*ones(4,1),'directional',true,'voltageRestraint',false(4,1),'name','');
der=base; der.voltageRestraint(1)=true;
N=numel(cases); K=inf(N,4); Kdir=K; Knondir=K; solar=zeros(N,1); maxKCL=0; maxLimitError=0;
for j=1:N
 n=network_solve(c,cases(j),ones(1,4),true,true);
 K(j,:)=relay_characteristic(c,n,der).'; Kdir(j,:)=relay_characteristic(c,n,base).'; solar(j)=cases(j).pvMW;
 nondir=base; nondir.directional=false; Knondir(j,:)=relay_characteristic(c,n,nondir).';
 maxKCL=max(maxKCL,n.kclResidual); maxLimitError=max(maxLimitError,max(abs(n.pvI))-n.pvLimitA);
 if mod(j,1000)==0, fprintf('  Solved %d/%d design faults\n',j,N); end
end
% Only source-connected forward devices can be coordinated by 67.
baseline=base; baseline.tms=grade(Kdir(solar==0,:),cases(solar==0));
baseline.directional=false; baseline.name='Conventional 51/51N';
directional=baseline; directional.directional=true; directional.name='Directional 67/67N';
improved=der; improved.tms=grade(K,cases); improved.name='DER-coordinated 67/67N + 51V';
design=struct('unitTimes',K,'directionalUnitTimes',Kdir,'nonDirectionalUnitTimes',Knondir,'cases',cases,'phaseLoadEnvelope',phaseEnvelope,...
 'earthLoadEnvelope',earthEnvelope,'maxKCLResidual',maxKCL,'maxPVLimitError',maxLimitError);
 function tms=grade(coeff,scenarios)
  tms=c.minTMS*ones(4,1); required=c.cti+c.breakerDelay+c.dt;
  for upstream=[2 1]
   for row=1:numel(scenarios)
    chain=relay_path(scenarios(row).zone);
    p=find(chain==upstream);
    if isempty(p) || p==numel(chain), continue; end
    downstream=chain(p+1);
    if ~isfinite(coeff(row,upstream)) || ~isfinite(coeff(row,downstream))
     ss=scenarios(row); error('Relay cannot pick up: zone=%d type=%s x=%.1f R=%.1f PV=%.1f load=%.2f source=%.1f relays=%d,%d coeff=%g,%g',ss.zone,ss.faultType,ss.location,ss.Rf,ss.pvMW,ss.loadScale,ss.sourceScale,upstream,downstream,coeff(row,upstream),coeff(row,downstream));
    end
    bound=(coeff(row,downstream)*tms(downstream)+required)/coeff(row,upstream);
    tms(upstream)=max(tms(upstream),ceil(bound/c.tmsStep)*c.tmsStep);
   end
  end
  assert(all(tms<=c.maxTMS),'Required TMS exceeds allowed bound.');
 end
end
