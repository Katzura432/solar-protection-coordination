function c=study_config()
% All impedances are ohms per phase; phasors are RMS.
c.VLL=11e3; c.f=60; c.Vph=c.VLL/sqrt(3); c.dt=0.001;
c.sourceZ1=0.12+1.20i; c.sourceZ0=0.25+1.80i;
c.lineZ1=[0.25+0.40i;0.70+0.90i;0.525+0.675i;0.875+1.125i];
c.lineZ0=3*c.lineZ1;
c.parent=[0 1 2 1]; c.child=[1 2 3 4]; c.relayNames={'R1','R2','R3','R4'};
c.loadVA=[0.8+0.20i;1.2+0.30i;1.6+0.40i;1.4+0.35i]*1e6;
c.pvBus=3; c.pvRatedMW=4; c.pvCurrentLimit=1.20; c.reactiveGain=2;
c.CTprimary=[600 300 300 200]; c.CTsecondary=1;
c.cti=0.25; c.breakerDelay=0.05; c.transferDelay=0.02; c.pvBreakerDelay=0.04;
c.minTMS=0.04; c.maxTMS=2.0; c.tmsStep=0.005; c.directionAngle=60*pi/180;
c.faultOn=0.25; c.duration=45; c.demoDuration=1.2; c.seed=20261004;
c.faultTypes={'AG','BG','CG','AB','BC','CA','ABG','BCG','CAG','ABC'};
c.solarMW=[0 1 2 3 4]; c.locations=[0.1 0.5 0.9]; c.resistances=[0.1 2 10];
c.validationCount=180;
end
