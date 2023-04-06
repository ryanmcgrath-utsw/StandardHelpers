function M = makeCBYColormap(high,low,zero)
% This function returns a colormap spanning cyan-black-yellow where black
% indicate "zero" point.
pos0 = ceil(255/((high-low)/abs(zero-low)));
M = zeros(255,3);
M(1:pos0,1)=0;
M(1:pos0,3)=linspace(1,0,pos0);
M(1:pos0,2)=linspace(1,0,pos0);
M(pos0+1:end,2)=linspace(0,1,255-pos0);
M(pos0+1:end,3)=0;
M(pos0+1:end,1)=linspace(0,1,255-pos0);
end