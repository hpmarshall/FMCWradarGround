classdef processing_settings
% this class contains all the FMCW processing settings    
    properties
        frange=[2.4 9.6]; % [GHz] frequency range to process
        vrange; % [V] voltage range on sweep to oscillator
        channel=1; % FMCW channel to process (1 or 2, for co/cross pol)
        files % daq files to process within the folder
        GPUflag=0; % 0=run FFT on CPU, 1=run FFT on GPU
        Ncores=1; % number of cores to use for processing with parallel toolbox
        nfft=2^13; % number of points in FFT
        alpha=5.3;
        batchsize=50; % number of daq files to process in a batch
        ndaq=500; % number of daq file processed results to save together in a mat file
        maxP=2^12; % maximum row number to save in PDATA
        overwrite=0 % overwrite previous processing results
    end
end