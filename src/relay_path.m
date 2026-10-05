function chain=relay_path(zone)
switch zone
 case 1, chain=1;
 case 2, chain=[1 2];
 case 3, chain=[1 2 3];
 case 4, chain=[1 4];
 otherwise, error('Invalid zone');
end
end
