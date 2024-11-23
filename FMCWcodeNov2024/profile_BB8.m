% this script profiles with the BB radar

% set the constants for this high freq oscillator
lowfreq=2; fullBW=8;
% load the settings
d=load_all_settingsBB;
% first the measurement settings
Fs=d.measure.Fs; % sample frequency
nsamptrace=d.measure.nsamptrace; % number of samples per trace
startfreq=d.measure.startfreq; stopfreq=d.measure.stopfreq; % start/stop freq for measurement
datadir=d.measure.datadir;
ntraces=d.measure.ntraces;
% next the processing settings
freqrangemin=d.process.freqrangemin; freqrangemax=d.process.freqrangemax; % min/max freq for processing
alpha=d.process.alpha; % Kaiser-Bessel parameter
nfft=d.process.nfft; % number of points in fft
ref=d.process.ref;
skycal=d.process.skycal;
% next the plot settings
v=d.plot.v; % speed in cm/s
depthmin=d.plot.depthmin; depthmax=d.plot.depthmax; % depth range
zmin=d.plot.zmin; zmax=d.plot.zmax; % psd range

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOW SET UP Analog Input
AI=analoginput('nidaq','dev1'); % input object for DAQCARD
chan=addchannel(AI,[7 5]); % add 2 channels, ramp, radar input (far from each other)
AI.Channel(1).InputRange=[0 10]; % set input range for ramp
AI.Channel(2).InputRange=[-0.25 0.25]; % set input range of radar input
%AI.Channel(3).InputRange=[-0.5 0.5]; % set input range of radar input
set(AI.Channel(1),'ChannelName','Ramp') % name each channel for displays
set(AI.Channel(2),'ChannelName','Input')
% set(AI,'TriggerType','Manual');
% set(AI,'ManualTriggerHwOn','Trigger')
set(AI,'TriggerConditionValue',0.5); % trigger at 0.1 Volts
set(AI,'TriggerType','HwAnalogChannel') % trigger on PFI0/TRIG1 - Note this is much better than channel 1
set(AI,'TriggerCondition','AboveHighLevel')
set(AI,'TriggerChannel',AI.Channel(1)) % set the trigger pin to be #1 (maybe this can be removed)
% now set measurement parameters for analog input
AI.SampleRate=Fs; % set sample freq
AI.SamplesPerTrigger=nsamptrace; % samples per trace to collect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOW SET UP Analog Output
AO=analogoutput('nidaq','dev1'); % create output object
chan2=addchannel(AO,0); % add the first output channel
set(AO.Channel(1),'ChannelName','RampOut') % name the channel
AO.SampleRate=Fs; % set sample freq
set(AO,'TriggerType','Immediate'); % specify a manual trigger (remove later)
outsamp=nsamptrace+200; %handles.measure_set.Fs*handles.measure_set.Tpl; 
freqramp=linspace(startfreq,stopfreq,outsamp); % linear frequency range
voltramp=(freqramp-lowfreq)*10/fullBW; % convert freq ramp to voltage ramp
voltramp=voltramp(1:length(voltramp)-1); % remove last sample to keep < 10 V
outsignal=[zeros(1,50) voltramp zeros(1,50)]; %  sawtooth pulse
%outsignal=[ones(1,200) zeros(1,200) voltramp linspace(max(voltramp),1,200) ones(1,200)]; %  sawtooth pulse
%outsignal=[outsignal outsignal]; % do it twice to make sure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%outsignal=[ones(1,200) zeros(1,200) 6*ones(1,1000) 7*ones(1,1000) 8*ones(1,1000) 9*ones(1,1000)];
% Lets take one trace to get a ramp sample
disp('Taking one sample trace....')
putdata(AO,outsignal')
start([AI AO]); % start both
wait([AI AO],5)
data=getdata(AI);
vdata=data(:,1);
tdata=data(:,2);
% initialize
tdata_all=zeros(nsamptrace,300);
tdata_all(:,1)=tdata;

% lets remove the sky calibration
if strcmp(skycal,'none')
    errordlg('No sky calibration used!','skycal="none"','modal')
    msky=zeros(size(tdata));
else
    load(skycal)
    if isfield(d,'tdata')
        if length(tdata)==length(d.tdata)
            msky=mean(d.tdata,2);
            disp('Removing instrumentation signals with sky cal...')
        else
            errordlg('Sky cal taken with different measurements parameters, no sky cal used!','skycal wrong size','modal')
            msky=zeros(size(tdata));
        end
    else
        errordlg('tdata does not exist, no sky cal used!','skycal not compatible','modal')
        msky=zeros(size(tdata));
    end
end
tdata=tdata-msky;

% lets find the frequencies of interest
%ind=pick_freqrange2(fullBW,lowfreq,freqrangemin,freqrangemax,vdata); % find the index of data of interest
%ind=1:length(vdata);
ind1=find(vdata>((freqrangemin-lowfreq)*10/fullBW));
ind2=find(vdata>((freqrangemax-lowfreq)*10/fullBW));
ind=ind1(1):ind2(1);
% and calculate the psd 
pTpl=length(ind)./Fs; % processed pulse length
BW=freqrangemax-freqrangemin; % processed bandwidth
% check if we need to decimate
if length(ind)>nfft
    fac=ceil(length(ind)/nfft); % factor to decimate by
    tdata=decimate(tdata(ind),fac); % decimate the data
    Fs=Fs/fac; % adjust sample frequency
else
    tdata=tdata(ind);
end
ww = KaiserBessel(length(tdata),alpha); % calculate window
[psd,w]=CAL_PSD2(tdata,ww,nfft,Fs); % calculate the windowed, zero-padded FFT
psd_dB=10*log10(psd/ref);
d=0.5*w*pTpl/(BW*1e9)*v;

% initialize
ind2=find(d>-1 & d<2500); np=length(ind2); d=d(ind2);
psd_all=zeros(np,300);
psd_all(:,1)=psd_dB(ind2);

% lets set up the plot
fh=figure;
hprof=imagesc(1,d,psd_all(:,1),[zmin zmax]) % draw first line
axis([1 20 depthmin depthmax])
set(gca,'YDir','reverse')
set(gcf,'doublebuffer','on'); % reduce plot flicker
title(datadir)

% make the stop button
hButton=uicontrol(fh,'style','togglebutton');
set(hButton,'String','Stop');
set(hButton,'Value',1)
val=1;
n=1;

% now lets continue measuring, and update plots
putdata(AO,outsignal')
while val
    n=n+1;
    try
        start([AI AO]); % start both
    catch
   %     disp('AI error!')
        stop(AI)
        putdata(AO,outsignal')
        start([AI AO]); % start both
    end        
    wait([AI AO],5)
    data=getdata(AI);
    vdata=data(:,1);
    tdata=data(:,2);
    % store new values
    tdata_all(:,n)=tdata;
    mytime(n)=now;
    % remove sky cal
    tdata=tdata-msky;

    % check if we need to decimate
    if length(ind)>nfft
        tdata=decimate(tdata(ind),fac); % decimate the data
    else
        tdata=tdata(ind);
    end
    [psd,w]=CAL_PSD2(tdata,ww,nfft,Fs); % calculate the windowed, zero-padded FFT
    psd_dB=10*log10(psd/ref);
    % store new values
    psd_all(:,n)=psd_dB(ind2);
    % update plots
    if n>20
       set(hprof,'CData',psd_all(:,(n-20):n),'XData',((n-20):n))
       axis([(n-20) n depthmin depthmax]);
    else
       set(hprof,'CData',psd_all(:,1:n),'XData',(1:n))
    end    
    drawnow
    %stop(AI)
    putdata(AO,outsignal')
    val=get(hButton,'Value');
    if n>=ntraces
        val=0
    end
end
stop([AI AO])
delete([AI AO])
% plot entire measurement
set(hprof,'CData',psd_all(:,1:n),'XData',(1:n))
axis([1 n depthmin depthmax]);
% save the measurement
[file,path]=uiputfile('*.mat','Save Measurement in File:',datadir);
if file
    depth=d; clear d;
    d.tdata=tdata_all(:,1:n);
    d.depth=d;
    d.rampsample=vdata;
    d.allset=load_all_settingsBB;
    d.mytime=mytime;
    save(file,'d')
end
clear all;


% figure(1);clf
% plot(vdata,'r')

% % lets check out the accuracy of this ramp
% x=vdata(201:(outsamp+200));
% P=polyfit((1:outsamp)',x,1);
% x2=polyval(P,(1:outsamp)');
% hold on
% plot((201:(outsamp+200))',x2,'k')
% er=x2-x;
% figure(2); clf
% plot_pdf_hist5(er);
% [F,X]=ecdf(er);
% ind=find(F<0.05);
% ind2=find(F>0.95);
% disp(['5,95% error in linear ramp: ' num2str(X(max(ind))) ' to ' num2str(X(min(ind2)))])
% 




% % get some paramters into shorter-named variables, cal. window for FFT, depth scale
% [trace_index] = pick_freqrange2(fullBW,lowfreq,freqrangemin,freqrangemax,vdata); % find the index of data of interest
% nps=length(trace_index);
% %nps=trace_index(2)-trace_index(1)+1; % number of samples to process
% ww = KaiserBessel(nps,handles.process_set.alpha); % calculate window
% nst=handles.measure_set.nsamptrace; N=handles.process_set.nfft; Fs=handles.measure_set.Fs;
% BW=handles.process_set.freqrangemax-handles.process_set.freqrangemin; % bandwidth processed
% pTpl=nps./handles.measure_set.Fs; % pulse length of processed data
% w=(0:N/2-1)/(N)*Fs; % frequencies sampled
% d=0.5*w*pTpl/(BW*1e9)*handles.plot_set.v; % approx depth [cm] 
% 
% 
% % set up the plot
% figure(3); clf; handles.rampplot=subplot(3,1,1);
% handles.ramp_h=plot(zeros(1,nps),'r'); ylabel('Output [Volts]')
% axis([1 nps 0 10])
% handles.title=title('Trace #: 1'); set(gcf,'doublebuffer','on'); % reduce plot flicker
% handles.timeplot=subplot(3,1,2); handles.time_h=plot(zeros(1,nps),'b'); xlabel('Sample #'); ylabel('Mixed Signal [Volts]')
% axis([1 nps -0.2 0.2])
% set(gcf,'doublebuffer','on'); % reduce plot flicker
% handles.freqplot=subplot(3,1,3);
% plot(ones(1,nps)*handles.plot_set.noise,'r-.'); hold on % plot noise floor
% axis([handles.plot_set.depthmin handles.plot_set.depthmax handles.plot_set.noise-10 50]); 
% handles.freq_h=plot(zeros(1,nps),'g'); 
% set(gcf,'doublebuffer','on'); % reduce plot flicker
% %axis([0 300 0 2e-5])
% ylabel('magnitude [Watts/Hz]'); xlabel('Approx Depth [cm]')
% handles.meantrace=zeros(nps,2);
% %tdata=zeros(nst,handles.measure_set.ntraces);
% %vdata=zeros(nst,handles.measure_set.ntraces);
% 
% % if the parameters are either (N=1200,Fs=60kHz or N=3500,Fs=175kHz)
% %   then use our sky calibration
% if strcmp(handles.process_set.skycal,'none')
%     if ((handles.measure_set.Fs==60000) & (handles.measure_set.nsamptrace==1200))
%         load([pre_defaults 'skycal_testFMCW_1200'])
%         msky=mean(d.tdata,2); % mean sky cal
%         disp('Using sky calibration file: skycal_testFMCW_1200')
%         axes(handles.timeplot); axis([1 nps -0.05 0.05])
%     elseif ((handles.measure_set.Fs==175000) & (handles.measure_set.nsamptrace==3500))
%         load([pre_defaults 'skycal_testFMCW_3500'])
%         msky=mean(d.tdata,2); % mean sky cal
%         disp('Using sky calibration file: skycal_testFMCW_3500')
%         axes(handles.timeplot); axis([1 nps -0.05 0.05])
%     else
%         disp('no sky calibration performed')
%         msky=zeros(length(tdata));
%         axes(handles.timeplot); axis([1 nps 0 0.2])
%     end
% else
%     load(handles.process_set.skycal)
%     msky=mean(d.tdata,2);
% end
% d=0.5*w*pTpl/(BW*1e9)*handles.plot_set.v; % approx depth [cm] 
% 
% putdata(AO,outsignal')
% tic
% for i=1:handles.measure_set.ntraces
%     start([AI AO]); % start both
%   %  trigger(AO); % trigger the analog output
%   %  while strcmp(AI.running,'On') | strcmp(AO.running,'On')% wait until analog input data is aquired, and output finishes
%   %  end
%     wait([AI AO],5)
%     data=getdata(AI); 
%     if length(data(:,2))==length(msky)
%        tdata=data(trace_index,2)-msky(trace_index);
%        %tdata=tdata(trace_index);
%     elseif length(data(trace_index,2)==length(msky)) % guess that msky was recorded with just the trace_index values
%        tdata=data(trace_index,2)-msky(1:length(trace_index));
%     else % otherwise, no sky cal 
%         tdata=data(trace_index,2);
%     end
%    % tdata_all(:,i)=tdata;
%     vdata=data(:,1);
%     % plot input to oscillator
%     axes(handles.rampplot); 
%     set(handles.ramp_h,'YData',vdata(trace_index)); % update ramp plot
%     % % plot time domain data
%     axes(handles.timeplot); % 
%     set(handles.time_h,'YData',tdata); % update time plot
%     % process time domain data, and plot resulting frequency data
%     [psd,w]=cal_psd2(tdata,ww,N,Fs); % calculate the windowed, zero-padded FFT
%     %psd_dB = cal_dB2(psd,40);
%     psd_dB=real(10*log(psd./5e-7)); % PSD in dB units, real part,relative to sphere
%     axes(handles.freqplot); 
%     set(handles.freq_h,'YData',psd_dB,'XData',d);   % cal. psd with respect to max reflection (surface?)
%     drawnow % update the plot
%     set(handles.title,'string',['Trace #: ' num2str(i)]); % title with trace number
%     putdata(AO,outsignal')
% end
% toc
% stop([AI AO])
% delete([AI AO])
% clear AI AO
% %clear all
% %save skycal_testFMCW_3500 tdata_all