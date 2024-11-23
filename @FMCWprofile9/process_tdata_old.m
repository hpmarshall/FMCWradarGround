function obj = process_tdata(obj)
% PROCESS_TDATA calculate zero-padded, windowed fft of time-domain data
% HPM 02/15/05, 07/24/10
% INPUT: obj.TDATA = matrix of time-domain data in columns
%             obj.Fs = sample frequency
% OUTPUT: obj.PDATA = normalized power spectral density
%             obj.w = frequency difference between transmitted and received signal


%% first check to see if processed yet
pdir=[obj.data_dir 'PROCESSED/']; % processed directory
pdir=obj.pdir;
% if ~exist(pdir,'dir') % if directory exists, entire profile has been processed in 100 file increments
%     disp('New profile, creating directory to store processed results:')
%     mkdir(pdir)
% end

%% lets figure out how many batches of files we have
nb=obj.batchsize; % number of files in a batch
minF=min(obj.files); maxF=max(obj.files); % get min and max file number to look at
disp(['processing files: ' num2str(minF) ' to ' num2str(maxF)])
s1=(floor(minF/nb))*nb+1; % start file
s2=(ceil(maxF/nb))*nb; % stop file
nbatch=ceil((s2-s1)/nb); % total number of batches
n4=obj.nfft/4; % just store the first 25% of frequency results
% subdivide first file to get size of matrix to build
rd=obj; % create new radar data object
save temp rd
rd.files=s1:(s1+nb-1); % 25 files to process
rd=subdivide_daq(rd); % subdivide raw daq files
obj.TWT=rd.TWT;
obj.Fs=rd.Fs;
[n5,m5]=size(rd.TDATA);
P=zeros(n4,m5,nbatch)*NaN; % initialize psd matrix
T=zeros(n5-10,m5,nbatch)*NaN; % initialize time domain data matrix, account for more or less measurements per trace
CPUtime=zeros(1,m5*mbatch)*NaN
%XYZ=zeros(3,m5,nbatch)*NaN; % initialize GPS coordinates

if obj.GPUflag % if running on GPU
    for n=1:nbatch % do a regular for loop
        s3=s1+(n-1)*nb;
        s4=min([s3+nb-1 maxF]);
        disp(['Processing:' pdir 'PRD' num2str(s3) '-' num2str(s4)]) % processed file
        rd=obj; % create new radar data object
        rd.files=s3:s4; % 25 files to process
        rd=subdivide_daq(rd); % subdivide raw daq files
        rd.TDATA=rd.TDATA(1:(n5-10),:); % remove last 10 to fix size
        rd.nfft=obj.nfft; % number of FFT points
        rd=cal_psd_radar(rd); % process for freq domain
        %rd=get_xyz_radar(rd);
        % updated to work on file numbers not a multiple of 25
        %  modified to padd with NaNs to work with parfor
        P2=zeros(n4,m5)*NaN; % initialize psd matrix
        T2=zeros(n5-10,m5)*NaN; % initialize time domain data matrix, account for more or less measurements per trace
        %XYZ2=zeros(3,m5)*NaN; % initialize GPS coordinates     
        % get the sizes
        [n9,m9]=size(rd.PDATA); [n10,m10]=size(rd.TDATA); [n11,m11]=size(rd.xyz_radar_trace);
        P2(1:n4,1:m9)=rd.PDATA(1:n4,:); % store psd
        T2(1:n10,1:m10)=rd.TDATA; % store time domain
        %XYZ2(:,1:n11)=rd.xyz_radar_trace'; % store gps coordinates for each trace
        P(:,:,n)=P2;
        T(:,:,n)=T2; % store time domain
        %XYZ(:,:,n)=XYZ2; % store gps coordinates for each trace            
    end
else % if not on GPU, use multiple cores
    if obj.Ncores>1
        eval(['matlabpool open ' num2str(obj.Ncores)]) % open multiple cores
        parfor n=1:nbatch % loop over each batch
            s3=s1+(n-1)*nb; % start file
            s4=min([s3+nb-1 maxF]); % stop file
            disp(['Processing:' pdir 'PRD' num2str(s3) '-' num2str(s4)]) % processed file
            rd=obj;
            rd.files=s3:s4; % 25 files to process
            rd=subdivide_daq(rd); % subdivide raw daq files
            rd.TDATA=rd.TDATA(1:(n5-10),:); % remove last 10 to fix size
            rd.nfft=obj.nfft; % number of FFT points
            rd=cal_psd_radar(rd); % process for freq domain
            % rd=get_xyz_radar(rd);
            % updated to work on file numbers not a multiple of 25
            %  modified to padd with NaNs to work with parfor
            P2=zeros(n4,m5)*NaN; % initialize psd matrix
            T2=zeros(n5-10,m5)*NaN; % initialize time domain data matrix, account for more or less measurements per trace
            %XYZ2=zeros(3,m5)*NaN; % initialize GPS coordinates
            % get the sizes
            [n9,m9]=size(rd.PDATA); [n10,m10]=size(rd.TDATA); [n11,m11]=size(rd.xyz_radar_trace);
            P2(1:n4,1:m9)=rd.PDATA(1:n4,:); % store psd
            T2(1:n10,1:m10)=rd.TDATA; % store time domain
            %XYZ2(:,1:n11)=rd.xyz_radar_trace'; % store gps coordinates for each trace
            P(:,:,n)=P2;
            T(:,:,n)=T2; % store time domain
            %XYZ(:,:,n)=XYZ2; % store gps coordinates for each trace
        end
        matlabpool close % close the cores
    else
        for n=1:nbatch % loop over each batch
            s3=s1+(n-1)*nb; % start file
            s4=min([s3+nb-1 maxF]); % stop file
            disp(['Processing:' pdir 'PRD' num2str(s3) '-' num2str(s4)]) % processed file
            rd=obj;
            rd.files=s3:s4; % 25 files to process
            rd=subdivide_daq(rd); % subdivide raw daq files
            rd.TDATA=rd.TDATA(1:(n5-10),:); % remove last 10 to fix size
            rd.nfft=obj.nfft; % number of FFT points
            rd=cal_psd_radar(rd); % process for freq domain
            % rd=get_xyz_radar(rd);
            % updated to work on file numbers not a multiple of 25
            %  modified to padd with NaNs to work with parfor
            P2=zeros(n4,m5)*NaN; % initialize psd matrix
            T2=zeros(n5-10,m5)*NaN; % initialize time domain data matrix, account for more or less measurements per trace
            %XYZ2=zeros(3,m5)*NaN; % initialize GPS coordinates
            % get the sizes
            [n9,m9]=size(rd.PDATA); [n10,m10]=size(rd.TDATA); [n11,m11]=size(rd.xyz_radar_trace);
            P2(1:n4,1:m9)=rd.PDATA(1:n4,:); % store psd
            T2(1:n10,1:m10)=rd.TDATA; % store time domain
            %XYZ2(:,1:n11)=rd.xyz_radar_trace'; % store gps coordinates for each trace
            P(:,:,n)=P2;
            T(:,:,n)=T2; % store time domain
            %XYZ(:,:,n)=XYZ2; % store gps coordinates for each trace
        end        
    end
end
[n6,m6,q6]=size(P);
[n7,m7,q7]=size(T);
%[~,m8,q8]=size(XYZ);
obj.PDATA=single(reshape(P,n6,m6*q6));
I2=isfinite(obj.PDATA(1,:)); % find finite traces
obj.PDATA=obj.PDATA(:,I2); % remove trailing NaNs
obj.TDATA=single(reshape(T,n7,m7*q7));
rd=cal_psd_radar(rd); % run once more to get w vector
obj.w=single(rd.w);
obj.Tpl=rd.Tpl;
obj.TWT=single(rd.TWT);
%obj.xyz_GPS=single(obj.xyz_GPS);
%obj.GPStime=single(obj.GPStime);
%obj.GPSrtrace=single(obj.GPSrtrace);
%obj.GPSdata=single(obj.GPSdata);
%obj.xyz_radar_trace=single(obj.xyz_radar_trace);
%obj.xyz_radar_trace=(reshape(XYZ,3,m8*q8))';
%figure(1);hold on
%dx=obj.FEFN(:,1);
%dy=obj.FEFN(:,2);
%plot(obj.xyz_radar_trace(1,1)-dx,obj.xyz_radar_trace(1,2)-dy,'ro','MarkerSize',10,'linewidth',3)
%plot(obj.xyz_radar_trace(end,1)-dx,obj.xyz_radar_trace(end,2)-dy,'rx','MarkerSize',10,'linewidth',3)
%legend('GPS points','start','stop')


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %% SUBFUNCTIONS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function w = KaiserBessel(N,alpha)
% % KaiserBessel.m
% % HPM  02/03/04
% % this function gives a Kaiser-Bessel window (Harris,1978)
% % INPUT: N= number of samples
% %    alpha = parameter, where pi*alpha=1/2(time-bandwidth product)
% %         increasing alpha decreases side-lobe level at expense of
% %         increasing the time-bandwidth product
% %      THEREFORE: small alpha gives better resolution, but more effect to
% %      nearby frequencies...so use small alpha for determining location of
% %      strong signals, but will need larger alpha to resolve weak signals..
% % OUTPUT: w = window weights
% % SNTX: w = KaiserBessel(N,alpha)
% 
% I0=besseli(0,pi*alpha); % zero-order modified bessel function of the first kind
% n=-N/2:N/2; % sample points
% X=pi*alpha*sqrt(1.0-(n/(N/2)).^2); % input to modified bessel function
% w=besseli(0,X)./I0; % weights
% w=w(1:length(w)-1)'; % make it a column vector
% 
% function [psd,w] = cal_psd2(tdata,ww,N,Fs,GPUflag)
% % cal_psd2.m
% % HPM 02/06/04
% % this function calculates frequency-domain data from 
% %  a time-domain matrix
% % INPUT: tdata = time domain matrix (from get_tdata)
% %           ww = window for FFT
% %            N = number of points in FFT
% %           Fs = sample frequency [Hz]
% % OUTPUT: psd = power spectral density estimates
% %           w = frequencies sampled [Hz]
% % SNTX: [psd,w] = cal_psd2(tdata,ww,N,Fs)
% 
% [n,k]=size(tdata);  % n=number of data points per trace,k=num total traces
% if n==1
%     tdata=tdata'; n=k; k=1;
% end
% wjw=ww(:,1); % weights for welch (just grab one column)
% TDATA=ww.*tdata; % matrix to process
% if GPUflag
%     disp('processing on the GPU')
%     TDATA=gsingle(TDATA); % put TDATA on GPU
%     WJW=gsingle(wjw); % put wjw on GPU
%     D=fft(TDATA,N);
%     psd=estPSD(D,WJW,GPUflag); % power spectral density estimate
%     psd=single(psd); % bring back to CPU
% else
%     D=fft(ww.*tdata,N);  % FFT, note that ww*tdata is padded w/ zeros if N>n; this prevents freq contamination
%     psd=estPSD(D,wjw,GPUflag); % power spectral density estimate
% end
% w=(0:N/2-1)/(N)*Fs; % frequencies sampled
% 
% function psd=estPSD(D,wj,GPUflag)
% % estPSD.m
% % HPM 05/22/03
% % this function creates an estimate of the power spectral density using the 1- or 2-D output from FFT
% %  as described in "Numerical Recipies in C"
% % INPUT: D=coefficients from FFT  [k,N], where k is number of columns
% %        wj=weight on each data point (from hanning window, etc); use wj=ones(1,N) if no window  [1,N]
% % OUTPUT : psd = power spectral density at each frequency [k,N/2]
% 
% [n3,m3]=size(D);
% N=n3;
% if GPUflag
%     psd=gzeros(n3/2,m3); % make psd a matrix on the GPU
%     N=gsingle(N); % make sure N is on the GPU
%     Wss=N*sum(wj.^2); % window squared and summed [p.553, Num. Rec.]
%     if m3 > 1
%         psd(1,:)=1/Wss*abs(D(1,:)).^2; % frequency content at f_0=0
%         i=2:(N/2); % positive frequencies
%         i2=N+2-i; % negative frequencies
%         psd(i,:)=1/Wss*(abs(D(i,:)).^2+abs(D(i2,:)).^2);  % [eq. 13.4.10, Num Rec]
%         psd(N/2,:)=1/Wss*abs(D(N/2+1,:)).^2; % freq content of Nyquist freq
%     else
%         psd(1)=1/Wss*abs(D(1)).^2; % frequency content at f_0=0
%         i=2:(N/2); % positive frequencies
%         i2=N+2-i; % negative frequencies
%         psd(i)=1/Wss*(abs(D(i)).^2+abs(D(i2)).^2);  % [eq. 13.4.10, Num Rec]
%         psd(N/2)=1/Wss*abs(D(N/2+1)).^2; % freq content of Nyquist freq
%     end
% else
%     Wss=N*sum(wj.^2); % window squared and summed [p.553, Num. Rec.]
%     if m3 > 1
%         psd(1,:)=1/Wss*abs(D(1,:)).^2; % frequency content at f_0=0
%         i=2:(N/2); % positive frequencies
%         i2=N+2-i; % negative frequencies
%         psd(i,:)=1/Wss*(abs(D(i,:)).^2+abs(D(i2,:)).^2);  % [eq. 13.4.10, Num Rec]
%         psd(N/2,:)=1/Wss*abs(D(N/2+1,:)).^2; % freq content of Nyquist freq
%     else
%         psd(1)=1/Wss*abs(D(1)).^2; % frequency content at f_0=0
%         i=2:(N/2); % positive frequencies
%         i2=N+2-i; % negative frequencies
%         psd(i)=1/Wss*(abs(D(i)).^2+abs(D(i2)).^2);  % [eq. 13.4.10, Num Rec]
%         psd(N/2)=1/Wss*abs(D(N/2+1)).^2; % freq content of Nyquist freq
%     end
% end