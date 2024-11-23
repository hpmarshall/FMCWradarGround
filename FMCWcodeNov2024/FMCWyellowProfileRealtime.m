%% FMCW gray box (6-18 GHz)
s = daq.createSession('ni') % set up an NI session
dinfo  = daq.getDevi    ces; % get info about devices
s.Rate=80000;
% add the Analog Input channels and configure
ch=addAnalogInputChannel(s,dinfo.ID,[0 1 3],'Voltage') % add channels 0 and 1
ch(2).Range=[-10 10];
ch(3).Range=[-10 10];
% add the Analog Output channels and configure
addAnalogOutputChannel(s,dinfo.ID, 0, 'Voltage')% add output channels 0 and 1
%% radar specific analog output
fullBW=12;lowfreq=6; % oscillator bandwidth and minimum frequency
startfreq=12; stopfreq=18; % start/stop freq for measurement
freqrangemin=12;freqrangemax=18; % start/stop freq for processing
Fs=s.Rate; % store sample frequency
nfft=2^10; % number of fft points
alpha=2; % fft parameter
ref=1e-5; % reference PSD
v=2.3e10; % velocity rough estimate
zmin=-80; zmax=-20; % PSD range in dB to plot
depthmin=0;depthmax=500; % min/max depth to plot
ntraces=300; % max number of traces
voltrange=([startfreq stopfreq]-lowfreq)*10/fullBW; % calculate voltage range
data0 = [linspace(voltrange(1),voltrange(2),1000) linspace(voltrange(2),voltrange(1),1000)]';
%data1 = sin(linspace(0, 2*pi*10, 500001))';
data0(end) = [];
%data1(end) = [];
outsignal=[data0]; %,data1];
%outsignal=repmat([data0], 3000, 1);
clear data0
queueOutputData(s,outsignal);
disp('take one trace...')
[Data,~,AbsTime]=s.startForeground;
vdata=Data(:,2);
tdata_HH=Data(:,1);
tdata_HV=Data(:,3);
% initialize
nsamptrace=length(outsignal)
tdata_all_HH=zeros(nsamptrace,ntraces);
tdata_all_HV=zeros(nsamptrace,ntraces);
tdata_all_HH(:,1)=tdata_HH;
tdata_all_HV(:,1)=tdata_HV;
[file,path]=uiputfile('*.mat','Sky Calibration File:','C:\D_DRIVE\FMCW2016\GREENLAND2016\s1.mat');
skycal=[path file];  %'IQDATA\s1';
% lets remove the sky calibration
if length(skycal)<3
    errordlg('No sky calibration used!','skycal="none"','modal')
    mskyHH=zeros(size(tdata_HH));
    mskyHV=zeros(size(tdata_HV));
else
    load(skycal)
    if isfield(d,'tdata_HH') && isfield(d,'tdata_HV')
        if length(tdata_HH)==length(d.tdata_HH)
            mskyHH=mean(d.tdata_HH,2);
            mskyHV=mean(d.tdata_HV,2);
            disp('Removing instrumentation signals with sky cal...')
        else
            errordlg('Sky cal taken with different measurements parameters, no sky cal used!','skycal wrong size','modal')
            mskyHH=zeros(size(tdata_HH));
            mskyHV=zeros(size(tdata_HV));
        end
    else
        errordlg('tdata_HH and/or tdata_HV do not exist, no sky cal used!','skycal not compatible','modal')
        mskyHH=zeros(size(tdata_HH));
        mskyHV=zeros(size(tdata_HV));
    end
end
tdata_HH=tdata_HH-mskyHH;
tdata_HV=tdata_HV-mskyHV;


ind=pick_freqrange2(fullBW,lowfreq,freqrangemin,freqrangemax,vdata); % find the index of data of interest

% and calculate the psd 
pTpl=length(ind)./Fs; % processed pulse length
BW=freqrangemax-freqrangemin; % processed bandwidth
% check if we need to decimate
if length(ind)>nfft
    fac=ceil(length(ind)/nfft); % factor to decimate by
    tdata_HH=decimate(tdata_HH(ind),fac); % decimate the data
    tdata_HV=decimate(tdata_HV(ind),fac);
    Fs=Fs/fac; % adjust sample frequency
else
    tdata_HH=tdata_HH(ind);
    tdata_HV=tdata_HV(ind);
end
ww = KaiserBessel(length(tdata_HH),alpha); % calculate window
[psd_HH,w]=cal_psd2(tdata_HH,ww,nfft,Fs); % calculate the windowed, zero-padded FFT
[psd_HV,w]=cal_psd2(tdata_HV,ww,nfft,Fs); % calculate the windowed, zero-padded FFT
psd_HH_dB=10*log(psd_HH/ref);
psd_HV_dB=10*log(psd_HV/ref);
d=0.5*w*pTpl/(BW*1e9)*v;

% initialize
ind2=find(d>-1 & d<500); np=length(ind2); d=d(ind2);
psd_all_HH=zeros(np,ntraces);
psd_all_HV=zeros(np,ntraces);
psd_all_HH(:,1)=psd_HH_dB(ind2);
psd_all_HV(:,1)=psd_HV_dB(ind2);


% lets set up the plot
fh=figure;
subplot(2,1,1)
hprofHH=imagesc(1,d,psd_all_HH(:,1),[zmin zmax]) % draw first line
colorbar
axis([1 20 depthmin depthmax])
set(gca,'YDir','reverse')
set(gcf,'doublebuffer','on'); % reduce plot flicker
title('HH polarization')
subplot(2,1,2)
hprofHV=imagesc(1,d,psd_all_HV(:,1),[zmin zmax]) % draw first line
colorbar
axis([1 20 depthmin depthmax])
set(gca,'YDir','reverse')
set(gcf,'doublebuffer','on'); % reduce plot flicker
title('HV polarization')
% make the stop button
hButton=uicontrol(fh,'style','togglebutton');
set(hButton,'String','Stop');
set(hButton,'Value',1)
val=1;
n=1;

% now lets continue measuring, and update plots
queueOutputData(s,outsignal);
disp('start profiling...')

while val
    n=n+1;
    %try
        [Data,~,AbsTime]=s.startForeground;
    %catch
    %    disp('AI error!')
    %    stop(s)
    %    queueOutputData(s,outsignal);
    %    [Data,~,AbsTime]=s.startForeground;
    %end
    vdata=Data(:,2);
    tdata_HH=Data(:,1);
    tdata_HV=Data(:,3);
    % store new values
    tdata_all_HH(:,n)=tdata_HH;
    tdata_all_HV(:,n)=tdata_HV;
    % remove sky cal
    tdata_HH=tdata_HH-mskyHH;
    tdata_HV=tdata_HV-mskyHV;

    % check if we need to decimate
    if length(ind)>nfft
        tdata_HH=decimate(tdata_HH(ind),fac); % decimate the data
        tdata_HV=decimate(tdata_HV(ind),fac);
    else
        tdata_HH=tdata_HH(ind);
        tdata_HV=tdata_HV(ind);
    end
    [psd_HH,w]=cal_psd2(tdata_HH,ww,nfft,Fs); % calculate the windowed, zero-padded FFT
    [psd_HV,w]=cal_psd2(tdata_HV,ww,nfft,Fs); % calculate the windowed, zero-padded FFT
    psd_HH_dB=10*log(psd_HH/ref);
    psd_HV_dB=10*log(psd_HV/ref);
    % store new values
    psd_all_HH(:,n)=psd_HH_dB(ind2);
    psd_all_HV(:,n)=psd_HV_dB(ind2);    
    % update plots
    if n>20
       subplot(2,1,1)
       set(hprofHH,'CData',psd_all_HH(:,(n-20):n),'XData',((n-20):n))
       axis([(n-20) n depthmin depthmax]);
       subplot(2,1,2)
       set(hprofHV,'CData',psd_all_HV(:,(n-20):n),'XData',((n-20):n))
       axis([(n-20) n depthmin depthmax]);
    else
       set(hprofHH,'CData',psd_all_HH(:,1:n),'XData',(1:n))
       set(hprofHV,'CData',psd_all_HV(:,1:n),'XData',(1:n))
    end    
    drawnow
    %stop(AI)
    queueOutputData(s,outsignal);
    val=get(hButton,'Value');
    if n>=ntraces
        val=0
    end
end
%stop([AI AO])
%delete([AI AO])
s.stop;
% plot entire measurement
subplot(2,1,1)
set(hprofHH,'CData',psd_all_HH(:,1:n),'XData',(1:n))
axis([1 n depthmin depthmax]);
set(hprofHV,'CData',psd_all_HV(:,1:n),'XData',(1:n))
subplot(2,1,2)
axis([1 n depthmin depthmax]);
% save the measurement
[file,path]=uiputfile('*.mat','Save Measurement in File:','C:\D_DRIVE\FMCW2016\GREENLAND2016\');
if file
    depth=d; clear d;
    d.tdata_HH=tdata_all_HH(:,1:n);
    d.tdata_HV=tdata_all_HV(:,1:n);
    d.depth=d;
    d.rampsample=vdata;
%    d.allset=load_all_settingsXP;
    save(file,'d')
end
clear all;