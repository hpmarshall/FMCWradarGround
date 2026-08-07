classdef GPS
    % this class contains the GPS data and processing settings
    properties
        % GPS data
        xyz % UTM easting, northing, elevation
        time % GPS time
        daqfile % associated radar daqfile
        NumSat % number of satellites
        HDOP % [m] horizontal dilution of position (estimated relative accuracy)
        Fix % 0 for no fix, 1 for GPS fix, 2 for DGPS fix
        % GPS settings
        maxHDOP=2; % minimum HDOP to use
        dtSkyCal=5; % [sec] time difference between sky calibration
        UTCoffset=0; % [hours] CPUtime = GPS UTC time - UTCoffset; only used for GPS fixes with no daqfile match (e.g. a standalone GPS logger not tied to the radar's internal file counter), to align the DAQ computer clock with GPS time before interpolating
    end
end