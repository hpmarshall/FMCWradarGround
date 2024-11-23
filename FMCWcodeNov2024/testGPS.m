function testGPS

s1=serial('COM6');
s1.BaudRate=115200;
GPSfile=input('enter name for GPS file\n','s');
fid=fopen(GPSfile,'a');
s1.BytesAvailableFcnMode='terminator';
s1.BytesAvailableFcn={@writeGPS,fid,s1};
fopen(s1);
pause(10);
fclose(s1);
fclose(fid);


%s1.RecordDetail='verbose'; % or use 'compact'
%s1.RecordName='junkGPS1.txt';
%s1.RecordMode='index';
%record(s1)
%pause(3)
%record(s1)
%s1.RecordStatus

function writeGPS(obj,event,fid,s)
% reads a line from serial object s and writes to file fid
S1=fgetl(s);
fprintf(fid,S1);