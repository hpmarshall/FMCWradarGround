%function FMCWgrayboxProfile2Disk(datadir)
%if nargin<1
    datadir=input('Please enter directory name with no \\ and press return \n','s')
%end
mkdir(datadir)
s = daq.createSession('ni') % set up an NI session
dinfo  = daq.getDevices; % get info about devices
s.Rate=100000
% add the Analog Input channels and configure
ch=addAnalogInputChannel(s,dinfo(1).ID,[0 1 2 3 4],'Voltage'); % add channels 0 and 1
ch(2).Range=[-1 1];
ch(3).Range=[-1 1];
ch(4).Range=[-1 1];
ch(5).Range=[-1 1];

% add the Analog Output channels and confyigure
addAnalogOutputChannel(s,dinfo(1).ID, 0, 'Voltage'); % add output channels 0 and 1
%%
%% radar specific analog output
fullBW=12;lowfreq=6; % oscillator bandwidth and minimum frequency
startfreq=6; stopfreq=18; % start/stop freq for measurement
freqrangemin=6;freqrangemax=18; % start/stop freq for processing
Fs=s.Rate; % store sample frequency
nfft=2^10; % number of fft points
alpha=2; % fft parameter
ref=1e-5; % reference PSD
v=2.3e10; % velocity rough estimate
zmin=-80; zmax=-20; % PSD range in dB to plot
depthmin=0;depthmax=300; % min/max depth to plot
ntraces=300; % max number of traces
voltrange=([startfreq stopfreq]-lowfreq)*10/fullBW; % calculate voltage range
data0 = [linspace(voltrange(1),voltrange(2),1000) linspace(voltrange(2),voltrange(1),1000)]';
data0(end) = [];
outsignal=data0; 
outsignal=repmat([data0], 1000, 1); % repeat ramp 3000 times
clear data0
%% first a test run:
disp('short test, standby...')
queueOutputData(s,outsignal(1:5000));
s
[Data,~,AbsTime]=s.startForeground;
Data=single(Data);
figure(1);subplot(211)
plot(Data(:,1)); title('Voltage triangle wave, 0-10V')
subplot(212)
plot(Data(:,2:3)); title('Time-domain FMCW raw data')
disp('if OK, press any key.  If not, CNTL-C to kill')
pause
disp('checking voltage ranges for analog input:')
Dtmin=min(Data(:,2:3));
Dtmax=max(Data(:,2:3));
ch2range=[Dtmin(1) Dtmax(1)];
ch3range=[Dtmin(2) Dtmax(2)];
if max(abs(ch2range))>1
    ch(2).Range=[-5 5];
    if max(abs(ch2range))>5
        ch(2).Range=[-10 10];
    end
end
if max(abs(ch3range))>1
    ch(3).Range=[-5 5];
    if max(abs(ch3range))>5
        ch(3).Range=[-10 10];
    end
end

% %% set up GPS writting to file
% GPSfile=[datadir '\GPS' datestr(now,'yymmdd') '_f1.txt']
% GPSfile2=[datadir '\GPS' datestr(now,'yymmdd') '_GGA.txt'];
% fid=fopen(GPSfile2,'a');
% delete(instrfindall); % kill any existing COM connections
% s1=serial('COM1');
% s1.BaudRate=115200;
% %GPSfile=input('enter name for GPS file\n','s');
% s1.BytesAvailableFcnMode='terminator';
% s1.BytesAvailableFcn={@writeGPS,s1,fid};
% s1.RecordMode='index';
% s1.RecordDetail='verbose';
% s1.RecordName=GPSfile;
% fopen(s1);
while 1 % run forever
    tic
    queueOutputData(s,outsignal);
   % record(s1,'on')
    disp('running, please wait 2 min...')
    [Data,~,AbsTime]=s.startForeground;
    Data=single(Data);
    datafile=[datadir '\FMCWg' datestr(AbsTime,'yymmdd-HHMMSS')]
    save(datafile,'Data','AbsTime')
   % record(s1,'off')
    toc
    beep
end

% function writeGPS(obj,event,s1)
% % reads a line from serial object s and writes to file fid
% GPSstring=fgetl(s1);
% if strcmp(S(1:6),'$GNGGA')
%     GPSstring
% end