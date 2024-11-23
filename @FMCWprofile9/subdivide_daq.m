function obj = subdivide_daq(obj)
% SUBBDIVIDE_DAQ takes series of continuous voltage ramps and subdivides
% HPM 01/15/07, 04/26/08, 07/24/10
%   NOTE: now FOR loop for trace partioning removed, much faster!
% INPUT: obj. = data directory
%             vrange = [min max] voltage range to use
% OUTPUT: T = smoothed time domain matrix
%               Fs = sample frequency on smoothed data
%    CPUtime = serial date for each trace

% defaults
if isempty(obj.P.vrange)
    obj.P.vrange=(obj.P.frange-min(obj.M.frange))*10./(diff(obj.M.frange)); % calculate vrange
end
%% First load one file to determine size
D=dir([obj.data_dir '*.mat']);
filename=[obj.data_dir D(1).name]; % filename
load(filename); % get some info
Fs=100000; % sample rate [Hz]
ramp=Data(:,1); % voltage ramp
i1=find(ramp>=obj.P.vrange(1) & ramp<=obj.P.vrange(2)); % data in range
i2=diff(i1); i3=find(i2>5); % find breaks between traces
S=[i1(i3(1:end-1)+1) i1(i3(2:end))]; % start and end of each trace
dS=diff(S,1,2); ind= dS>50; S=S(ind,:); % remove traces caused by voltage glitch
TL=min(diff(S,1,2))+1; % minimum trace length
nT=length(S); % number of traces per file

%% loop over all requested files
TDATA=zeros(TL,nT*length(obj.P.files))*NaN;
Ct=zeros(1,nT*length(obj.P.files))*NaN;
for n=1:length(obj.P.files)
    filename=[obj.data_dir D(obj.P.files(n)).name]; % filename
    load(filename)
    Fs=100000; % sample frequency
    ramp=Data(:,1); % voltage ramp
    i1=find(ramp>=obj.P.vrange(1) & ramp<=obj.P.vrange(2)); % data in range
    i2=diff(i1); i3=find(i2>5); % find breaks between traces
    S=[i1(i3(1:end-1)+1) i1(i3(2:end))]; % start and end of each trace
    dS=diff(S,1,2); ind= dS>50; S=S(ind,:); % remove traces caused by voltage glitch
    TL=min(diff(S,1,2))+1; % minimum trace length
    tdata=Data(:,obj.P.channel); % time domain data - grab specified channel
    x=0:(TL-1); % vector of delta S
    X=ones(length(S),1)*x; % matrix of increments
    IND=(S(:,1)*ones(1,TL)+X)'; % index of all traces, 1 column for each trace
    if max(IND)<=length(tdata) % if we have a complete trace
        T=tdata(IND); % time domain data, subdivided for each trace
        CPUtime=datenum(AbsTime)+(S(:,1)+TL/2)/Fs/60/60/24; % absolute time [days] for trace, put time at center of trace
        t1=(n-1)*nT+1;
        nT=length(S); % size of S
        t2=t1+nT-1;
        [n5,~]=size(T);
        TDATA(1:n5,t1:t2)=single(T); % store in tdata matrix
        Ct(t1:t2)=CPUtime; % store
    end
end
%I2=isfinite(TDATA(1,:));
obj.TDATA=TDATA; %(:,I2);
obj.CPUtime=Ct; %(I2);
obj.M.Fs=Fs;
obj.Tpl=TL./obj.M.Fs; % pulse length

    


