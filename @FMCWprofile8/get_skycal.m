function obj=get_skycal(obj)
% HPM 07/28/10
% this function uses the total backscatter to grab skycalibration periods and plots
% them with an image of the raw data

I2=obj.S.SkyCalRange(1):obj.S.SkyCalRange(2); % range to sum energy for finding sky cal
% lets sum the values of the top 10 peaks
[n3,m3]=size(obj.PDATA);
% for n=1:m3
%     I3=imregionalmax(obj.PDATA(I2,n),[0 1 0;0 1 0;0 1 0]); % get all the peaks
%     Pv=sort(obj.PDATA(I2(I3),n)); % sort the peaks
%     if length(Pv)>5
%         Pv2=10.^(Pv((end-5):end)/10); % top 10 peaks
%     else
%         Pv2=1;
%     end
%     sP(n)=10*log10(mean(Pv2));
% end
%sP=10*log10(sum(10.^(obj.PDATA(I2,:)/10))); % sum of PSD energy, but sum in non dB space:
sP=sum(10.^(obj.PDATA(I2,:)/10)); % sum of PSD energy, but sum in non dB space:
figure(3);clf
subplot(2,1,1)
imagesc(obj.PDATA)
axis([1 m3 1 n3/2])
subplot(2,1,2)
plot(sP)
axis([1 m3 0 max(sP)])
hold on
plot([1 length(sP)],[obj.S.skythresh obj.S.skythresh],'r')
obj.S.ProfileTraces=find(sP>obj.S.skythresh); % profile data
obj.S.SkycalTraces=find(sP<=obj.S.skythresh); % skycalibration data
% I3=find(diff(obj.ProfileTraces)>20); % find the start of each profile right after skycal
% if ~isempty(I3)
%     I3=[1;I3(:);length(obj.ProfileTraces)]; % include first and last trace
%     PT=[];
%     S=[(I3(1:end-1)+obj.GPSbuffer(1)) (I3(2:end)-obj.GPSbuffer(2))]; % start and end of each profile
%     [n2,~]=size(S);
%     % now build vector of traces during profile
%     for n=1:n2
%         PT=[PT obj.ProfileTraces(S(n,1):S(n,2))]; % store all the profile traces
%     end
%     obj.ProfileTraces=PT;
% end
plot(obj.S.ProfileTraces,mean(sP)*ones(size(obj.S.ProfileTraces)),'go','MarkerSize',10)
plot(obj.S.SkycalTraces,mean(sP)*ones(size(obj.S.SkycalTraces)),'kx','MarkerSize',10)
subplot(2,1,1); hold on
plot(obj.S.ProfileTraces,obj.S.SkyCalRange(1)*ones(size(obj.S.ProfileTraces)),'go','MarkerSize',10)
plot(obj.S.SkycalTraces,obj.S.SkyCalRange(1)*ones(size(obj.S.SkycalTraces)),'kx','MarkerSize',10)

% figure(1);hold on
% dx=min(obj.xyz_GPS(:,1));
% dy=min(obj.xyz_GPS(:,2));
% plot(obj.xyz_radar_trace(obj.ProfileTraces,1)-dx,obj.xyz_radar_trace(obj.ProfileTraces,2)-dy,'rx')
% plot(obj.xyz_radar_trace(obj.SkycalTraces,1)-dx,obj.xyz_radar_trace(obj.SkycalTraces,2)-dy,'ks')

