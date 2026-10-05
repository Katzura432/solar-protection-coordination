function u=pack_measurements(n)
u=[real(n.I(:));imag(n.I(:));real(n.V(:));imag(n.V(:));...
 real(n.pvI(:));imag(n.pvI(:));real(n.faultI(:));imag(n.faultI(:))].';
end
