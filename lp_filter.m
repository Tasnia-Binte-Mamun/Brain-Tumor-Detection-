function H= lp_filter(type,M,N,D0,n)

[U,V]= dftuv(M,N);
D= hypot(U,V);

switch type
    case 'ideal'
        H= D<=D0;
    case 'butterworth'
        H= 1./(1+((D./D0).^(2*n)));
    case 'gaussian'
        H= exp(-D.^2./(2.*D0^2));
    otherwise
        error('Unknown filter type');
end
end