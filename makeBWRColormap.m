function M = makeBWRColormap(high,low,zero)
% This function returns a colormap spanning blue-white-red where white
% indicate "zero" point.
pos0 = ceil(255/((high-low)/abs(zero-low)));
M = zeros(255,3);
M(1:pos0,1)=linspace(0,1,pos0);%0;%R
M(1:pos0,3)=1;%linspace(1,0,pos0);%B
M(1:pos0,2)=linspace(0,1,pos0);%linspace(1,0,pos0);%G
M(pos0+1:end,2)=linspace(1,0,255-pos0);%G
M(pos0+1:end,3)=linspace(1,0,255-pos0);%0;%B
M(pos0+1:end,1)=1;%linspace(0,1,255-pos0);%R
end