function writeGPS(obj,event,s1,fid)
% reads a line from serial object s and writes to file fid
GPSstring=fgetl(s1);
if strcmp(GPSstring(1:6),'$GNGGA')
    disp(GPSstring)
    fprintf(fid,[GPSstring ' \n']);
end

