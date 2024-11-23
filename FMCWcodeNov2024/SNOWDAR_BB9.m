function varargout = SNOWDAR_BB9(varargin)
% SNOWDAR_BB9 M-file for SNOWDAR_BB9.fig
%      SNOWDAR_BB9, by itself, creates a new SNOWDAR_BB9 or raises the existing
%      singleton*.
%
%      H = SNOWDAR_BB9 returns the handle to a new SNOWDAR_BB9 or the handle to
%      the existing singleton*.
%
%      SNOWDAR_BB9('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SNOWDAR_BB9.M with the given input arguments.
%
%      SNOWDAR_BB9('Property','Value',...) creates a new SNOWDAR_BB9 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SNOWDAR_BB8_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SNOWDAR_BB9_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SNOWDAR_BB9

% Last Modified by GUIDE v2.5 05-Mar-2012 23:34:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SNOWDAR_BB9_OpeningFcn, ...
                   'gui_OutputFcn',  @SNOWDAR_BB9_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SNOWDAR_BB9 is made visible.
function SNOWDAR_BB9_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SNOWDAR_BB9 (see VARARGIN)


% Choose default command line output for SNOWDAR_BB9
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SNOWDAR_BB9 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SNOWDAR_BB9_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in Measure_set.
function Measure_set_Callback(hObject, eventdata, handles)
% hObject    handle to Measure_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h=measure_settings_BB2

% --- Executes on button press in Process_set.
function Process_set_Callback(hObject, eventdata, handles)
% hObject    handle to Process_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h=process_settings_BB2

% --- Executes on button press in Plot_set.
function Plot_set_Callback(hObject, eventdata, handles)
% hObject    handle to Plot_set (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
h=plot_settings_BB2

% --- Executes on button press in Restore_defaults.
function Restore_defaults_Callback(hObject, eventdata, handles)
% hObject    handle to Restore_defaults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete('measure_settings.mat')
delete('process_settings.mat')
delete('plot_settings.mat')

% --- Executes on button press in Process.
function Process_Callback(hObject, eventdata, handles)
% hObject    handle to Process (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% set the constants for this high freq oscillator

[psd_dB,depth,w,pTpl,BW] = process_data_BB3;

% save processed data
handles.psd_dB=psd_dB;
handles.w=w; handles.pTpl=pTpl; handles.BW=BW;
handles.depth=depth;
guidata(hObject, handles);



% --- Executes on button press in Plot.
function Plot_Callback(hObject, eventdata, handles)
% hObject    handle to Plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfield(handles,'psd_dB')
    file=uigetfile('*_proc.mat','No current processed data, please load processed file, or cancel:');
    if file
        load(file)
        handles.psd_dB=d.psd_dB;
        handles.w=d.w; handles.pTpl=d.pTpl; handles.BW=d.BW;
    else
        handles.psd_dB=zeros(100,100);
        handles.w=1:100; handles.Tpl=0.02; handles.BW=8;
    end
end    
% load the settings
d=load_all_settingsBB;
v=d.plot.v; % speed in cm/s
depthmin=d.plot.depthmin; depthmax=d.plot.depthmax; % depth range
zmin=d.plot.zmin; zmax=d.plot.zmax; % psd range
tmin=d.plot.tmin; tmax=d.plot.tmax; % psd range

% get depth scale
depth=0.5*handles.w*handles.pTpl/(handles.BW*1e9)*v;
handles.depth=depth;

% plot result in new figure
disp('Plot result...')
[n,m]=size(handles.psd_dB);
figure;
imagesc((1:m),depth,handles.psd_dB,[zmin zmax]) % plot
if tmax==inf
    tmax=m;
end
axis([tmin tmax depthmin depthmax])
set(gca,'YDir','reverse')
title(d.process.datadir)
guidata(hObject, handles);

    


% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
% hObject    handle to Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% save the measurement
d=load_all_settingsBB;
datadir=d.process.datadir;
[file,path]=uiputfile('*.mat','Save Processed Data in File:',[datadir '_proc']);
if file
    d.psd_dB=handles.psd_dB;
    d.pTpl=handles.pTpl;
    d.w=handles.w;
    d.BW=handles.BW;
    d.depth=handles.depth;
    d.allset=load_all_settingsBB;
    save(file,'d')
end



% --- Executes on button press in Test_radar.
function Test_radar_Callback(hObject, eventdata, handles)
% hObject    handle to Test_radar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
test_FMCW_BB6

% --- Executes on button press in Profile.
function Profile_Callback(hObject, eventdata, handles)
% hObject    handle to Profile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
profile_BB8

% --- Executes on button press in Exit.
function Exit_Callback(hObject, eventdata, handles)
% hObject    handle to Exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(gcf)



% --- Executes on button press in startgps.
function startgps_Callback(hObject, eventdata, handles)
% hObject    handle to startgps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
GPSfile=input('gps file?','s')
[handles.gps,handles.fid]=readGPS6(GPSfile)
guidata(hObject, handles);

% --- Executes on button press in stopgps.
function stopgps_Callback(hObject, eventdata, handles)
% hObject    handle to stopgps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
fclose(handles.fid)
fclose(handles.gps)

