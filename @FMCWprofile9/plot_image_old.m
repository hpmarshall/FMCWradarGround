function obj=plot_image(obj)
% HPM 07/28/10
% this function plots a FMCWprofile object


%% first check to see if processed yet
pdir=['/home/hpm/D_DRIVE/PROCESSED_RADAR' obj.data_dir(39:end)]; % processed directory
if ~exist(pdir) % if directory exists, entire profile has been processed in 100 file increments
    disp('New profile, creating directory to store processed results:')
    mkdir(pdir)
    pdir
end

%% lets figure out how many batches of 100 files we have
minF=min(obj.files); maxF=max(obj.files); % get min and max file number to look at
disp(['processing files: ' num2str(minF) ' to ' num2str(maxF)])
s1=(floor(minF/100))*100+1; % start file
s2=(ceil(maxF/100))*100; % stop file
nbatch=floor((s2-s1)/100)+1 % number of batches
for n=1:nbatch
    s3=s1+(n-1)*100;
    s4=min([s3+99 maxF]); 
    pfile=[pdir 'PRD' num2str(s3) '-' num2str(s4)] % processed file
    if exist(pfile)
        disp(['file: ' pfile ' already processed, skipping'])
    else
        rd=obj; % create new radar data object
        rd.files=s3:s4; % 100 files to process
        tic
        rd=subdivide_daq(rd); % subdivide raw daq files
        toc
        nfft=2^13; % number of FFT points
        [n2,m2]=size(rd.TDATA); % size of time domain matrix
        ww = KaiserBessel(n2,2.0); % calculate window
        WW=ww(:)*ones(1,m2); % make WW size of tdata
        tic
        [Pn,rd.w]=cal_psd2(rd.TDATA,WW,nfft,rd.Fs); % calculate the windowed, zero-padded FFT
        toc
        Pn=10*log10(Pn); % put on dB scale
        rd.PDATA=single(Pn);
        rd.TDATA=[]; % remove TDATA to save space
        save(pfile,'rd') % save object for future use
        clear rd Pn WW % clear large varibles to free up space
    end
end




minF=min(obj.files); maxF=max(obj.files); % get min and max file number to look at
disp(['plotting files: ' num2str(minF) ' to ' num2str(maxF)])
s1=(floor(minF/100))*100+1; % start file
s2=(ceil(maxF/100))*100; % stop file
nfiles=floor((s2-s1)/100)+1 % number of files to load
pdir=['/home/hpm/D_DRIVE/PROCESSED_RADAR' obj.data_dir(39:end)]; % processed directory
pfile=[pdir 'PRD' num2str(s1) '-' num2str(s2)] % processed file
if exist

load([pdir 'PRD' num2str(s1) '-' num2str((s1+99))]); % load the first one
[n3,m3]=size(rd.PDATA); % get the size
nw=floor(n3/2); % keep upper half
obj.PDATA=zeros(nw,m3*nfiles); % preallocate
obj.PDATA(:,1:m3)=rd.PDATA(1:nw,:); % store first daq file
obj.CPUtime(1:m3)=rd.CPUtime;
for n=2:nfiles
    n
    s1=s1+100;
    load([pdir 'PRD' num2str(s1) '-' num2str((s1+99))]); % load the next one
    t1=(n-1)*m3+1;
    t2=t1+m3-1;
    obj.PDATA(:,t1:t2)=rd.PDATA(1:nw,:); % grab upper half of result
    obj.CPUtime(t1:t2)=rd.CPUtime;
end
obj.w=rd.w(1:nw);
%% now plot the entire image    
figure
[n5,m5]=size(obj.PDATA);
h=imagesc((1:m5),obj.w,obj.PDATA,[-100 -65]);
axis([1 m5 1 50000])
xlabel('trace #')
ylabel('frequency difference [Hz]')
colorbar
