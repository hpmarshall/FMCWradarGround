function ymod = nonparametric_smooth8(x,y,xmod,winsize)
% this function smooths a data set of 1 variable using a bisquare kernal
% This version does only vectors, but much faster 04/13/06
% INPUT:         x = independent variable [n,1]
%                y = dependent variable [n,1]
%             xmod = locations for estimates [*,1]
%          winsize = size of window [same units as x]
% OUTPUT:     ymod = non-parametric density estimate [*,1]

%if nargin<5
    

x=x(:);y=y(:);xmod=xmod(:); % force columns
ymod=zeros(size(xmod));
for i=1:length(xmod)
    %if ~rem(i,500)
     %   disp([num2str(i/length(xmod)*100) '% finished'])
    %end
    dist=sqrt((x-xmod(i)).^2); % distance from depthi to each point
    ival=find(dist<winsize); % use only the points within winsize of depthi 
    dy=y(ival)-mean(y(ival)); % deviation of points within winsize from mean
%    ival=ival(dy<maxd); % only use points within maxd of mean, to remove outliers 
    if isempty(ival)
        ymod(i)=NaN;
    else
        weights=15/16*(1-(dist(ival)/winsize).^2).^2; % bi-square kernal of weights
        ymod(i)=sum(weights.*y(ival))./sum(weights); % non-param estimate
    end
end
