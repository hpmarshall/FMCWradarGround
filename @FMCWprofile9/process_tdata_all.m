function obj=process_tdata_all(obj)
% HPM 07/16/12
% this function processes all of the data in all subdirectories given in
%   obj.subdir.  Note it must be run after get_GPS_all

ndaq=obj.P.ndaq; % maximum number of daq files to save together
maxP=obj.P.maxP; % maximum row number to save
data_dir=obj.data_dir; % data directory
proc_dir=obj.proc_dir; % store results
G=obj.G;
for n=1:length(obj.proc_subdir)
    subdir=obj.subdir{obj.proc_subdir(n)};
    D2=dir([proc_dir subdir '_*.mat']);
    if ((isempty(D2) && obj.P.overwrite==0) || obj.P.overwrite==1)
        obj.data_dir=[obj.data_dir subdir '/'];
        if iscell(G)
            G2=G{1};
        else
            G2=G(1);
        end
        if ~isempty(G2.xyz)
            obj.G=G(obj.proc_subdir(n));
        else
            GPSfile=[data_dir 'GPSall.mat']; % processed GPS data
        end   
        if length(obj.P.files)<=ndaq
            %obj.P.files=1:(length(obj.daqfiles)-2); % process entire directory
            if ~isempty(obj.P.files)
                tic
                obj=process_tdata(obj);
                toc
                obj.PDATA=obj.PDATA(1:maxP/2,:); %
               % obj.D=obj.D(1:maxP,:); %
                if ~isempty(obj.S.SkyCalRange)
                    obj=get_skycal(obj); % find the sky cal measurements
                    obj=remove_skycal(obj); % remove the sky measurements
                end
                %obj=filter_normalize(obj); % apply median filter and normalize to noise level
                %obj=range_gain(obj); % apply AGC
%                 if ~isempty(G.xyz) % if the GPS object has xyz coordinates
%                     obj=get_xyz_radar(obj); % get xyz coordinates for all traces
%                 else % otherwise we set the CPU tine and use an old function to get the GPS data - see SBB processing for this...
%                     disp('warning, using get_radarGPS2 which is not currently a method for FMCWprofile8! please include as object method!')
%                     if ~isempty(obj.S.ProfileTraces)
%                         Rtime=obj.CPUtime(obj.S.ProfileTraces);
%                     else
%                         Rtime=obj.CPUtime;
%                     end
%                     [Rx,Ry,Rz] = get_radarGPS2(GPSfile,Rtime);
%                     obj.xyz=[Rx(:) Ry(:) Rz(:)];
%                 end
                rd=obj;
                % store everything in rd structure for saving
                %rd.TDATA=[]; % remove TDATA field to save space
                save([rd.proc_dir subdir],'-v7.3','rd')
            else
                disp('no files in rd.P.files!')
            end
            obj.data_dir=data_dir;
        else % too many daq files to do entire directory, subdividing -- this is a place for possible parallel application if multiple GPU
            disp('Note: more than obj.P.ndaq files in this directory, subdividing...')
            nf=ceil(length(obj.P.files)/ndaq); % number of separate 2000 daq file groups
            P.files=obj.P.files;
            for m=1:nf
                s3=1+(m-1)*ndaq;
                s4=min([(s3+ndaq-1) (max(obj.daqfiles)-1)]);
                if max(P.files)>s4 % if s4 is less than the last file
                    obj.P.files=s3:s4; % do in batches, otherwise don't change the files to process
                end               
                obj.TDATA=[]; obj.filenumber=[];
                tic
                obj=process_tdata(obj);
                toc
                obj.D=obj.D(1:maxP,:); %
                obj.PDATA=obj.PDATA(1:maxP/2,:); %
                if ~isempty(obj.S.SkyCalRange)
                    obj=get_skycal(obj); % find the sky cal measurements
                    obj=remove_skycal(obj); % remove the sky measurements
                end
                %obj=filter_normalize(obj); % apply median filter and normalize to noise level
                %obj=range_gain(obj); % apply AGG
                %obj=get_xyz_radar(obj); % get xyz coordinates for all traces
%                 if ~isempty(G2.xyz)
%                     obj=get_xyz_radar(obj); % get xyz coordinates for all traces
%                 else
%                     if ~isempty(obj.S.ProfileTraces)
%                         Rtime=obj.CPUtime(obj.S.ProfileTraces);
%                     else
%                         Rtime=obj.CPUtime;
%                     end
%                     [Rx,Ry,Rz] = get_radarGPS2(GPSfile,Rtime);
%                     obj.xyz=[Rx(:) Ry(:) Rz(:)];
%                 end
                rd=obj;
                %rd.TDATA=[];
                save([rd.proc_dir subdir '_' num2str(m)],'-v7.3','rd')
            end
        end
    else
        disp([subdir ' has already been processed, skipping...'])
    end
    obj.data_dir=data_dir;
end
