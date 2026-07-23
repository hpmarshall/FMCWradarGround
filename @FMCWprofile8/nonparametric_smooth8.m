function ymod = nonparametric_smooth8(x,y,xmod,winsize)
% this function smooths a data set of 1 variable using a bisquare kernal
% INPUT:         x = independent variable [n,1]
%                y = dependent variable [n,1]
%             xmod = locations for estimates [*,1]
%          winsize = size of window [same units as x]
% OUTPUT:     ymod = non-parametric density estimate [*,1]
x=x(:);y=y(:);xmod=xmod(:); % force all inputs to columns
ymod=zeros(size(xmod)); % initialize modeled values
for i=1:length(xmod)
    dist=sqrt((x-xmod(i)).^2); % distance from xmod to each point
    ival=find(dist<winsize); % use only the points within winsize of xmod
%     if isempty(ival)
%         ival=find(dist<2*winsize); % use only the points within winsize of xmod
%         winsize=winsize*2;
%     end
%     if isempty(ival)
%         ival=find(dist<4*winsize); % use only the points within winsize of xmod
%         winsize=winsize*2;
%     end
    ival=ival(isfinite(y(ival))); % remove NaNs
    if isempty(ival)
        ymod(i)=NaN; % give a NaN if xmod has no data within winsize
    else
        weights=15/16*(1-(dist(ival)/winsize).^2).^2; % bi-square kernal of weights
        ymod(i)=sum(weights.*y(ival))./sum(weights); % non-param estimate
    end
end
