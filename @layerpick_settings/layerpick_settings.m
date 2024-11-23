classdef layerpick_settings
% settings for autopicking surface and ground in FMCW data
    properties
        Isurf % index to surface locations
        surfthresh % threshold for locating surface reflections
        DCcoupling % index range at top of profile to remove before finding surface (caused by DC coupling)
        SurfMax % max index for surface pick
        Gthresh % threshold for ground picks
        Gmin % minimum index for ground picks
        Iground % index to ground picks
    end
end