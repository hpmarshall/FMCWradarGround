classdef postproc_settings
    % this class contains all the FMCW settings for postprocessing - filtering/gain/smooth
    properties
        MedFiltSize=[4 4]; % size of median filter (index) to apply during "filter_normalize"
        NoiseRange % index range for normalization to noise
        gain_window % [samples] smoothing window to use for gain
        smooth_x % easting locations to provide smoothed estimate
        smooth_y % northing locations for smoothed estimate
        smooth_window % [m] window size for smoothing image
    end
end