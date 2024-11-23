classdef skycalpause_settings
% object with all settings for removing sky calibration and pauses
    properties
        ProfileTraces % index to traces during profiling
        SkycalTraces % index to traces during sky calibration
        skythresh % threshold for locating sky calibration
        SkyCalRange % index range for locating sky calibration measurements
        mSky % mean sky calibration measurement
    end
end
