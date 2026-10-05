function cases=design_cases(c)
cases=repmat(default_scenario(),0,1);
for zone=1:4
 for type=c.faultTypes
  for location=c.locations
   for R=c.resistances
    for pv=c.solarMW
     for sourceScale=[0.8 1.5]
      for loadScale=[0.25 1.2]
       s=default_scenario(); s.zone=zone; s.faultType=type{1};
       s.location=location; s.Rf=R; s.pvMW=pv;
       s.sourceScale=sourceScale; s.loadScale=loadScale; cases(end+1,1)=s;
      end
     end
    end
   end
  end
 end
end
end
