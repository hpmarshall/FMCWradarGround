classdef FMCWprofile3
    % HPM 07/24/10
    % this class is for FMCW measurements
    % rd=FMCWprofile(location,data_dir,inc_angle)
    % this class adds GPU functionality
    properties
        location
        data_dir
        inc_angle
        vrange=[0.5 9.5];
        frange
        files=[1:10];
        TDATA
        CPUtime
        Fs
        PDATA
        w
        Tpl
        TWT
        xyz_GPS
        GPStime
        GPSrtrace
        GPSdata
        CPUtime_GPS
        xyz_radar
        GPUflag=0;
    end
    properties (Dependent = true, SetAccess = private)
        date
        daqfiles
    end

    methods
        % constuctor function
        function rd=FMCWprofile3(location,data_dir,inc_angle)
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
                [P,F]=fileparts(D(n).name);
                df(n)=str2double(F(6:end)); % get file number
            end
        end
        % get date function
        function ad=get.date(obj)
            [d,t,a]=daqread([obj.data_dir 'file0' num2str(min(obj.daqfiles)) '.daq']); % get date for first daq file
            ad=a(1:3);
        end
        % function to grab time domain data
        obj=subdivide_daq(obj)
        % function to perform windowed, zero-padded FFT to time domain data
        obj=process_tdata(obj)
        % function to plot an image of the processed data
        obj=plot_image(obj)
        % function to get the GPS coordinates associated with measurement
        obj=get_GPS(obj)
        % function to interpolate GPS coordinates for each radar trace
        obj=get_xyz_radar(obj)
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
