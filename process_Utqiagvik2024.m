% process_RME_March2009
% this script requires m_map
% choose directory and set parameters

% CPU=computer; % check to see which computer I'm running on
% if strcmp(CPU,'MACI64')
%     disp('running on ice')
%     datadisk='/Volumes/data2/';
%     codedisk='/Volumes/data1/';
% elseif strcmp(CPU,'GLNXA64')
%     disp('running on avalanche')
%     pre='/data3/';
%     pre2='/data/';
% end
% CP=pwd;
% cd([codedisk 'D_DRIVE/MATLAB/BIN']);
% %cd(['/Users/hpm/D_DRIVE/MATLAB/BIN']);
% startup_hpm % run my startup file to define paths, etc
% cd(CP) % return to original directory
%%
%datadisk='/data2/';
datadisk='/Users/hpmarshall/';
codedisk='/Users/hpmarshall/';
%datadisk='/data2/'
%codedisk='/data2/'
rd=FMCWprofile9; % make a FMCW profile object
rd.data_dir=[datadisk 'DATA_DRIVE/Utqiagvik2024/20240417/FMCWradar/utq20240417shore2tent2/']; % raw data location
rd.proc_dir=[codedisk 'DATA_DRIVE/Utqiagvik2024/20240417/FMCWradar/utq20240417shore2tent2/PROC/']; % location to store processed results
rd.proc_subdir=1; %[2 3]; %1:length(rd.subdir); %process the first 3 directories in rd.datadir
rd.location='Utqiagvik'; % location name
%% NOTE: GPS parameters below set by default in @GPS/GPS.m
%rd.G.maxHDOP=2; % minimum HDOP to use 
%rd.G.dtSkyCal=5; % [sec] time difference between sky calibration

%rd=get_GPS_all(rd); % get all the GPS data recorded in rd.datadir

%% set the processing parameters
rd.M.frange=[4 18]; % low freq osc used for this survey
rd.P.Ncores=1; % use 1 CPU core
rd.P.frange=[7 17]; % process away from endpoints to reduce noise
rd.P.GPUflag=0; % process on the GPU
rd.P.channel=2; % time domain signal is on this raw data channel
rd.P.nfft=2^14; % number of points in FFT
rd.P.batchsize=10;  % batch size 
rd.P.ndaq=10; % store results of 2000 daq files together
rd.P.maxP=rd.P.nfft; % save all %%upper 1/2 of data%% from PDATA
rd.P.overwrite=1; % overwrite previous results
rd.P.files=1:10; %; %1:100;
% set the post-processing parameters
rd.P2.MedFiltSize=[]; %[4 4]; % size of median filtering window
rd.P2.NoiseRange=[]; %[1 150]; % noise range for normalization
% rd.P2.gain_window=100; % window size of 100 samples for AGC
% set the sky calibration removal parameters
%rd.S.SkyCalRange=[300 900]; % range for picking sky calibration in 
%rd.S.skythresh=2e-8; % threshold for finding sky calibration locations
%%
tic
rd=process_tdata_all(rd); % process the radar data
toc
