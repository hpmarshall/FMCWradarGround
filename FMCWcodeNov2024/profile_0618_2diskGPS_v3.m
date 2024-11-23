% this script tests the BB radar

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

% change directory
mydir=input('data directory?','s')
mkdir(mydir)
cd(mydir)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOW SET UP Analog Input
AI=analoginput('nidaq','dev1'); % input object for DAQCARD
chan=addchannel(AI,[6 4 7]); % add 2 channels, ramp, radar input (far from each other)
AI.Channel(1).InputRange=[0 10]; % set input range for ramp
AI.Channel(2).InputRange=[-1 1]; % set input range of radar input
AI.Channel(3).InputRange=[-1 1]; % set input range of radar input
%AI.Channel(4).InputRange=[-0.1 0.1]; % set input range of radar input
set(AI.Channel(1),'ChannelName','Ramp') % name each channel for displays
set(AI.Channel(2),'ChannelName','HH-pol')

set(AI,'TriggerConditionValue',0.5); % trigger at 0.1 Volts
set(AI,'TriggerType','HwAnalogChannel') % trigger on PFI0/TRIG1 - Note this is much better than channel 1
set(AI,'TriggerCondition','AboveHighLevel')
set(AI,'TriggerChannel',AI.Channel(1)) % set the trigger pin to be #1 (maybe this can be removed)
%set to log to disk
set(AI,'LoggingMode','Disk')
set(AI,'LogFileName','file00.daq')
set(AI,'LogToDiskMode','Index')
% now set measurement parameters for analog input
AI.SampleRate=Fs; % set sample freq
AI.SamplesPerTrigger=9000; %nsamptrace*20; % samples per trace to collect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NOW SET UP Analog Output
AO=analogoutput('nidaq','dev1'); % create output object
chan2=addchannel(AO,1); % add the first output channel
set(AO.Channel(1),'ChannelName','RampOut') % name the channel
AO.SampleRate=Fs; % set sample freq
set(AO,'TriggerType','Immediate'); % specify a manual trigger (remove later)
%set(AO,'repeatoutput',2)
outsamp=nsamptrace-500; %handles.measure_set.Fs*handles.measure_set.Tpl; 
freqramp=linspace(startfreq,stopfreq,outsamp); % linear frequency range
voltramp=(freqramp-lowfreq)*10/fullBW; % convert freq ramp to voltage ramp
voltramp=voltramp(1:length(voltramp)-1); % remove last sample to keep < 10 V
%voltramp=[voltramp fliplr(voltramp)];
voltramp=[voltramp zeros(1,200)];
V=voltramp'*ones(1,7);
outsignal=[ones(1,200) zeros(1,200) V(:)' ones(1,200)]; %  sawtooth pulse
%outsignal=[outsignal outsignal]; % do it twice to make sure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Lets take one trace to get a ramp sample
disp('Taking one sample trace....')
putdata(AO,outsignal')
start([AI AO]); % start both
wait([AI AO],5)

% lets set up the plot
fh=figure;
%subplot(2,1,1)
htext=title('0','fontsize',18)
% subplot(2,1,2)
% plot(d,psd_HH); hold on
% plot(d,psd_HV,'r')
% htext=title('psd');
% make the stop button
hButton=uicontrol(fh,'style','togglebutton');
set(hButton,'String','Stop');
set(hButton,'Value',1)
val=1;
n=1;
% now lets continue measuring, and update plots
putdata(AO,outsignal')
% disp('set up gps')
% gps=serial('COM1')
% % set any protocols
% set(gps,'BaudRate',19200,'DataBits',8,'StopBits',1,'Parity','none','readasyncmode','manual');
% fopen(gps);
% S=fscanf(gps,'%s')
% if length(S)>=16
%     hr=S(8:9);
%     min=S(10:11);
%     second=S(12:16)
%     second2=num2str(str2num(S(12:16))+0.07)
%     eval(['!time ' hr ':' min ':' second2])
%     disp('CPU set to UTC time')
% else
%     disp('no gps fix')
%     beep
%     beep
%     S=num2str(zeros(1,16))
% end
% fid=fopen('GPSdata.txt','wt')
disp('ok, now record to disk')
while val
    n=n+1;
    try
        start([AI AO]); % start both
    catch
        disp('AI error!')
        stop([AI AO])
        putdata(AO,outsignal')
        start([AI AO]); % start both
    end        
    wait([AI AO],25)    
%    S=fgets(gps);
%     if length(S)>15
%         sec=str2num(S(12:16));
%         set(htext,'string',['trace:' num2str(n) ', gps:' S(12:16) '!'])
%         if rem(sec,5)==0
%             fprintf('GPS time: %12.4f\n', sec)
%         end
%         filen=num2str(n);
%         fprintf(fid,'%s,%s\n',filen,S);
%     end
    beep
    drawnow
    %stop(AI)
    putdata(AO,outsignal')
    val=get(hButton,'Value');
    if n>=ntraces
        val=0
    end
    disp(num2str(n))
    pause(60*5)
end
stop([AI AO])
delete([AI AO])
fclose(fid); fclose(gps)
clear all;
cd ..
