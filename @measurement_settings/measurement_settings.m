classdef measurement_settings
% this class contains all the FMCW measurement settings 
    properties
        incidence_angle=0; % incidence angle of measurement relative to nadir
        frange = [2 10]; % frequency range measured
        Fs = 100000; % sample frequency
        prf = 20; % pulse repetition frequency
        horns = '2-18 GHz Q-Par'; % horn antennas used
        GPS = 'onboard Garmin 5Hz OEM'; % GPS used
        channels = 'VV'; % cell array of channels
    end
end