function RMSE = radarFit(rmod2,TWT,PDATA3,rmod,MPdepth,gthresh,sthresh)
% function to find best thresholds for surface/ground picks

[~,m6]=size(PDATA3);
Isurf=ones(1,m6); % surface 
Iground=ones(1,m6); % ground
I2=650:1400; % range for finding peaks
for n=1:m6
    if isfinite(sum(PDATA3(I2,n))) % if no NaNs
        I3=find(imregionalmax(PDATA3(I2,n),[0 1 0;0 1 0;0 1 0])); % get all the peaks
        I4=find(PDATA3(I2(I3),n)>sthresh); % find peaks above the threshold
        if ~isempty(I4)
            SurfPeaks=I2(I3(I4)); % all the peaks within range above the threshold
            Isurf(n)=SurfPeaks(1); % index to first peak above threshold
        else
            Isurf(n)=NaN;
        end
        I5=find(PDATA3(I2(I3),n)>gthresh); % find peaks above the threshold
        if ~isempty(I4)
            Gpeaks=I2(I3(I5)); % all the peaks within range above the threshold
            Iground(n)=Gpeaks(end); % index to last peak above threshold
        else
            Iground(n)=NaN;
        end
    else
        Isurf(n)=NaN;
        Iground(n)=NaN;
    end
end
%
% now one last loop to get median depth at each MP location
winsize2=15; % window size for median
RadarDepth=zeros(size(rmod))*NaN;
for n=1:length(rmod)
    Ix=find(rmod2>(rmod(n)-winsize2/2) & rmod2<(rmod(n)+winsize2/2)); % radar traces in window
    IxG=isfinite(Iground(Ix));
    IxS=isfinite(Isurf(Ix));
    if sum(IxG)>0 && sum(IxS)>0
        Sloc=median(TWT(Isurf(Ix(IxS)))); % surface TWT
        Gloc=median(TWT(Iground(Ix(IxG)))); % ground TWT
        RadarDepth(n)=(Gloc-Sloc)*2.275e10; % estimated depth (find other factor of 2!)
    end
end
RadarDepth=nonparametric_smooth8(rmod,RadarDepth,rmod,10);
MPdepth=MPdepth(:);
Ix=isfinite(MPdepth) & isfinite(RadarDepth);
RMSE=sqrt(mean((MPdepth(Ix)-RadarDepth(Ix)).^2));
[Rval,~]=corrcoef(MPdepth(Ix),RadarDepth(Ix));
C=1-Rval(1,2); % output to minimize
