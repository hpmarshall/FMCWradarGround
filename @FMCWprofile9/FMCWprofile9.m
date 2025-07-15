classdef FMCWprofile9
    % HPM 07/24/10
    % this class is for FMCW measurements, and requires the below classes
    % this class adds GPU functionality
    properties
        % classes containing all settings
        M = measurement_settings; % object with the measurement settings
        P = processing_settings; % object with settings for processing
        P2 = postproc_settings; % object with settings for filtering/gaining/smoothing
        S = skycalpause_settings % object with settings for removing sky calibration and pauses
        L = layerpick_settings; % object with settings for picking layers
        G = GPS; % object with GPS data and settings for interpolating to radar traces
        % data description
        location = ' '; % description of profile location
        data_dir = ' '; % directory to completely process
        proc_dir = ' '; % processed data directory
        proc_subdir % index to sub directories to process
        % properties of the processed data
        PDATA % frequency domain matrix, power spectral density
        D % complex result of FFT, before estPSD
        TWT % two-way travel time
        xyz % xyz coordinates of each trace
        FEFN % false easting, false northing for plotting
        TDATA % time domain matrix
        Tpl % pulse length (defines maximum range)
        filenumber % radar filenumber for each trace, for GPS interpolation
        CPUtime % CPU time for each radar trace, for pre-2009 interpolation
        % settings for plotting
        ColorScale % [min max] amplitude range for plotting image
        rho=250; % [kg/m^3] density for estimating dry snow velocity
        DepthRange % [min max] depth scale for plot
        Marks % structure array containing marked traces and descriptions
        % date % JUKES ADDED DATE PROPERTY
    end
    properties (Dependent = true, SetAccess = private)
        date
        subdir % cell array of subdirectories
        %daqfiles
    end

    methods
        % constuctor function
        function rd=FMCWprofile9(location,data_dir)
            if nargin==0
                rd.location=' ';
                rd.data_dir=' ';
            end
            if nargin>0
                rd.location=location;
                rd.data_dir=data_dir;
             end
        end
        % % get daqfiles function
        % function df=get.daqfiles(obj)
        %     D=dir([obj.data_dir '*.daq']); % grab all daq files
        %     df=zeros(1,length(D));
        %     for n=1:length(D)
        %         [~,F]=fileparts(D(n).name);
        %         df(n)=str2double(F(6:end)); % get file number
        %     end
        % end
        % % get date function
        % function ad=get.date(obj)
        %     [~,~,a]=daqread([obj.data_dir 'file0' num2str(min(obj.daqfiles)) '.daq']); % get date for first daq file
        %     ad=a(1:3);
        % end
        % get subdir function
        function sd=get.subdir(obj)
            D=dir([obj.data_dir '*']);
            I2=find([D.isdir]); % get all the directories
            p=1;
            sd{1}=[];
            for n=1:length(I2)
                if isempty(strfind(D(I2(n)).name,'.')) % if is not . or ..
                    sd{p}=D(I2(n)).name; % add it to the list
                    p=p+1;
                end
            end
         end
        % methods
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
        %obj=LayerPicker(obj) % GUI for picking layers
        function plot_xyz(obj)
            figure(1);clf
            if ~isempty(obj.G(obj.proc_subdir(1)).xyz)
                plot(obj.G.xyz(:,1),obj.G.xyz(:,2),'o')
                hold on
            end
            if ~isempty(obj.xyz)
                plot(obj.xyz(:,1),obj.xyz(:,2),'rx')
                hold on
            end
        end 
    end
end