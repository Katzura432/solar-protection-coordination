function G=fault_admittance(kind,R)
g=1/max(R,1e-4); G=zeros(3);
switch kind
 case 'AG', G(1,1)=g;
 case 'BG', G(2,2)=g;
 case 'CG', G(3,3)=g;
 case {'AB','ABG'}, pair=[1 2];
 case {'BC','BCG'}, pair=[2 3];
 case {'CA','CAG'}, pair=[3 1];
 case 'ABC', G=eye(3)*g; % Balanced three-phase-to-ground shunts.
 otherwise, error('Unknown fault type: %s',kind);
end
if exist('pair','var')
 G(pair,pair)=g*[1 -1;-1 1];
 if endsWith(kind,'G'), G(pair,pair)=G(pair,pair)+g*eye(2); end
end
end
