function M = makeBWRColormap3(high,low,zero)
% This function returns a colormap spanning blue-white-red where white
% indicate "zero" point.
% 2020/11/27: Use [178,24,43] for R and [33,102,172] for B
pos0 = ceil(255/((high-low)/abs(zero-low)));

orimap = [178,24,43;...
    214,96,77;...
    244,165,130;...
    253,219,199;...
    247,247,247;...
    209,229,240;...
    146,197,222;...
    67,147,195;...
    33,102,172];

i_orizero = 5;
num_oricol = size(orimap,1);

M1 = zeros(255,3);
for n = 1:3
    M1(1:pos0,n) = interp1(linspace(1,pos0,i_orizero),orimap(end:-1:i_orizero,n),1:pos0);
    M1(pos0:end,n) = interp1(linspace(pos0,255,num_oricol-i_orizero+1),orimap(i_orizero:-1:1,n),pos0:255);
end
M = M1./255;

end