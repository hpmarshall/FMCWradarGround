function [psd,w] = cal_psd5(tdata,ww,N,Fs,GPUflag)
% cal_psd2.m
% HPM 02/06/04
% this function calculates frequency-domain data from 
%  a time-domain matrix
% INPUT: tdata = time domain matrix (from get_tdata)
%           ww = window for FFT
%            N = number of points in FFT
%           Fs = sample frequency [Hz]
% OUTPUT: psd = power spectral density estimates
%           w = frequencies sampled [Hz]
% SNTX: [psd,w] = cal_psd2(tdata,ww,N,Fs)

[n,k]=size(tdata);  % n=number of data points per trace,k=num total traces
if n==1
    tdata=tdata'; n=k; k=1;
end
wjw=ww(:,1); % weights for welch (just grab one column)
TDATA=ww.*tdata; % matrix to process
if GPUflag
    disp('processing on the GPU')
    TDATA=gsingle(TDATA); % put TDATA on GPU
    WJW=gsingle(wjw); % put wjw on GPU
    D=fft(TDATA,N);
    psd=estPSD(D,WJW,GPUflag); % power spectral density estimate
    psd=single(psd); % bring back to CPU
else
    D=fft(ww.*tdata,N);  % FFT, note that ww*tdata is padded w/ zeros if N>n; this prevents freq contamination
    psd=estPSD(D,wjw,GPUflag); % power spectral density estimate
end
w=(0:N/2-1)/(N)*Fs; % frequencies sampled

function psd=estPSD(D,wj,GPUflag)
% estPSD.m
% HPM 05/22/03
% this function creates an estimate of the power spectral density using the 1- or 2-D output from FFT
%  as described in "Numerical Recipies in C"
% INPUT: D=coefficients from FFT  [k,N], where k is number of columns
%        wj=weight on each data point (from hanning window, etc); use wj=ones(1,N) if no window  [1,N]
% OUTPUT : psd = power spectral density at each frequency [k,N/2]

[n3,m3]=size(D);
N=n3;
if GPUflag
    psd=gzeros(n3/2,m3); % make psd a matrix on the GPU
    N=gsingle(N); % make sure N is on the GPU
    Wss=N*sum(wj.^2); % window squared and summed [p.553, Num. Rec.]
    if m3 > 1
        psd(1,:)=1/Wss*abs(D(1,:)).^2; % frequency content at f_0=0
        i=2:(N/2); % positive frequencies
        i2=N+2-i; % negative frequencies
        psd(i,:)=1/Wss*(abs(D(i,:)).^2+abs(D(i2,:)).^2);  % [eq. 13.4.10, Num Rec]
        psd(N/2,:)=1/Wss*abs(D(N/2+1,:)).^2; % freq content of Nyquist freq
    else
        psd(1)=1/Wss*abs(D(1)).^2; % frequency content at f_0=0
        i=2:(N/2); % positive frequencies
        i2=N+2-i; % negative frequencies
        psd(i)=1/Wss*(abs(D(i)).^2+abs(D(i2)).^2);  % [eq. 13.4.10, Num Rec]
        psd(N/2)=1/Wss*abs(D(N/2+1)).^2; % freq content of Nyquist freq
    end
else
    Wss=N*sum(wj.^2); % window squared and summed [p.553, Num. Rec.]
    if m3 > 1
        psd(1,:)=1/Wss*abs(D(1,:)).^2; % frequency content at f_0=0
        i=2:(N/2); % positive frequencies
        i2=N+2-i; % negative frequencies
        psd(i,:)=1/Wss*(abs(D(i,:)).^2+abs(D(i2,:)).^2);  % [eq. 13.4.10, Num Rec]
        psd(N/2,:)=1/Wss*abs(D(N/2+1,:)).^2; % freq content of Nyquist freq
    else
        psd(1)=1/Wss*abs(D(1)).^2; % frequency content at f_0=0
        i=2:(N/2); % positive frequencies
        i2=N+2-i; % negative frequencies
        psd(i)=1/Wss*(abs(D(i)).^2+abs(D(i2)).^2);  % [eq. 13.4.10, Num Rec]
        psd(N/2)=1/Wss*abs(D(N/2+1)).^2; % freq content of Nyquist freq
    end
end