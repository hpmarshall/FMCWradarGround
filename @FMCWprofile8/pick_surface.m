function obj = pick_surface(obj)
% HPM 11/2/11
% this method picks the surface reflection and plots

[~,m6]=size(obj.PDATA);
Isurf2=ones(1,m6); % surface 
I2=obj.DCcoupling:obj.SurfMax; % range for finding surface
for n=1:m6
    I3=find(imregionalmax(obj.PDATA(I2,n),[0 1 0;0 1 0;0 1 0])); % get all the peaks
    I4=find(obj.PDATA(I2(I3),n)>obj.surfthresh); % find peaks above the threshold
    if ~isempty(I4)
        peaks=I2(I3(I4)); % all the peaks within range above the threshold
        Isurf2(n)=peaks(1); % index to first peak above threshold
    else
        Isurf2(n)=NaN;
    end
end

figure(5);clf
%subplot(2,1,1)
imagesc(obj.PDATA)
colorbar
hold on
plot(Isurf2,'ks','markersize',10,'linewidth',3)
obj.Isurf=Isurf2;

%axis([1 350 0 200])
% now adjust surface to be on the same row

%% below commented for testing

% nr=sum(obj.DepthRange)+1; % total number of measurements per trace to keep
% 
% % now interpolate surface locations for all traces
% x=1:length(Isurf2); % vector of traces
% I7=isfinite(Isurf2); % index to good surface picks
% x2=x(I7); y2=Isurf2(I7); % vectors of good picks
% y3=nonparametric_smooth8(x2,y2,x,5); % 20 trace smooth
% y3(isnan(y3))=nanmean(y3); % set the NaNs to the mean
% %y3=medfilt2(y2,[1 5]); % apply 5-point median filter to remove outliers
% %x2=x2(2:(end-1)); y3=y3(2:(end-1)); % remove end points
% I9=find(y3>(mean(y3)-2*std(y3))); % remove surf picks that are too low
% x4=x(I9); y4=y3(I9);
% figure(5);subplot(2,1,1);
% % I7=I7(2:(end-1));
% % Ip=I7(I9); % index to good picks
% P2=obj.PDATA(:,x4);
% obj.xyz_radar_trace=obj.xyz_radar_trace(x4,:);
% [n6,m6]=size(P2);
% Isurf=y4;
% %Isurf=pchip(x2,y3,x); % interpolate surface location for all traces
% Isurf=round(y4); % round to nearest index
% nr=sum(obj.DepthRange)+1; % total number of measurements per trace to keep
% m6=length(Isurf);
% P=zeros(nr,m6); % initialize
% for n=1:m6 % loop over traces
%     P(:,n)=P2((Isurf(n)-obj.DepthRange(1)):(Isurf(n)+obj.DepthRange(2)),n); % apply shift
% end
% figure(5); subplot(2,1,1)
% hold on
% plot(x4,Isurf,'ks','markersize',10,'linewidth',3)
% plot(x4,y4,'wo','LineWidth',3)
% axis([1 m6 obj.DCcoupling obj.SurfMax])
% subplot(2,1,2)
% imagesc(P)
% colorbar
% obj.Isurf=Isurf;
%obj.PDATA=P; % store surface corrected data
%obj.TWT=obj.TWT(1:nr);
%obj.w=obj.w(1:nr);


function ymod = nonparametric_smooth(x,y,xmod,winsize)
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
    ival=ival(isfinite(y(ival))); % remove NaNs
    if isempty(ival)
        ymod(i)=NaN; % give a NaN if xmod has no data within winsize
    else
        weights=15/16*(1-(dist(ival)/winsize).^2).^2; % bi-square kernal of weights
        ymod(i)=sum(weights.*y(ival))./sum(weights); % non-param estimate
    end
end