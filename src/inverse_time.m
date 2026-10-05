function t=inverse_time(current,pickup,tms)
% IEC standard/normal inverse mathematical characteristic, primary amps.
M=current./pickup; t=inf(size(M)); on=M>1;
t(on)=0.14*tms./(M(on).^0.02-1);
end
