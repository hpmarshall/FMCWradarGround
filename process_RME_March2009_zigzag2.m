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
%CP=pwd;
%cd([codedisk 'D_DRIVE/MATLAB/BIN']);

datadisk='/Users/hpmarshall/';
codedisk='/Users/hpmarshall/';

%cd(['/Users/hpmarshall/D_DRIVE/MATLAB/BIN']);
%startup_hpm % run my startup file to define paths, etc
%cd(CP) % return to original directory
%%
rd=FMCWprofile8; % make a FMCW profile object
rd.data_dir=[datadisk 'D_DRIVE/FMCW_TESTS/WINTER09/REYNOLDS031909/']; % raw data location
rd.proc_dir=[codedisk 'D_DRIVE/PROJECTS/RME/PROC3/']; % location to store processed results
rd.proc_subdir=1; %process the first 3 directories in rd.datadir
rd.location='RME'; % location name
%% NOTE: GPS parameters below set by default in @GPS/GPS.m
%rd.G.maxHDOP=2; % minimum HDOP to use 
%rd.G.dtSkyCal=5; % [sec] time difference between sky calibration

rd=get_GPS_all(rd); % get all the GPS data recorded in rd.datadir

%% set the processing parameters
rd.M.frange=[2 10]; % low freq osc used for this survey
rd.P.files=1:500;
rd.P.Ncores=1; % use 1 CPU core
rd.P.frange=[2.4 9.6]; % process away from endpoints to reduce noise
rd.P.GPUflag=0; % process on the GPU
rd.P.channel=1; % time domain signal is on this raw data channel
rd.P.nfft=2^14; % number of points in FFT
rd.P.batchsize=50;  % batch size 
rd.P.ndaq=500; % store results of 2000 daq files together
rd.P.maxP=rd.P.nfft/4; % save upper 1/2 of data from PDATA
rd.P.overwrite=1; % overwrite previous results
% set the post-processing parameters
rd.P2.MedFiltSize=[]; % size of median filtering window
rd.P2.NoiseRange=[]; % noise range for normalization
rd.P2.gain_window=[]; % window size of 100 samples for AGC
% set the sky calibration removal parameters
rd.S.SkyCalRange=[]; % range for picking sky calibration in 
rd.S.skythresh=[]; %7e-7; % threshold for finding sky calibration locations
tic
rd=process_tdata_all(rd); % process the radar data
toc