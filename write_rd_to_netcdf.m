% function to save an rd FMCWprofile9 object to a .mat file
function write_rd_to_netcdf(filepath)
load(filepath);
newfilename = [filepath(1:end-4) '.nc']; % target file name

PDATA = rd.PATA; TWT = rd.TWT; % grab PDATA & TWT
ylen, xlen = size(PDATA); % dimensions of PDATA

nccreate(newfilename,"PDATA"); % create PDATA variable
nccreate(newfilename,"TWT"); % TWT
ncwrite(newfilename,"PDATA",PDATA); % write PDATA
ncwrite(newfilename,"TWT",TWT(ylen+1:end)); % positive half of TWT

if length(rd.xyz) > 0
    x = rd.xyz(:,1); y = rd.xyz(:,2); z = rd.xyz(:,3);
    skycal_idx = rd.S.SkycalTraces; trace_idx = rd.S.ProfileTraces;

    % write to file
    nccreate(newfilename,"x"); ncwrite(newfilename,"x", x);
    nccreate(newfilename,"y"); ncwrite(newfilename,"y", y);
    nccreate(newfilename,"z"); ncwrite(newfilename,"z", z);
    nccreate(newfilename,"skycal_idx"); ncwrite(newfilename,"skycal_idx", skycal_idx);
    nccreate(newfilename,"trace_idx"); ncwrite(newfilename,"trace_idx", trace_idx);
end
% save(newfilename);
