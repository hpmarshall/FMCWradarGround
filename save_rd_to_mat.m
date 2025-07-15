% function to save an rd FMCWprofile9 object to a .mat file
function save_rd_to_mat(filepath)
load(filepath);
PDATA = rd.PDATA;
TWT = rd.TWT;
if length(rd.xyz) > 0
    x = rd.xyz(:,1); y = rd.xyz(:,2); z = rd.xyz(:,3);
    skycal_idx = rd.S.SkycalTraces; trace_idx = rd.S.ProfileTraces;
end
save([filepath(1:end-4) '_PDATA.mat']);
