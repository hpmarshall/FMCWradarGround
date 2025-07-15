%% Process RME May 2025
cd '/Users/jukesliu/Documents/GitHub'/FMCWradarGround/;
data_folder = '/Users/jukesliu/Documents/POSTDOC/snow-radar/ReynoldsMountain/ProcessedMay25_xyz/';

files = dir(fullfile(data_folder,'p*.mat'));
for k = 1:length(files)
    filepath = [data_folder, files(k).name];
    disp(files(k).name);
    % save_rd_to_mat(filepath)
    write_rd_to_netcdf(filepath);
end
