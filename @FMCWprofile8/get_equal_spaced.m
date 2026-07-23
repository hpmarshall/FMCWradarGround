function obj=get_equal_spaced(obj)
% this function takes the radar GPS data and makes equally spaced set of points
XY=obj.xyz_radar_trace;
%R=cumsum(sqrt(diff(XY(:,1)).^2+diff(XY(:,2)).^2)); % distance along transect 
%dR=10; % calculate in 100m sections
dR2=0.25; % point spacing
%n=dR/dR2; % number of equally spaced points
winsize=1000; % use window of 1000 radar trace locations
sp=1:winsize/2:(length(XY)-winsize); % starting point of window
%xm=NaN*zeros(length(XY),1); ym=NaN*zeros(length(XY),1);
xm2=[]; ym2=[];
%Rt=0;
%while Rt<max(R) % while we are at a position less than the total transect length
%    I2=find(R<Rt+dR); % find all points within this 100m section
%    xt=XY(I2,1);
%    yt=XY(I2,2);
% 
dN2=0;
xm3=[];ym3=[];
disp('calculating equally spaced points')
 for n=1:length(sp)
    n
    xt=XY(sp(n):(sp(n)+winsize-1),1);
    yt=XY(sp(n):(sp(n)+winsize-1),2);
    t=(1:winsize)';
    P=polyfit(t,xt,3);
    xm=polyval(P,t(winsize/4:3*winsize/4));
    P=polyfit(t,yt,3);
    ym=polyval(P,t(winsize/4:3*winsize/4));  
    xm=[xm3(:);xm(:)]; % add left over points
    ym=[ym3(:);ym(:)]; % add left over points
    dR3=sqrt(diff(xm).^2+diff(ym).^2); % dist between points
    TL=cumsum(dR3); % length of trace at any point
    % now find a length that has an even number of points
    I2=find(TL<floor(max(TL)));
    xm3=xm(max(I2):end); ym3=ym(max(I2):end);
    % use only the points that are in the even distance
    xm=xm(I2); ym=ym(I2);
    %dN=max(TL)-floor(max(TL)); % left over points
    %dN2=dR2-dN; % remove this distance from next one
    np=round(floor(max(TL))/dR2)+1; % number of equal spaced points
    if length(xm)>2
        [x2,y2] = linspacearc(xm,ym,np);
        xm2=[xm2;x2(2:end)']; % fixed problem of endpoints being very close
        ym2=[ym2;y2(2:end)']; % fixed problem of endpoints being very close
    end
    %figure(3);hold on
    %plot(xm,ym,'g-')
end
obj.smooth_x=xm2; obj.smooth_y=ym2;

function [x2,y2] = linspacearc(x,y,n)
m = length(x);
t = linspace(0,1,m);
ppx = spline(t,x);
ppy = spline(t,y);
 
dppx = pp_deriv(ppx);
dppy = pp_deriv(ppy);
integrand = @(tt) sqrt(ppval(dppx,tt).^2 + ppval(dppy,tt).^2);
arc_length = quadgk(integrand,0,1);
s = linspace(0,arc_length,n);
 
inv_arc_len = @(arc,est) fzero(@(u)(quadgk(integrand,0,u)) - arc,est);
 
t2 = zeros(1,n);
t2(1) = inv_arc_len(s(1),0);
for i = 2:n
    t2(i) = inv_arc_len(s(i),t2(i-1));
end
 
x2 = ppval(ppx,t2);
y2 = ppval(ppy,t2);
 
 
function dpp = pp_deriv(pp)
% pp_deriv: derivative of piecewise polynomial (pp)
 
dpp = pp;
n = pp.order;
dpp.coefs = bsxfun(@times,n-1:-1:1,pp.coefs(:,1:n-1));
dpp.order = n - 1;