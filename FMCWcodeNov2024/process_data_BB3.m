function [psd_dB,depth,w,pTpl,BW] = process_data_BB(varargin)
% processes data from the BroadBand (2-10 GHz) radar
% INPUT: d = measurement,processing,plot settings
%           NOTE=if not specified, they are loaded from the current directory
% OUTPUT: psd_dB = power spectral density in dB relative to d.process.ref
%         depth  = depth scale
%             w  = frequency [Hz] corresponding to psd_dB
%          pTpl  = pulse length [s] of signal
%            BW  = bandwidth [GHz] of signal

if nargin<1
    d=load_all_settingsBB;
else
    d=varargin{1};
end

lowfreq=2; fullBW=8;
% load the settings
% first the measurement settings
Fs=d.measure.Fs; % sample frequency
nsamptrace=d.measure.nsamptrace; % number of samples per trace
startfreq=d.measure.startfreq; stopfreq=d.measure.stopfreq; % start/stop freq for measurement
% next the processing settings
freqrangemin=d.process.freqrangemin; freqrangemax=d.process.freqrangemax; % min/max freq for processing
alpha=d.process.alpha; % Kaiser-Bessel parameter
nfft=d.process.nfft; % number of points in fft
ref=d.process.ref;
skycal=d.process.skycal;
datadir=d.process.datadir;
% next the plot settings
v=d.plot.v; % speed in cm/s
depthmin=d.plot.depthmin; depthmax=d.plot.depthmax; % depth range
zmin=d.plot.zmin; zmax=d.plot.zmax; % psd range
tmin=d.plot.tmin; tmax=d.plot.tmax; % psd range


% load the data
disp('loading data...')
load(datadir)
[n,m]=size(d.tdata);
% lets remove the sky calibration
if strcmp(skycal,'none')
    errordlg('No sky calibration used!','skycal="none"','modal')
    msky=zeros(n,m);
else
    sky=load(skycal)
    if isfield(sky.d,'tdata')
        if length(d.tdata)==length(sky.d.tdata)
            disp('Removing instrumentation signals with sky cal...')
            msky=mean(sky.d.tdata,2)*ones(1,m);
        else
            errordlg('Sky cal taken with different measurements parameters, no sky cal used!','skycal wrong size','modal')
                msky=zeros(n,m);
        end
    else
        errordlg('tdata does not exist, no sky cal used!','skycal not compatible','modal')
        msky=zeros(n,m);
    end
end
tdata=d.tdata-msky;

% lets find the frequencies of interest
disp('find frequencies of interest, filter...')
%ind=pick_freqrange2(fullBW,lowfreq,freqrangemin,freqrangemax,d.rampsample); % find the index of data of interest

vdata=d.rampsample;
ind1=find(vdata>((freqrangemin-lowfreq)*10/fullBW));
ind2=find(vdata>((freqrangemax-lowfreq)*10/fullBW));
ind=ind1(1):ind2(1);

% and calculate the psd 
disp('calculate windowed, zero-padded FFT...')
pTpl=length(ind)./Fs; % processed pulse length
BW=freqrangemax-freqrangemin; % processed bandwidth
% check if we need to decimate
if length(ind)>nfft
    fac=ceil(length(ind)/nfft); % factor to decimate by
    Fs=Fs/fac; % adjust sample frequency
    for p=1:m
        tdata(:,p)=decimate(tdata(ind,p),fac); % decimate the data
    end
else
    tdata=tdata(ind,:);
end
[p2,q2]=size(tdata);
ww = KaiserBessel(p2,alpha); % calculate window
WW=ww(:)*ones(1,m); % make WW size of tdata
[psd,w]=cal_psd2(tdata,WW,nfft,Fs); % calculate the windowed, zero-padded FFT
psd_dB=10*log10(psd./ref);
depth=0.5*w*pTpl/(BW*1e9)*v;

% now plot the result
disp('Plot result...')
figure;
imagesc((1:m),depth,psd_dB,[zmin zmax]) % draw first line
if tmax==inf
    tmax=m;
end
axis([tmin tmax depthmin depthmax])
set(gca,'YDir','reverse')
title(datadir)

% save processed data
% handles.psd_dB=psd_dB;
% handles.w=w; handles.pTpl=pTpl; handles.BW=BW;
% handles.depth=depth;
% guidata(hObject, handles);