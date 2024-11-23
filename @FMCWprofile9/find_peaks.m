F=find_peaks(x,y,M,xi,yi,thresh,wx,wy)
% HPM 08/04/10
% this function finds peaks based on the first or last peak above a threshold
%  INPUT: x = x-coordinate
%         y = y-coordinate
%         M = matrix of values
%         xi = x-locations of estimates
%         yi = y-locations of estimates
%        thresh = threshold to define peak
%            wx = window for horizontal
%            wy = window for vertical
% OUTPUT:     F = pdf of peak locations, for parameters thresh,wx,wy

% in each column, find all peaks above threshold
[n1,m1]=size(M); % dimensions of M
for m=1:m1 % loop over columns
        I2=find(imregionalmax(M(:,m))); % find all peaks
        I3{m}=I2(find(M(I2,m)>thresh)); % find all peaks above thresh
end
%% now loop over locations of estimates to get pdf for each
F=zeros(length(yi),length(xi)); % matrix of pdf values
for m=1:length(xi) % loop over horizontal
    I4=find(x>(xi(m)-wx) && x<=(xi(m)+wx)); % find columns within wx of xi(m)
    Y=y(I3{I4}); % y-coordinate of all peaks within wx;
    F(:,m)=ksdensity(Y,yi,'width',wy); % calculate pdf of peaks using smoothing window wy
end