classdef FMCWprofile6
    % HPM 07/24/10
    % this class is for FMCW measurements
    % rd=FMCWprofile(location,data_dir,inc_angle)
    % this class adds GPU functionality
    properties
        location = ' '; % description of profile location
        data_dir = ' '; % data directory or file to process
        proc_dir = ' '; % processed data directory
        inc_angle = 0; % incidence angle of the measurement
        vrange=[0.5 9.5]; % voltage range sent to oscillator
        frange % frequency range measured (oscillator dependant)
        files=1:10; % files to process
        TDATA % time domain matrix
        filenumber % radar filenumber for each trace, for GPS interpolation
        CPUtime % CPU time for each trace
        Fs % sample frequency
        PDATA % frequency domain matrix
        w % frequency differences
        Tpl % pulse length
        TWT % two-way travel time
        xyz_GPS % xyz positions from GPS
        FEFN % false easting, false northing for plotting
        GPStime % GPS time from GPS file
        GPSrtrace % radar filenumber associated with each GPS position
        GPSdata % all GPS data from GPS file
        CPUtime_GPS % CPU time associated with each GPS position
        xyz_radar % xyz position for each radar file
        xyz_radar_trace % xyz position for each radar trace
        GPUflag=0; % 0=run FFT on CPU, 1=run FFT on GPU
        ProfileTraces % index to traces during profiling
        SkycalTraces % index to traces during sky calibration
        skythresh % threshold for locating sky calibration
        nfft % number of points in FFT
        batchsize % number of files in a batch
        mSky % mean sky calibration measurement
        Isurf % index to surface locations
        surfthresh % threshold for locating surface reflections
        MedFiltSize % size of median filter (index) to apply during "filter_normalize"
        NoiseRange % index range for normalization to noise
        SkyCalRange % index range for locating sky calibration measurements
        GPSbuffer % [start stop] number of traces to remove at beginning and end of profile that have bad GPS
        DCcoupling % index range at top of profile to remove before finding surface (caused by DC coupling)
        ColorScale % [min max] amplitude range for plotting image
        DepthRange % [above below] index range above and below surface pick to keep
        SurfMax % max index for surface pick
        Ncores % number of cores to use for processing with parallel toolbox
        Gthresh % threshold for ground picks
        Gmin % minimum index for ground picks
        Iground % index to ground picks
        channel % FMCW channel to use (1 or 2, for co/cross pol)
        gain_window % [samples] smoothing window to use for gain
        smooth_x % easting locations to provide smoothed estimate
        smooth_y % northing locations for smoothed estimate
        smooth_window % [m] window size for smoothing image
        subdir % list of subdirectory names
    end
    properties (Dependent = true, SetAccess = private)
        date
        daqfiles
    end

    methods
        % constuctor function
        function rd=FMCWprofile5(location,data_dir,inc_angle)
            if nargin==0
                rd.location=' ';
                rd.data_dir=' ';
                rd.inc_angle=0;
            end
            if nargin>0
                rd.location=location;
                rd.data_dir=data_dir;
                rd.inc_angle=inc_angle;
            end
        end
        % get daqfiles function
        function df=get.daqfiles(obj)
            D=dir([obj.data_dir '*.daq']); % grab all daq files
            df=zeros(1,length(D));
            for n=1:length(D)
                [~,F]=fileparts(D(n).name);
                df(n)=str2double(F(6:end)); % get file number
            end
        end
        % get date function
        function ad=get.date(obj)
            [~,~,a]=daqread([obj.data_dir 'file0' num2str(min(obj.daqfiles)) '.daq']); % get date for first daq file
            ad=a(1:3);
        end
        
        obj=subdivide_daq(obj) % function to grab time domain data       
        obj=process_tdata(obj) % function to perform windowed, zero-padded FFT to time domain data  
        obj=process_tdata_all(obj) % function to perform windowed, zero-padded FFT on all subdirectories
        obj=plot_image(obj) % function to plot an image of the processed data       
        obj=get_GPS(obj) % function to get the GPS coordinates in one directory
        obj=get_GPS_all(obj) % function to get the GPS coordinates in all subdirectories
        obj=get_xyz_radar(obj) % function to interpolate GPS coordinates for each radar trace        
        obj=get_skycal(obj) % fucntion to get the sky calibration periods        
        obj=remove_skycal(obj) % function to remove sky calibration        
        obj=cal_psd_radar(obj) % function to calculate frequency domain from time domain radar        
        obj=filter_normalize(obj)  % function to filter data with a median filter and normalize based on noise level        
        obj=pick_surface(obj) % function to pick surface reflections
        obj=smooth_image(obj) % function to smooth image to regular spacing
        obj=pick_ground(obj) % function to pick ground reflections
        obj=range_gain(obj) % function to apply an automatic range gain
        obj=get_equal_spaced(obj) % gets equally spaced locations for smoothing
    end
end

%% NOTE: below code written to get start and stop times from daq time...but something wrong with abstime
%       We will have to use GPS data (no movement) with radar data (sky cal or constant signal) to relate GPS to radar
        % get start
%         function ts=get.start(obj)
%             D=dir([obj.data_dir '*.daq']); % grab all daq files
%             filen=zeros(1,length(D));
%             for n=1:length(D)
%                 [P,F]=fileparts(D(n).name);
%                 filen(n)=str2double(F(6:end)); % get file number
%             end
%             [d,t,a]=daqread([obj.data_dir 'file0' num2str(min(filen)) '.daq']); % get date for first daq file
%             a(6)=round(a(6));
%             ts=a(4:6);
%         end
%         % get stop
%         function ts=get.stop(obj)
%             D=dir([obj.data_dir '*.daq']); % grab all daq files
%             filen=zeros(1,length(D));
%             for n=1:length(D)
%                 [P,F]=fileparts(D(n).name);
%                 filen(n)=str2double(F(6:end)); % get file number
%             end
%             [d,t,a]=daqread([obj.data_dir 'file0' num2str(max(filen)) '.daq']); % get date for last daq file
%             a(6)=round(a(6));
%             ts=a(4:6);
%         end
