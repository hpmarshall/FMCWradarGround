function obj=remove_skycal(obj)
% HPM 07/28/10
% this function uses the get_skycal to subtract the skycal data from the rest

if isempty(obj.S.ProfileTraces)
    disp('sky cal locations not set, run get_skycal')
else
    obj.PDATA=obj.PDATA(:,obj.S.ProfileTraces);
end



% [n2,m2]=size(obj.TDATA(:,obj.ProfileTraces));
% if ~isempty(obj.SkycalTraces)
%     mSky=median(obj.TDATA(:,obj.SkycalTraces),2); % median sky cal tdata
% else
%     mSky=zeros(n2,1);
% end
% n4=floor(obj.nfft/4);
% obj.TDATA=obj.TDATA(:,obj.ProfileTraces); %-mSky*ones(1,m2); % subtract sky cal; % replace TDATA with only those traces that are part of profile
% obj.PDATA=obj.PDATA(:,obj.ProfileTraces);
% obj.mSky=mSky; % store sky calibration
% 


% figure(10);clf
% plot(mean(obj.TDATA(:,obj.ProfileTraces),2)); hold on
% plot(mSky,'r','LineWidth',3)
% plot(mean(Ptdata,2),'k','LineWidth',3)

%% TESTING...
% nfft=2^13; % number of FFT points
% Ptdata2=Ptdata(111:end,:); % remove funny data at start - GPS noise?
% [n2,m2]=size(Ptdata); % size of time domain matrix
% ww = KaiserBessel(n2,2.0); % calculate window
% WW=ww(:)*ones(1,m2); % make WW size of tdata
% tic
% [Pn,rd.w]=cal_psd5(Ptdata,WW,nfft,100000,0); % calculate the windowed, zero-padded FFT
% [n2,m2]=size(Ptdata2); % size of time domain matrix
% ww = KaiserBessel(n2,2.0); % calculate window
% WW=ww(:)*ones(1,m2); % make WW size of tdata
% tic
% [Pn2,rd.w]=cal_psd5(Ptdata2,WW,nfft,100000,0); % calculate the windowed, zero-padded FFT
% 
% figure(12);clf
% Pn3=Pn-Pn2; % difference
% h=imagesc(Pn3,[0 5e-8]);