function varargout = LayerPicker4(varargin)
% LAYERPICKER4 M-file for LayerPicker4.fig
%      LAYERPICKER4, by itself, creates a new LAYERPICKER4 or raises the existing
%      singleton*.
%
%      H = LAYERPICKER4 returns the handle to a new LAYERPICKER4 or the handle to
%      the existing singleton*.
%
%      LAYERPICKER4('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LAYERPICKER4.M with the given input arguments.
%
%      LAYERPICKER4('Property','Value',...) creates a new LAYERPICKER4 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before layer_picker3_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LayerPicker4_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LayerPicker4

% Last Modified by GUIDE v2.5 02-Aug-2012 23:13:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @LayerPicker4_OpeningFcn, ...
    'gui_OutputFcn',  @LayerPicker4_OutputFcn, ...
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


% --- Executes just before LayerPicker4 is made visible.
function LayerPicker4_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LayerPicker4 (see VARARGIN)

% Choose default command line output for LayerPicker4
handles.output = hObject;
handles.dpath='/home';
handles.ppath='/home';
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes LayerPicker4 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = LayerPicker4_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%varargout{1} = handles.output;


% --- Executes on button press in pick_pts_push.
function pick_pts_push_Callback(hObject, eventdata, handles)
% hObject    handle to pick_pts_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
x=[];y=[];    %reset click points.
handles.Ypick=[];
handles.Xpick=[];
z=str2double(get(handles.ztol_edit,'string'));
% keep current axis limits
xlim=get(handles.main_axes,'xlim');
handles.xmin=xlim(1);
handles.xmax=xlim(2);
ylim=get(handles.main_axes,'ylim');
handles.ymin=ylim(1);
handles.ymax=ylim(2);
guidata(hObject, handles);
[x,y]=ginput; % get user input

for n=1:length(x) % Snap Picks to Peaks
    [~,Ix]=min(abs(x(n)-handles.X)); % index of x pick
    [~,Iy] =min(abs(y(n)-handles.Y)); % index of y pick
    win=Iy-z:Iy+z; % window to adjust pick to max amplitude    
    [~,Iy2]=max(handles.data(win,Ix)); % find maximum within the window in the Ix trace    
    x(n)=handles.X(Ix); % store adjusted x location
    y(n)=handles.Y(win(Iy2)); % store adjusted y location
end
% update gui
handles.Xpick=x;
handles.Ypick=y;
plot_main(handles)
guidata(hObject, handles);

% --- Executes on button press in pick_layer_push.
function pick_layer_push_Callback(hObject, eventdata, handles)
% hObject    handle to pick_layer_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Check to make sure picks have been made
if isempty(handles.Xpick) || isempty(handles.Ypick)
    h=msgbox('Requires Picked Points','ERROR','warn');
    set(h,'color',[153 193 203]/255)
end

ztol=str2num(get(handles.ztol_edit,'String'));  % # of points above and below to search
[~,I1]=min(abs(handles.Xpick(1)-handles.X)); % index of first xpick
[~,Iend]=min(abs(handles.Xpick(end)-handles.X)); % index of last xpick

if length(handles.Ypick)==length(handles.Y)     %if full layer picked (IE surf or ground)
    ypts=handles.Ypick;     %pass the layer to new variable    
else %otherwise (IE Not surf or ground)
    I=find(isnan(handles.Ypick)); % find nans
    % toss nans
    handles.Ypick(I)=[];
    handles.Xpick(I)=[];
    % interpolate between points
    ypts=interp1(handles.Xpick,handles.Ypick,handles.X(I1:Iend));    
end

xtemp=handles.X(I1:Iend);
check='empty';
% check for coordinates, if there arnt any setting opt=[] lets add_layers
% know
opt=[];
if isfield(handles,'XX')
    X=handles.XX(I1:Iend);
    Y=handles.YY(I1:Iend);
    check='xy';
    opt{1}=X;
    opt{2}=Y;
    opt{3}=check;
elseif isfield(handles,'lon')
    X=handles.lon(I1:Iend);
    Y=handles.lat(I1:Iend);
    check='ll'
    opt{1}=X;
    opt{2}=Y;
    opt{3}=check;
end
%Construct a question dlalog
choice = questdlg('Use current range to pick layer?','Look Down','Yes','No','Yes');
% Handle response
switch choice
    case 'Yes'      %if user likes their  ranges, find peaks
        for ii=1:length(ypts)
            [~,I]=min(abs(ypts(ii)-handles.Y)); % index of the closest time to ypts
            [~,Ix]=min(abs(xtemp(ii)-handles.X));
            win=I-ztol:I+ztol; % window around pick
            
            [~,Iy]=max(handles.data(win,Ix)); % get location of max amplitude within win
            layr(ii)=handles.Y(win(Iy)); % store time of adjusted pt
        end
        numL=num_layers(handles);   %get # of layers
        %add the layer
        
        handles=add_layer(handles.X(I1:Iend),layr,['Layer ',num2str(numL+1)],opt,handles);
        handles.Xpick=[];           %resets picked points
        handles.Ypick=[];           %resets picked points
        plot_main(handles)
        plot_trace(handles)
        plot(handles.Xpick,handles.Ypick,'m')
    case 'No'       %if user hates their ranges, go back
        plot_main(handles)
end

guidata(hObject, handles);


% --- Executes on button press in save_layers_push.
function save_layers_push_Callback(hObject, eventdata, handles)
% hObject    handle to save_layers_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filtspec = [handles.ppath];
[f,p]=uiputfile(filtspec,'Save Layers');
% avoid errors from pressing cancel or something else or save
if isnumeric(f) || isnumeric(p)
    return
else
    Layers=handles.layers;
    fname = [p f];
    save(fname,'Layers')
end


function ztol_edit_Callback(hObject, eventdata, handles)
% hObject    handle to ztol_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ztol_edit as text
%        str2double(get(hObject,'String')) returns contents of ztol_edit as a double

guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function ztol_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ztol_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in load_data_push.
function load_data_push_Callback(hObject, eventdata, handles)
% hObject    handle to load_data_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

filtspec = [handles.dpath];
[f p]=uigetfile(filtspec,'Load Radar Data');
% check button presses to either load or avoid errors by pressing something
% else
if isnumeric(f) || isnumeric(p)
    return
else
    load([p f])
end
% check for coordinates
if isfield(handles,'XY')
    if handles.XY==1
        handles=rmfield(handles,{'X','Y','XY'}) ;
    end
elseif isfield(handles,'ll')
    if handles.ll==1
        handles=rmfield(handles,{'lon','lat','ll'});
    end
end
handles.path=p;
handles.fname=f;

% sets the Current File display
dial = ['Current File:  ' f];
set(handles.static_text_cfile,'string',dial)
% remove variables that will mess stuff up if they already exist
if exist('handles.xmin','var') || exist('handles.xmax','var') ||...
        exist('handles.ymin','var') || exist('handles.xmax','var')
    handles = rmfield(handles,'xmin');
    handles = rmfield(handles,'xmax');
    handles = rmfield(handles,'ymin');
    handles = rmfield(handles,'xmax');
end

handles.pick_type='Follow Peak';     %init. pick_type
handles.trace=0;                %init. no trace to plot
handles.data=[];

%reset layer data
handles.layers=1;                   %initialize value, silly but needed to use rmfield
handles=rmfield(handles,'layers');  %clear layers field entirely
handles.layers.X=[];                %reset first layer x to empty
handles.layers.Y=[];                %reset first layer y to empty
handles.layers.Label=[];            %reset first layer label to empty
labels=get_layer_labels(handles);  %get layer labels
set(handles.layers_listbox,'value',1:length(handles.layers)) %give listbox right values
set(handles.layers_listbox,'string',labels) %make listbox display layers
handles.highlays.inds=[];    %resets layer highlighted
handles.highlays.p1=[];      %resets layer highlighted
handles.highlays.p2=[];      %resets layer highlighted
handles.Xpick=[];           %resets picked points
handles.Ypick=[];           %resets picked points

%*************************************************************************
%*** important variables, make sure these are correct for each dataset ***
%*************************************************************************

%%%%%%%%%%% HPM 08/02/12 -- added functionality for loading FMCWprofile8 objects
if exist(rd) % if an FMCWprofile8 object was loaded
    [n9,m9]=size(rd.PDATA);
    dat.dist=1:m9; % make the distance vector just the number of traces
    dat.ttime=rd.TWT; % set the two-way travel time
    dat.trace=rd.PDATA; % set the PSD data (radar image)
    dat.X=rd.xyz(:,1); % UTM easting
    dat.Y=rd.xyz(:,2); % UTM northing
end
%%%%%%%%%%%

handles.X=dat.dist; % distance along profile (m) -> x axis
t=dat.ttime; % travel time (s) -> y axis
handles.Y = t;
% Get image and normalize if selected
norm = cellstr(get(handles.popup_normalize,'String'));
norm = norm{get(handles.popup_normalize,'value')};
handles.norm=get(handles.popup_normalize,'value');
if strcmp(norm,'None           ')
    handles.data=dat.trace; 
elseif strcmp(norm,'By Max. Value  ')
    handles.data=dat.trace/(max(max(dat.trace)));
elseif strcmp(norm,'By Min. Value  ')
    handles.data=dat.trace/(min(min(dat.trace)));
elseif strcmp(norm,'By Mean Value  ')
    handles.data=dat.trace/(nanmean(nanmean(dat.trace)));
elseif strcmp(norm,'By Median Value')
    handles.data=dat.trace/(nanmedian(nanmedian(dat.trace)));
end

handles.dat=dat; % stores dat just incase we need to go back to its original values
handles.xmin=min(dat.dist);
handles.ymin=min(t);
handles.ymax=max(t);
handles.xmax=max(dat.dist);
% Plot Geometry if it Exists
% check for lat longs
if isfield(dat,'lon') && isfield(dat,'lat')
    handles.lat=dat.lat;
    handles.lon=dat.lon;
    handles.ll=1;
    plot(handles.geom_axes,dat.lon,dat.lat,'k.');
    set(handles.geom_axes,'linewidth',2,'fontweight','bold','fontsize',12)
    xlabel(handles.geom_axes,'Long.','fontweight','bold','fontsize',12)
    ylabel(handles.geom_axes,'Lat.','fontweight','bold','fontsize',12)
end
%Check for X-Y pts
if isfield(dat,'X') && isfield(dat,'Y')
    handles.XX=dat.X;
    handles.YY=dat.Y;
    handles.XY=1;
    plot(handles.geom_axes,dat.X,dat.Y,'k.');
    set(handles.geom_axes,'linewidth',2,'fontweight','bold','fontsize',12)
    xlabel(handles.geom_axes,'X','fontweight','bold','fontsize',12)
    ylabel(handles.geom_axes,'Y','fontweight','bold','fontsize',12)
end
%*************************************************************************
%*** End of important variables ******************************************
%*************************************************************************

% if the colorbar step doesnt exist yet it will be created now
if ~isfield(handles,'STEP')
    cmax=500;
    cmin=-500;
    cs_max=30000;
    cs_min=-30000;
    cs_step=20;   %set default step size for color slider
    css=cs_step/(cs_max-cs_min);   %calc what the dumb slider step is
    handles.STEP=css;
    % set slider and edit box properties for the colorbar
    set(handles.color_max_slider,'Max',cs_max)
    set(handles.color_max_slider,'Min',cs_min)
    set(handles.color_max_slider,'SliderStep',[css 0])
    set(handles.color_min_slider,'Max',cs_max)
    set(handles.color_min_slider,'Min',cs_min)
    set(handles.color_min_slider,'SliderStep',[css 0])
    set(handles.color_min_edit,'String',num2str(cmin))
    set(handles.color_max_edit,'String',num2str(cmax))
    set(handles.color_max_slider,'value',cmax)
    set(handles.color_min_slider,'value',cmin)
else
    set(handles.color_max_slider,'value',str2num(get(handles.color_max_edit,'string')))
    set(handles.color_min_slider,'value',str2num(get(handles.color_min_edit,'string')))
end

%set main axis to full dataset display on first load
set(handles.main_axes_xmin_edit,'String',num2str(handles.X(1)))
set(handles.main_axes_xmax_edit,'String',num2str(handles.X(length(handles.X))))
set(handles.main_axes_ymin_edit,'String',num2str(handles.Y(1)))
set(handles.main_axes_ymax_edit,'String',num2str(handles.Y(length(handles.Y))))

plot_main(handles)
plot_trace(handles)
guidata(hObject, handles);

% --- Executes on button press in trace_single_push.
function trace_single_push_Callback(hObject, eventdata, handles)
% hObject    handle to trace_single_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles,'average_trace_index') % if an average trace has been used remove it
    handles=rmfield(handles,'average_trace_index');
end

handles.trace=0;    %reset handles.trace value

[x,y]=ginput(1);                    %get input from mouse clicks
[~,Ix]=min(abs(handles.X-x)); % index of trace
handles.trace=x; % stores the location for later
handles.single_trace_index=Ix;%pass trace x coordinate
plot_trace(handles)                %plot the trace
plot_main(handles)                  %replot imagesc to clear previous lines
plot_geom(handles)

guidata(hObject, handles);

% --- Executes on button press in trace_avg_push.
function trace_avg_push_Callback(hObject, eventdata, handles)
% hObject    handle to trace_avg_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.trace=0;    %reset handles.trace value
if isfield(handles,'single_trace_index') % if a single trace has been used remove it
    handles=rmfield(handles,'single_trace_index');
end
    [x,y]=ginput(2);                %get both input from mouse clicks   
    [~, n(1)]=min(abs(x(1)-handles.X));      %find nearest index to 1st click
    [~, n(2)]=min(abs(x(2)-handles.X));      %find nearest index to 2nd click
    handles.average_trace_index=n; % store these indices for later
    handles.trace=x;            %pass trace positions for plotting
    handles.trace_position=mean(x); % average position of the trace
    plot_trace(handles)         %plot avg traces
    plot_main(handles)          %replot imagesc to clear previous lines
    plot_geom(handles)
guidata(hObject, handles);

function surf_find_edit_Callback(hObject, eventdata, handles)
% hObject    handle to surf_find_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of surf_find_edit as text
%        str2double(get(hObject,'String')) returns contents of surf_find_edit as a double


% --- Executes during object creation, after setting all properties.
function surf_find_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to surf_find_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in find_surf_push.
function find_surf_push_Callback(hObject, eventdata, handles)
% hObject    handle to find_surf_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

sthresh=str2num(get(handles.surf_find_edit,'String'));    %get thresh. value
temp=handles.data; % copy the image
if isempty(sthresh)     %if no surface thresh. value entered
    h=msgbox('Surface Threshold Needed','ERROR','warn');
    set(h,'color',[153 193 203]/255)
else%if a surface thresh. value entered
    for ii=1:size(handles.data,2)
        ind1=find(handles.data(:,ii)>sthresh,1,'first');  %find last value above surface threshold
        if isempty(ind1)==1     %if no value over threshold
            sval(ii)=NaN;       %assign NaN
        else                    %if value found
            sval(ii)=handles.Y(ind1(1));  %get actual depth values, ignore more than 1
        end
    end
    handles.Ypick=sval;
    handles.Xpick=handles.X;
    handles.data=temp;
    plot_trace(handles)                        %replot trace
    plot_main(handles)                         %replot main imagesc
end
handles.data=temp;
guidata(hObject, handles);

% --- Executes on button press in use_thresh_radio.
function use_thresh_radio_Callback(hObject, eventdata, handles)
% hObject    handle to use_thresh_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of use_thresh_radio



function ground_find_edit_Callback(hObject, eventdata, handles)
% hObject    handle to ground_find_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ground_find_edit as text
%        str2double(get(hObject,'String')) returns contents of ground_find_edit as a double


% --- Executes during object creation, after setting all properties.
function ground_find_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ground_find_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in find_ground_push.
function find_ground_push_Callback(hObject, eventdata, handles)
% hObject    handle to find_ground_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
gthresh=str2num(get(handles.ground_find_edit,'String'));    %get thresh. value
if isempty(gthresh)==1          %if no thresh value entered
    h=msgbox('Ground Threshold Needed','ERROR','warn');
    set(h,'color',[153 193 203]/255)
else                            %if thresh value entered
    for ii=1:size(handles.data,2)   %loop over ever x-position
        ind1=find(handles.data(:,ii)>gthresh,1,'last');  %find last value above surface threshold
        if isempty(ind1)==1     %if no value over threshold
            gval(ii)=NaN;           %assign NaN
        else                    %if value found
            gval(ii)=handles.Y(ind1(1));  %get actual depth values, ignore more than 1
        end
    end
    
    handles.Ypick=gval;
    handles.Xpick=handles.X;
    
    plot_main(handles)                         %replot main imagesc
    plot_trace(handles)                        %replot trace
end
guidata(hObject, handles);


function color_min_edit_Callback(hObject, eventdata, handles)
% hObject    handle to color_min_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of color_min_edit as text
%        str2double(get(hObject,'String')) returns contents of color_min_edit as a double


% --- Executes during object creation, after setting all properties.
function color_min_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to color_min_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function color_max_edit_Callback(hObject, eventdata, handles)
% hObject    handle to color_max_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of color_max_edit as text
%        str2double(get(hObject,'String')) returns contents of color_max_edit as a double


% --- Executes during object creation, after setting all properties.
function color_max_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to color_max_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function main_axes_xmin_edit_Callback(hObject, eventdata, handles)
% hObject    handle to main_axes_xmin_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of main_axes_xmin_edit as text
%        str2double(get(hObject,'String')) returns contents of main_axes_xmin_edit as a double


% --- Executes during object creation, after setting all properties.
function main_axes_xmin_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to main_axes_xmin_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function main_axes_xmax_edit_Callback(hObject, eventdata, handles)
% hObject    handle to main_axes_xmax_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of main_axes_xmax_edit as text
%        str2double(get(hObject,'String')) returns contents of main_axes_xmax_edit as a double


% --- Executes during object creation, after setting all properties.
function main_axes_xmax_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to main_axes_xmax_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function main_axes_ymin_edit_Callback(hObject, eventdata, handles)
% hObject    handle to main_axes_ymin_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of main_axes_ymin_edit as text
%        str2double(get(hObject,'String')) returns contents of main_axes_ymin_edit as a double


% --- Executes during object creation, after setting all properties.
function main_axes_ymin_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to main_axes_ymin_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function main_axes_ymax_edit_Callback(hObject, eventdata, handles)
% hObject    handle to main_axes_ymax_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of main_axes_ymax_edit as text
%        str2double(get(hObject,'String')) returns contents of main_axes_ymax_edit as a double


% --- Executes during object creation, after setting all properties.
function main_axes_ymax_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to main_axes_ymax_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in zoom_in_push.
function zoom_in_push_Callback(hObject, eventdata, handles)
% hObject    handle to zoom_in_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[x,y]=ginput(2);                    %get both input from mouse clicks
if x(1)>x(2) % clicking from right to left
    [~,nx(2)]=min(abs(x(1)-handles.X)); %find nearest cell index to 1st click
    [~,nx(1)]=min(abs(x(2)-handles.X)); %find nearest cell index to 2nd click
elseif x(2)>x(1) % clicking from left to right
    [~,nx(1)]=min(abs(x(1)-handles.X)); %find nearest cell index to 1st click
    [~,nx(2)]=min(abs(x(2)-handles.X)); %find nearest cell index to 2nd click
else
    return
end
if y(1)>y(2) % clicking from down to up
    [~,ny(2)]=min(abs(y(1)-handles.Y)); %find nearest cell index to 1st click
    [~,ny(1)]=min(abs(y(2)-handles.Y)); %find nearest cell index to 2nd click
elseif y(2)>y(1) % clicking from up to down
    [~,ny(1)]=min(abs(y(1)-handles.Y)); %find nearest cell index to 1st click
    [~,ny(2)]=min(abs(y(2)-handles.Y)); %find nearest cell index to 2nd click
else
    return
end
set(handles.main_axes_xmin_edit,'String',num2str(min(handles.X(nx))))   %set edit box value
set(handles.main_axes_xmax_edit,'String',num2str(max(handles.X(nx))))   %set edit box value
set(handles.main_axes_ymin_edit,'String',num2str(min(handles.Y(ny))))   %set edit box value
set(handles.main_axes_ymax_edit,'String',num2str(max(handles.Y(ny))))   %set edit box value

plot_main(handles)                  %replot imagesc zoomed in
plot_trace(handles)


% --- Executes on button press in zoom_out_push.
function zoom_out_push_Callback(hObject, eventdata, handles)
% hObject    handle to zoom_out_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% reset everything to full extent
set(handles.main_axes_xmin_edit,'String',num2str(handles.X(1)))
set(handles.main_axes_xmax_edit,'String',num2str(handles.X(length(handles.X))))
set(handles.main_axes_ymin_edit,'String',num2str(handles.Y(1)))
set(handles.main_axes_ymax_edit,'String',num2str(handles.Y(length(handles.Y))))

plot_main(handles)
plot_trace(handles)


% % --- Executes on slider movement.
% function main_axes_scroll_Callback(hObject, eventdata, handles)
% % hObject    handle to main_axes_scroll (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
% 
% % Hints: get(hObject,'Value') returns position of slider
% %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
% 
% %find current zoom
% x1=str2double(get(handles.main_axes_xmin_edit,'String'));
% x2=str2double(get(handles.main_axes_xmax_edit,'String'));
% dx=x2-x1;
% L=handles.X(length(handles.X));         %set L as last value in x-axis
% 
% xpos=get(hObject,'Value');     %get current scroll position
% 
% xmin=xpos*L-dx/2;
% xmax=xpos*L+dx/2;
% 
% if xmin < handles.X(1)           %if plot to far left
%     xpos=(dx/2)/L;                  %xpos=furthest left without going to far
%     xmin=xpos*L-dx/2;
%     xmax=xpos*L+dx/2;
%     set(handles.main_axes_xmin_edit,'String',num2str(xmin))
%     set(handles.main_axes_xmax_edit,'String',num2str(xmax))
%     plot_main(handles)
% elseif xmax > handles.X(length(handles.X))    %if plot to far right
%     xpos=(L-dx/2)/L;        %xpos=furthest right without going to far
%     xmin=xpos*L-dx/2;
%     xmax=xpos*L+dx/2;
%     set(handles.main_axes_xmin_edit,'String',num2str(xmin))
%     set(handles.main_axes_xmax_edit,'String',num2str(xmax))
%     plot_main(handles)
% else                                %otherwise just plot
%     set(handles.main_axes_xmin_edit,'String',num2str(xmin))
%     set(handles.main_axes_xmax_edit,'String',num2str(xmax))
%     plot_main(handles)
% end
% 
% 
% % --- Executes during object creation, after setting all properties.
% function main_axes_scroll_CreateFcn(hObject, eventdata, handles)
% % hObject    handle to main_axes_scroll (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    empty - handles not created until after all CreateFcns called
% 
% % Hint: slider controls usually have a light gray background.
% if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
%     set(hObject,'BackgroundColor',[.9 .9 .9]);
% end

% --- Executes on button press in delete_layers_push.
function delete_layers_push_Callback(hObject, eventdata, handles)
% hObject    handle to delete_layers_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


laynums=get(handles.layers_listbox,'value'); %get index os selected layers
if isempty(laynums)
    return
end
handles.highlays.inds=[];laynums;            %to highligh selected layers
for ii=1:length(laynums)
    hold(handles.main_axes,'on')
    plot(handles.layers(laynums(ii)).X,handles.layers(laynums(ii)).Y,'m*')
end
%plot_main(handles)
% Construct a questdlg with yes/no options
% Construct a questdlg with three options
arg=[];
for j = 1:length(laynums); % String containing layers in question
    if j ~= length(laynums)
        arg=[arg handles.layers(laynums(j)).Label ', '];
    elseif j==1
        arg=[arg handles.layers(j).Label];
    else
        arg = [arg 'and ' handles.layers(j).Label];
    end
end
choice = questdlg(['Delete these layers?'],...
    'User Input Required','Yes','No','Yes');
% Handle response
switch choice
    case 'Yes'      %if yes selected
        handles.handles=handles;
        handles=delete_layers(laynums,handles);  %delete selected layers
        
        handles.highlays.inds=[];           %reset layer highlighting
        handles.highlays.p1=[];             %reset layer highlighting
        handles.highlays.p2=[];             %reset layer highlighting
        
        plot_trace(handles)                 %replot trace
        plot_main(handles)                  %replot main imagesc
    case 'No'
        handles.highlays.inds=[];           %reset layer highlighting
        handles.highlays.p1=[];             %reset layer highlighting
        handles.highlays.p2=[];             %reset layer highlighting
        % plot_main(handles)                  %replot main imagesc
        for j=1:length(laynums)
            hold(handles.main_axes,'on')
            plot(handles.layers(laynums(j)).X,handles.layers(laynums(j)).Y,'w*')
        end
end

guidata(hObject,handles)




% --- Executes on slider movement.
function color_min_slider_Callback(hObject, eventdata, handles)
% hObject    handle to color_min_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

cmin=get(handles.color_min_slider,'Value');  %get color scale min
set(handles.color_min_edit,'String',num2str(cmin)); %set color max edit
plot_main(handles)  %replot main_axes
plot_trace(handles)


% --- Executes during object creation, after setting all properties.
function color_min_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to color_min_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function color_max_slider_Callback(hObject, eventdata, handles)
% hObject    handle to color_max_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

cmax=get(handles.color_max_slider,'Value');  %get color scale max
set(handles.color_max_edit,'String',num2str(cmax)); %set color max edit
plot_main(handles)  %replot main_axes
plot_trace(handles)



% --- Executes during object creation, after setting all properties.
function color_max_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to color_max_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in find_point_push.
function find_point_push_Callback(hObject, eventdata, handles)
% hObject    handle to find_point_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

get(handles.trace_click_radio,'Value');      %get on/off of trace_clcick_radio
handles.trace=0;    %reset handles.trace value

[x,y]=ginput(1);                    %get input from mouse clicks

if gca==handles.trace_axes  %if click from trace_axes
    xmin=min(min(handles.data));    %current x-min of plot
    xmax=max(max(handles.data));    %current x-max of plot
    ymin=min(handles.Y);            %current y-min of plot
    ymax=max(handles.Y);            %current y-max of plot
    if x >= xmin && x <= xmax && y >= ymin && y <= ymax %if click is actually in axes
        set(handles.find_pointX_edit,'String',num2str(x))   %set edit to x from click
        set(handles.find_pointY_edit,'String',num2str(y))   %set edit to y from click
        
        hold(handles.trace_axes,'on')
        plot(handles.trace_axes,[xmin xmax],[y y], ':r')
        plot(handles.trace_axes,[x x],[ymin ymax], ':r')
        hold(handles.trace_axes,'off')
    else
        disp('Please click inside the TRACE axes')
    end
else
    disp('Please click inside the TRACE axes')
end


guidata(hObject, handles);


function find_pointX_edit_Callback(hObject, eventdata, handles)
% hObject    handle to find_pointX_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of find_pointX_edit as text
%        str2double(get(hObject,'String')) returns contents of find_pointX_edit as a double


% --- Executes during object creation, after setting all properties.
function find_pointX_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to find_pointX_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function find_pointY_edit_Callback(hObject, eventdata, handles)
% hObject    handle to find_pointY_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of find_pointY_edit as text
%        str2double(get(hObject,'String')) returns contents of find_pointY_edit as a double


% --- Executes during object creation, after setting all properties.
function find_pointY_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to find_pointY_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in merge_layers_push.
function merge_layers_push_Callback(hObject, eventdata, handles)
% hObject    handle to merge_layers_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ztol=str2num(get(handles.ztol_edit,'String'));
laynum=get(handles.layers_listbox,'value'); %get index os selected layers
if length(laynum)<2     %if less than 2 layers selected throw errordlg
    err{1}='Must Have at Least TWO Layers';
    err{2}='Selected to Perform Action:';
    err{3}='           MERGE LAYERS';
    h=msgbox(err,'ERROR!','warn');
    set(h,'color',[153 193 203]/255)
    return
end

xtmp=[]; % contains xpositions of all layers for merge
ytmp=[]; % contains twt of all layers for merge
xcoord=[];
ycoord=[];
for ii=1:length(laynum)        %for each layer selected
    [~,t1]=min(abs(handles.layers(laynum(ii)).X(1)-handles.X)); % beginning index of each layer
    [~,t2]=min(abs(handles.layers(laynum(ii)).X(end)-handles.X)); % ending index of each layer
    Ix(ii,:)=[t1 t2]; % index positions for beginning and ends of each layer
    xtmp=[xtmp handles.layers(laynum(ii)).X];
    ytmp=[ytmp; handles.layers(laynum(ii)).Y(:)];
    check=1;
end
    % Check if layers have a coordinate system and store the x-y pts if
    % they do
    if isfield(handles.layers(laynum(ii)),'Xcoord')
       [~,I]=min(abs(handles.X-min(xtmp)));
       [~,I2]=min(abs(handles.X-max(xtmp)));
       xcoord = handles.XX(I:I2);
       ycoord = handles.YY(I:I2);
       opt{1}=xcoord;
       opt{2}=ycoord;
       opt{3}='xy';
    elseif isfield(handles.layers(laynum(ii)),'lat')
        [~,I]=min(abs(handles.X-min(xtmp)));
        [~,I2]=min(abs(handles.X-max(xtmp)));
        xcoord = handles.lon(I:I2);
        ycoord = handles.lat(I:I2);
        opt{1}=xcoord;
        opt{2}=ycoord;
        opt{3}='ll';
    else
        ccheck=0;
        opt=[];
    end
% sort in asceding order
[xtmp,IS]=sort(xtmp);
ytmp=ytmp(IS);
% check for overlaped layers
[xtmp,m,~]=unique(xtmp);
ytmp=ytmp(m); % discard overlaped values
IG=find(diff(xtmp)>mean(diff(handles.X))*1.1); % index of any gaps
Ix=Ix';
S=size(Ix);
handles.highlays.inds=laynum; % to highligh selected layers
for ii=1:length(laynum)
    hold(handles.main_axes,'on')
    plot(handles.main_axes,handles.layers(laynum(ii)).X,...
        handles.layers(laynum(ii)).Y,'m*')
end
% Construct a questdlg with three options
arg=[];
for j = 1:length(laynum); % String containing layers in question
    if j ~= length(laynum)
        arg=[arg handles.layers(j).Label ', '];
    else
        arg = [arg 'and ' handles.layers(j).Label];
    end
end
choice = questdlg(['Are you sure you want to merge ' arg '?'],...
    'User Input Required','Yes','No','Yes');
% Handle response
switch choice
    case 'Yes'      %if yes selected merge the layers
        if ~isempty(IG)
            Igap=[IG;IG+1]';
            if length(IG)>1
                lg=length(Igap);
            else
                lg=1;
            end
            for j = 1:lg
                II=find(ismember(handles.X,xtmp(Igap(j,:))));% indicies to interpolate between
                xi=handles.X(II(1):II(2));
                P=polyfit(xtmp(Igap(j,:)),ytmp(Igap(j,:))',1);
                yitmp=polyval(P,xi);
                for M = 1:length(yitmp) % snap interp to peaks
                    [~,IX]=min(abs(xi(M)-handles.X));
                    [~,Iy]=min(abs(yitmp(M)-handles.Y));
                    win=Iy-ztol:Iy+ztol;
                    [~,Imin]=min(abs(handles.data(win,IX)));
                    yi(M)=handles.Y(win(Imin));
                end
                xtmp=[xtmp(:); xi(:)]';
                ytmp=[ytmp(:); yi(:)];
                clear xi yi
            end
            [xtmp,IS]=sort(xtmp);
            ytmp=ytmp(IS);clc
            [xtmp,m,~]=unique(xtmp);
            ytmp=ytmp(m); % discard overlaped values
            handles=add_layer(xtmp,ytmp,'New Merged Layer',opt,handles);  %add merged layer
        else
            handles=add_layer(xtmp,ytmp,'New Merged Layer',opt,handles);  %add merged layer
        end
    case 'No'       %if no selected
        for ii=1:length(laynum)
            plot(handles.main_axes,handles.layers(laynum(ii)).X,...
                handles.layers(laynum(ii)).Y,'w*')
        end
    case ''
        for ii=1:length(laynum)
            plot(handles.main_axes,handles.layers(laynum(ii)).X,...
                handles.layers(laynum(ii)).Y,'w*')
        end
end


handles.highlays.inds=[];       %reset layer highlighting
handles.highlays.p1=[];         %reset layer highlighting
handles.highlays.p2=[];         %reset layer highlighting
plot_main(handles)              %replot main imagesc
plot_trace(handles)             %replot trace



guidata(hObject, handles);


% --- Executes on selection change in layers_listbox.
function layers_listbox_Callback(hObject, eventdata, handles)
% hObject    handle to layers_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns layers_listbox contents as cell array
%        contents{get(hObject,'Value')} returns selected item from layers_listbox


% --- Executes during objeuntitled.pngct creation, after setting all properties.
function layers_listbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to layers_listbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in rename_layer_push.
function rename_layer_push_Callback(hObject, eventdata, handles)
% hObject    handle to rename_layer_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.handles=handles;

laynum=get(handles.layers_listbox,'value');     %get selected layer indicies

if length(laynum)==1                   %if 1 layer selected
    rname_prmp=sprintf([['Rename ',handles.layers(laynum).Label], ' as:']); % create prompt message for layer rename
    new_lbl=inputdlg(rname_prmp,'Renaming...'); % gui user input
    %new_lbl=input('Enter new layer label >','s');   %get label as string
    if ~strcmp(char(new_lbl),'') % make sure cancel wasnt pressed
        handles.layers(laynum).Label=char(new_lbl); % set new label
    end
else                                    %if anything but 1 layer is selected
    h=msgbox('Please select a single layer to rename.','Rename Error','warn'); % gui warning
    set(h,'color',[153 193 203]/255)
end

labels=get_layer_labels(handles);               %get layer labels
set(handles.layers_listbox,'value',1:length(handles.layers)) %give listbox right values
set(handles.layers_listbox,'string',labels)     %make listbox display layers

guidata(hObject, handles)


% --- Executes on button press in highlight_layer_push.
function highlight_layer_push_Callback(hObject, eventdata, handles)
% hObject    handle to highlight_layer_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

laynums=get(handles.layers_listbox,'value');    %get selected layer indicies

if isempty(laynums)==1  %if no layers selected
    handles.highlays.inds=[];    %reset layers to highlight
    handles.highlays.p1=[];      %reset start point of highlights
    handles.highlays.p2=[];      %teset end points of highlights
else
    % remove any previous highlighting
    for j = 1:length(handles.layers);
        hold(handles.main_axes,'on')
        plot(handles.layers(j).X,handles.layers(j).Y,'w*')
    end
    %if layers selected
    for ii=1:length(laynums)     %loop over selected layers
        p1(ii)=1;                       %first pt of layer to plot
        p2(ii)=length(handles.X);       %last pt of layer to plot
        hold(handles.main_axes,'on')
        plot(handles.layers(laynums(ii)).X,handles.layers(laynums(ii)).Y,'m*')
    end
    handles.highlays.inds=laynums;    %indicies of layers to highlight
    handles.highlays.p1=p1;          %starting point of highlights
    handles.highlays.p2=p2;          %ending points of highlights
end
%plot_main(handles)


guidata(hObject, handles)


% --- Executes on button press in clear_section_push.
function clear_section_push_Callback(hObject, eventdata, handles)
% hObject    handle to clear_section_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.handles=handles;

laynum=get(handles.layers_listbox,'value');  %get selected layer's index
if length(laynum)==1    %if  1 layer selected
    [x,~]=ginput(2);        %get 2 clicked points
    [~, pt1]=min(abs(min(x)-handles.X));      %find closet index to min click
    [~, pt2]=min(abs(max(x)-handles.X));      %find closet index to max click
    
    handles.highlays.inds=laynum;        %highlight selected layer
    handles.highlays.p1=pt1;            %index of start of highlight
    handles.highlays.p2=pt2;            %index of end of highlight
    
    plot_main(handles)
    %Construct a questdlg with Yes/No buttons
    choice = questdlg('Are you sure you want to clear this section?',...
        'Need your input','Yes','No','Yes');
    % Handle response
    switch choice
        case 'Yes'      %if yes
            handles.layers(laynum).Y(pt1:pt2)=[];  %delete selection
            handles.layers(laynum).X(pt1:pt2)=[];
            % remove coordinates if there are any
            if isfield(handles.layers(laynum),'Xcoord')
                handles.layers(laynum).Xcoord(pt1:pt2)=[];
                handles.layers(laynum).Ycoord(pt1:pt2)=[];
                
            elseif isfield(handles.layers(laynum),'lon')
                handles.layers(laynum).lon(pt1:pt2)=[];
                handles.layers(laynum).lat(pt1:pt2)=[];
            end
            
            %reset highlights
            handles.highlays.inds=[];
            handles.highlays.p1=[];
            handles.highlays.p2=[];
            plot_main(handles)
        case 'No'       %if no
            %reset highlights
            handles.highlays.inds=[];
            handles.highlays.p1=[];
            handles.highlays.p2=[];
            plot_main(handles)
    end
    
else                    %otherwise
    h=msgbox('Please Select ONE Layer','Highlight Error','warn'); % gui warning
    set(h,'color',[153 193 203]/255)
end

guidata(hObject, handles)


% --- Executes on button press in load_layers_push.
function load_layers_push_Callback(hObject, eventdata, handles)
% hObject    handle to load_layers_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
filtspec = [handles.ppath];
[fn,pth]=uigetfile(filtspec,'Load Picks');  %get file name
if ~ischar(fn) || ~ischar(pth)
    return
else
    load([pth fn]);%load data from file
end
for ii=1:length(Layers) %loop over each layer to load
    if isfield(Layers(ii),'Xcoord')
        opt{1}=Layers(ii).Xcoord;
        opt{2}=Layers(ii).Ycoord;
        opt{3}='xy';
    elseif isfield(Layers(ii),'lat')
        opt{1}=Layers(ii).lon;
        opt{2}=Layers(ii).lat;
        opt{3}='ll';
    else
        opt=[];
    end
    handles = add_layer(Layers(ii).X,Layers(ii).Y,Layers(ii).Label,opt,handles); %add layer
end
plot_main(handles)
plot_trace(handles)

guidata(hObject, handles)



% % --- Executes on button press in flatten_layer_push.
function flatten_layer_push_Callback(hObject, eventdata, handles)
% % hObject    handle to flatten_layer_push (see GCBO)
% % eventdata  reserved - to be defined in a future version of MATLAB
% % handles    structure with handles and user data (see GUIDATA)
%
handles.handles=handles;

laynum=get(handles.layers_listbox,'value');
if length(laynum)~=1
    h=msgbox('Please Select only ONE Layer','Flatten Layer Error','warn'); % gui warning
    set(h,'color',[153 193 203]/255)
elseif length(laynum)==0
    h=msgbox('Please Select only ONE Layer','Flatten Layer Error','warn'); % gui warning
    set(h,'color',[153 193 203]/255)
else
    M=max(handles.layers(laynum).Y);
    [~,Imax]=min(abs(handles.Y-M)); % index of first reflection from layer laynum
    for j=1:length(handles.layers(laynum).Y)
        [~,I(j)]=min(abs(handles.Y-handles.layers(laynum).Y(j)));
        [~,Ix]=min(abs(handles.X-handles.layers(laynum).X(j)));
        dI(j)=Imax-I(j);
        handles.data(:,Ix)=circshift(handles.data(:,Ix),dI(j));
        handles.layers(laynum).Y(j)=handles.Y(Imax);
        %dT(j)=handles.layers(laynum).Y(Imax)-handles.Y(I(j));
    end
    for ii = 1:length(handles.layers)
        if ii ~=laynum
            if length(handles.layers(laynum).X)>=length(handles.layers(ii).X)
                [~,II(1)]=min(abs(handles.layers(laynum).X-handles.layers(ii).X(1)));
                [~,II(2)]=min(abs(handles.layers(laynum).X-handles.layers(ii).X(end)));
                for jj = 1:length(handles.layers(laynum).X(II(1):II(2)));
                    [~,Iy]=min(abs(handles.layers(ii).Y(jj) - handles.Y));
                    handles.layers(ii).Y(jj)=handles.Y(Iy+dI(II(1)-1+jj));
                end
            else
                [~,II(1)]=min(abs(handles.layers(laynum).X(1)-handles.layers(ii).X));
                [~,II(2)]=min(abs(handles.layers(laynum).X(end)-handles.layers(ii).X));
                for jj = 1:length(handles.layers(laynum).X);
                    [~,Iy]=min(abs(handles.layers(ii).Y(II(1)+jj-1) - handles.Y));
                    handles.layers(ii).Y(II(1)+jj-1)=handles.Y(dI(jj)+Iy);
                end
            end
        end
    end
end

plot_main(handles)
guidata(hObject, handles)


% *******************************************************************************
% *******************************************************************************
% *** User Functions + any newly created or callbacks, but they can be moved above to
% *** keep user functions at bottom to make them easier to find.


% *** Plot or replot the main imagesc
function plot_main(handles)
%   inputs: handles - gives axis to all gui variables
xmin=str2num(get(handles.main_axes_xmin_edit,'String'));   %get xmin value from edit input
xmax=str2num(get(handles.main_axes_xmax_edit,'String'));   %get xmin value from edit input
ymin=str2num(get(handles.main_axes_ymin_edit,'String'));   %get xmin value from edit input
ymax=str2num(get(handles.main_axes_ymax_edit,'String'));   %get xmin value from edit input
[~,x1]=min(abs(xmin-handles.X));        %find index nearest xmin
[~,x2]=min(abs(xmax-handles.X));        %find index nearest xamx
[~,y1]=min(abs(ymin-handles.Y));       %find index nearest ymin
[~,y2]=min(abs(ymax-handles.Y));       %find index nearest ymax
s=size(handles.data);
if x2>s(2)
    x2=x2-(x2-s(2));
end

cmin=str2num(get(handles.color_min_edit,'String')); %get min color scale value from edit input
cmax=str2num(get(handles.color_max_edit,'String')); %get max color scale value from edit input

my_axe(1)=handles.main_axes;    %set axes handles to single var
my_axe(2)=handles.trace_axes;   %set axes handles to single var
linkaxes(my_axe,'y');           %lock y scale for plots

% *** Plot main imagesc
subplot(handles.main_axes);             %trick imagesc to plot to the right axes
%imagesc(handles.X(x1:x2),handles.Y(y1:y2),handles.data(y1:y2,x1:x2),[cmin cmax]); grid off; %replot imagesc
imagesc(handles.X,handles.Y,handles.data,[cmin cmax]); grid off; %replot imagesc
hold(handles.main_axes,'on')
axis([xmin xmax ymin ymax])
xlabel('X-Pos','fontweight','bold','fontsize',24)
ylabel('TWT','fontweight','bold','fontsize',24)
H=colorbar('EastOutside');set(H,'fontweight','bold','fontsize',15,'linewidth',2)
% if isfield(handles,'cmap')
%     colorbar(handles.cmap);
% else
%     colorbar('default')
% end
% *** Plot layers
if isempty(handles.layers(1).X)==1      %if no layers, skip
else                    %otherwise plot all layers
    for ii=1:size(handles.layers,2)
        %plots all layers
        plot(handles.main_axes,handles.layers(ii).X,handles.layers(ii).Y,...
            'w*','markersize',5,'LineWidth',2)
    end
end

% *** highlight layers with variable ranges
if isempty(handles.highlays(1).inds)==1 %if no layers to highlight, skip
else
    for ii=1:length(handles.highlays.inds)   %loop over each layer to highlight
        ind=handles.highlays.inds(ii);         %current layer index
        pt1=handles.highlays.p1(ii);            %current layer start pt
        pt2=handles.highlays.p2(ii);            %current layer end pt
        %highlight current layer from pt1 to pt2
        plot(handles.main_axes,handles.layers(ind).X(pt1:pt2),handles.layers(ind).Y(pt1:pt2),...
            'm*','markersize',5,'LineWidth',2)
    end
end

% *** plot traces on imagesc
%   handles.traces=[x1 x2 x3 x4] where xi are
%   x-positions to plot the traces at.
%   handles.traces=0 plots no trace.

if handles.trace==0                     %if handles.trace=0, plot no trace on imagesc
else
    %[~, trace_ind]=min(abs(handles.trace-handles.X));    %find nearest index to input
    for ii=1:length(handles.trace)
        plot(handles.main_axes,[handles.trace(ii) handles.trace(ii)],...
            [min(handles.Y) max(handles.Y)],'w--','LineWidth',2)
    end
end

% *** plots current Xpick and Ypick values
if isempty(handles.Xpick)==1 %if no values to plot, skip
else                        %otherwise, values to plot
    plot(handles.main_axes,handles.Xpick,handles.Ypick,'m*','markersize',10,'LineWidth',2)
end
hold(handles.main_axes,'off')
set(gca,'fontweight','bold','fontsize',15,'linewidth',2)
guidata(handles.output, handles)



% *** Plot or replot the traces plot
function plot_trace(handles)
%   inputs: handles - gives axis to all gui variables
%           trace_num - X-Position of trace(s) to plot.
%           EX:     trace_num=100 - trace at 100
%                   trace_num=(100,200) - avg trace between 100, 200

ymin=str2num(get(handles.main_axes_ymin_edit,'String'));   %get xmin value from edit input
ymax=str2num(get(handles.main_axes_ymax_edit,'String'));   %get xmin value from edit input
cmin=str2num(get(handles.color_min_edit,'String')); %get min color scale value from edit input
cmax=str2num(get(handles.color_max_edit,'String')); %get max color scale value from edit input



if size(handles.trace,1)==1     %if 1 trace
    [~, n]=min(abs(handles.trace-handles.X));    %find nearest index to input
    %set(handles.trace_single_edit,'String',num2str(handles.trace))  %set edit box value
    set(handles.trace_num_text,'String',['Trace: ',num2str(n)])     %set trace # text
    
    %plot in trace_axes
    plot(handles.trace_axes,handles.data(:,n),handles.Y,'b','LineWidth',2)
    hold(handles.trace_axes,'on')
    set(gca,'fontweight','bold','fontsize',15)
    % *** Plot layers in current trace on trace_axes
    if ~isempty(handles.layers(1).X)       %if no layers, skip
                  %otherwise plot all layers
        for ii=1:size(handles.layers,2)
            t_pos=handles.trace; %get trace pos
            lay_xmin=min(handles.layers(ii).X);   %find min x pos of layer
            lay_xmax=max(handles.layers(ii).X);   %find min y pos of layer
            
            if t_pos >= lay_xmin & t_pos <= lay_xmax   %if trace crosses layer
                %gets x-index of layer position closest to trace
                [~, x_ind]=min(abs(handles.trace-handles.layers(ii).X));
                ypos=handles.layers(ii).Y(x_ind);     %finds y pos of layer
                [~, y_ind]=min(abs(ypos-handles.Y)); %finds the y-pos index
                
                %plot layer point in trace_axes
                if handles.data(y_ind,x_ind)<=cmax
                    plot(handles.trace_axes,handles.data(y_ind,x_ind),ypos,'rx','LineWidth',3)
                else
                    plot(handles.trace_axes,cmax,ypos,'rx','LineWidth',3)
                end
            end
        end
    end
    hold(handles.trace_axes,'off')
    %axis(handles.trace_axes,[min(min(handles.data)) max(max(handles.data)) ymin ymax])
    set(handles.trace_axes,'YDir','reverse')        %plot to match iamgesc
     axis(handles.trace_axes,[cmin cmax ymin ymax])
   
elseif size(handles.trace,1)==2     %if 2 traces
    [~, n(1)]=min(abs(handles.trace(1)-handles.X));    %find nearest index to input
    [~, n(2)]=min(abs(handles.trace(2)-handles.X));    %find nearest index to input
    
    %plot in trace_axes
    plot(handles.trace_axes,mean(handles.data(:,min(n):max(n)),2),handles.Y,'b','LineWidth',2)
    %scales axis nicely
    axis(handles.trace_axes,[cmin cmax ymin ymax])
    set(handles.trace_axes,'ydir','reverse')
end
set(handles.trace_axes,'fontweight','bold','linewidth',2,'fontsize',15)
set(handles.trace_axes,'xlim',[cmin cmax]);
hold(handles.trace_axes,'off')


% *** function to add layer information based on X & Y position vectors
function handles = add_layer(X,Y,label,opt,handles)
%   Inputs: X - 1-D vector of horizonal positions, dimension match Y
%           Y - 1-D vector of vertical positions, dimension match X
%           xx - contains long. or x values
%           yy - contains lat. or y values
%           check - 'xy' for x-y points 'll' for lat long points
%           label - label for the layer, string.
%           handles needed to pass vars
%           NOTE: Only 1 layer can be added at a time
%   Output: is handles because subfunctions don't pass variables the same
%           way as GUIDE generated functions and this is the easiest work around I found.
handles.handles=handles;

%make data into row vectors for storing
if size(X,1) > size(X,2)    %if more rows than columns
    X=X';       %make X row vector
    Y=Y';       %Make Y row vector
end
if ~isempty(opt)
    xx=opt{1};
    yy=opt{2};
    check=opt{3};
else
    check='none';
end
if isempty(handles.layers(1).X)==1               %if no layers
    handles.layers(1).X=X;                  %assign X data w/NaN padding
    handles.layers(1).Y=Y;                  %assign Y data w/NaN padding
    handles.layers(1).Label=label;          %assign layer name
    if strcmp(check,'ll') % if there are coordinates add them also
        handles.layers(1).lon=opt(1);
        handles.layers(1).lat=opt(2);
        handles.layers(1).coord='ll';
    elseif strcmp(check,'xy')
        handles.layers(1).Xcoord=xx;
        handles.layers(1).Ycoord=yy;
        handles.layers(1).coord='xy';
    else
        handles.layers(1).coord='none';
    end
    
else                                    %otherwise
    new_row=size(handles.layers,2)+1;       %get ind of next row
    handles.layers(new_row).X=X;            %assign X data w/NaN padding
    handles.layers(new_row).Y=Y;            %assign Y data w/NaN padding
    handles.layers(new_row).Label=label;    %assign layer name
    if strcmp(check,'ll')% if there are coordinates add them also
        handles.layers(new_row).lon=xx;
        handles.layers(new_row).lat=yy;
        handles.layers(new_row).coord='ll';
    elseif strcmp(check,'xy')
        handles.layers(new_row).lon=xx;
        handles.layers(new_row).lat=yy;
        handles.layers(new_row).coord='xy';
    else
        handles.layers(new_row).coord='none';
    end
end

labels=get_layer_labels(handles);  %get layer labels
set(handles.layers_listbox,'value',1:length(handles.layers)) %give listbox right values
set(handles.layers_listbox,'string',labels) %make listbox display layers



% *** function to delete layers and move previous layers 'up'
function handles = delete_layers(laynums,handles)
%   Inputs: laynum - indicies of layers to be removed
%           handles needed to pass vars
%   Output: is handles because subfunctions don't pass variables the same
%           way as GUIDE generated functions and this is the easiest work around I found.
handles.handles=handles;

lays.X=[];      %init. layer x storage
lays.Y=[];      %init. layer y storage
lays.Label=[];  %init. layer label storage
ind=0;          %initialize index counter

if length(laynums)==length(handles.layers)  %if all layers deleted
    handles=rmfield(handles,'layers');  %clear layers field entirely
    handles.layers.X=[];                %reset first layer x to empty
    handles.layers.Y=[];                %reset first layer y to empty
    handles.layers.Label=[];            %reset first layer label to empty
    set(handles.layers_listbox,'value',[]) %give listbox right values
    set(handles.layers_listbox,'string',[]) %make listbox display layers
else                            %if not all layers deleted
    for ii=1:length(handles.layers)  %loop over all layers
        if isempty(find(ii==laynums))   %if not one of the layers to be removed
            ind=ind+1;                          %increase counter
            lays(ind).X=handles.layers(ii).X;   %pass X values
            lays(ind).Y=handles.layers(ii).Y;   %pass X values
            lays(ind).Label=handles.layers(ii).Label;   %pass layer label
        end
    end
    handles.layers=lays;                %assigns layer values
    labels=get_layer_labels(handles);  %get layer labels
    set(handles.layers_listbox,'value',1:length(handles.layers)) %give listbox right values
    set(handles.layers_listbox,'string',labels) %make listbox display layers
end



% *** function to return the actual number of layers
function numL=num_layers(handles)
%   Inputs: handles - needed to pass variables
%   Output: numL - returns the actual # of layers

if isempty(handles.layers(1).X)==1  %if no layers
    numL=0;
else                                %if there are layers
    numL=size(handles.layers,2);
end


% *** funtion to return layer labels since 'getfield' hasn't worked for me
function labels = get_layer_labels(handles)
%   Inputs: handles - needed to pass variables
%   Output: labels - returns the layer labels

for ii=1:length(handles.layers)
    labels{ii}=handles.layers(ii).Label; %get current layer label
end


% *** End user functions, move anything below this to above user functions
% for cleanliness.  Or don't.
% *******************************************************************************
% *******************************************************************************

% --- Executes on button press in autopick.
function autopick_Callback(hObject, eventdata, handles)
% hObject    handle to autopick (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.handles=handles;

ztol=str2num(get(handles.ztol_edit,'String'));
numL=num_layers(handles);   %get # of layers
[handles.X,twt] = autopick(handles.dat,ztol);
if isfield(handles,'XX')
    opt{1}=handles.XX;
    opt{2}=handles.YY;
    opt{3}='xy';
elseif isfield(handles,'lon')
    opt{1}=handles.lon;
    opt{2}=handles.lat;
    opt{3}='ll';
else
    opt=[];
end
handles=add_layer(handles.X,twt,['Layer ',num2str(numL+1)],opt,handles);
handles.Xpick=[];           %resets picked points
handles.Ypick=[];           %resets picked points
plot_main(handles)
plot_trace(handles)
guidata(hObject, handles)
%plot(handles.Xpick,handles.Ypick,'m')


function figure1_CreateFcn(hObject, eventdata, handles)
% This is a Dummy Fucntion


% --- Executes on button press in panup.
function panup_Callback(hObject, eventdata, handles)
% hObject    handle to panup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfield(handles,pan)
    handles.pan=20/100;
end
ymin=str2num(get(handles.main_axes_ymin_edit,'String'));   %get xmin value from edit input
ymax=str2num(get(handles.main_axes_ymax_edit,'String'));   %get xmin value from edit input
win = ymax-ymin;
shift=win*handles.pan;
if ymin-shift>min(handles.Y) && ymax-shift<max(handles.Y)
    set(handles.main_axes_ymin_edit,'String',num2str(ymin-shift))   %set edit box value
    set(handles.main_axes_ymax_edit,'String',num2str(ymax-shift))   %set edit box value
    plot_main(handles)                  %replot imagesc zoomed in
elseif ymin-shift<min(handles.Y)
    ymin=min(handles.Y);
    ymax=ymin+win;
    set(handles.main_axes_ymin_edit,'String',num2str(ymin))   %set edit box value
    set(handles.main_axes_ymax_edit,'String',num2str(ymax))   %set edit box value
    plot_main(handles)                  %replot imagesc zoomed in
else
    h=msgbox('End of Record','ERROR','warn');
    set(h,'color',[153 193 203]/255)
end


% --- Executes on button press in panright.
function panright_Callback(hObject, eventdata, handles)
% hObject    handle to panright (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Get old Limits
if ~isfield(handles,pan)
    handles.pan=20/100;
end
xmin=str2num(get(handles.main_axes_xmin_edit,'String'));   %get xmin value from edit input
xmax=str2num(get(handles.main_axes_xmax_edit,'String'));   %get xmin value from edit input
win=xmax-xmin;
shift=win*handles.pan;
if xmin+shift>min(handles.X) && xmax+shift<max(handles.X)
    set(handles.main_axes_xmin_edit,'String',num2str(xmin+shift))   %set edit box value
    set(handles.main_axes_xmax_edit,'String',num2str(xmax+shift))   %set edit box value
    plot_main(handles)                  %replot imagesc zoomed in
elseif xmax+shift>max(handles.X)
    xmax=max(handles.X);
    xmin=xmax-win;
    set(handles.main_axes_xmin_edit,'String',num2str(xmin))   %set edit box value
    set(handles.main_axes_xmax_edit,'String',num2str(xmax))   %set edit box value
    plot_main(handles)                  %replot imagesc zoomed in
else
    h= msgbox('End of Record','ERROR','warn');
    set(h,'color',[153 193 203]/255)
end
% --- Executes on button press in pandown.
function pandown_Callback(hObject, eventdata, handles)
% hObject    handle to pandown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfield(handles,pan)
    handles.pan=20/100;
end
ymin=str2num(get(handles.main_axes_ymin_edit,'String'));   %get xmin value from edit input
ymax=str2num(get(handles.main_axes_ymax_edit,'String'));   %get xmin value from edit input
win=ymax-ymin;
shift=win*handles.pan;
if ymin+shift>min(handles.Y) && ymax+shift<max(handles.Y)
    set(handles.main_axes_ymin_edit,'String',num2str(ymin+shift))   %set edit box value
    set(handles.main_axes_ymax_edit,'String',num2str(ymax+shift))   %set edit box value
    plot_main(handles)
elseif ymax+shift>max(handles.Y)
    ymax=max(handles.Y);
    ymin=ymax-win;
    set(handles.main_axes_ymin_edit,'String',num2str(ymin))   %set edit box value
    set(handles.main_axes_ymax_edit,'String',num2str(ymax))   %set edit box value
    plot_main(handles)                  %replot imagesc zoomed in
else
    h= msgbox('End of Record','ERROR','warn');
    set(h,'color',[153 193 203]/255)
end


% --- Executes on button press in panleft.
function panleft_Callback(hObject, eventdata, handles)
% hObject    handle to panleft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfield(handles,pan)
    handles.pan=20/100;
end
xmin=str2num(get(handles.main_axes_xmin_edit,'String'));   %get xmin value from edit input
xmax=str2num(get(handles.main_axes_xmax_edit,'String'));   %get xmin value from edit input
win=xmax-xmin;
shift=win*handles.pan;
if xmin-shift>min(handles.X) && xmax-shift<max(handles.X)
    set(handles.main_axes_xmin_edit,'String',num2str(xmin-shift))   %set edit box value
    set(handles.main_axes_xmax_edit,'String',num2str(xmax-shift))   %set edit box value
    plot_main(handles)                  %replot imagesc zoomed in
elseif xmin-shift<min(handles.X)
    xmin=min(handles.X);
    xmax=xmin+win;
    set(handles.main_axes_xmin_edit,'String',num2str(xmin))   %set edit box value
    set(handles.main_axes_xmax_edit,'String',num2str(xmax))   %set edit box value
    plot_main(handles)                  %replot imagesc zoomed in
else
    h=msgbox('End of Record','ERROR','warn');
    set(h,'color',[153 193 203]/255)
end



function panedit_Callback(hObject, eventdata, handles)
% hObject    handle to panedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of panedit as text
%        str2double(get(hObject,'String')) returns contents of panedit as a double
handles.pan=str2double(get(hObject,'string'))/100; % amount to move current extent
guidata(hObject, handles)


% --- Executes during object creation, after setting all properties.
function panedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to panedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function File_Callback(hObject, eventdata, handles)
% hObject    handle to File (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function datapath_Callback(hObject, eventdata, handles)
% hObject    handle to datapath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%if no path exists use root
if ~isfield(handles,'dpath') || isempty(handles.dpath)
    handles.dpath='/';
end

handles.dpath=uigetdir(handles.dpath,'Select Path to Data');
guidata(hObject, handles)


% --------------------------------------------------------------------
function paths_Callback(hObject, eventdata, handles)
% hObject    handle to paths (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function pickpath_Callback(hObject, eventdata, handles)
% hObject    handle to pickpath (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% if no path exists use root
if ~isfield(handles,'ppath') || isempty(handles.ppath)
    handles.ppath='/';
end
handles.ppath=uigetdir(handles.ppath,'Select Path to Picks');
guidata(hObject, handles)



% --- Executes on button press in push_limapply.
function push_limapply_Callback(hObject, eventdata, handles)
% hObject    handle to push_limapply (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% applies limits defined by users in the edit boxes
set(handles.color_max_slider,'value',str2num(get(handles.color_max_edit,'string')))
set(handles.color_min_slider,'value',str2num(get(handles.color_min_edit,'string')))
plot_main(handles)
plot_trace(handles)
guidata(hObject,handles)

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function cbardef_Callback(hObject, eventdata, handles)
% hObject    handle to cbardef (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --------------------------------------------------------------------
function colorstep_Callback(hObject, eventdata, handles)
% hObject    handle to colorstep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% sets up the colorstep for the colorbar sliders
prompt='Enter Step Size for Colorbar Scrolling:';
dlg_title='User Input Required';
answer = inputdlg(prompt,dlg_title);
if isempty(answer) % if there is no answer don't throw errors
    return
end
% get maximum and minimum possible values for the slider
cmin=get(handles.color_min_slider,'Min');
cmax=get(handles.color_min_slider,'Max');
% get the user input
cs_step=str2num(answer{1});
% calculate the step value
css=cs_step/(cmax-cmin);
% apply the step value
set(handles.color_max_slider,'SliderStep',[css 0])
set(handles.color_min_slider,'SliderStep',[css 0])
handles.STEP=css;
guidata(hObject,handles)

% --------------------------------------------------------------------
function cmap_Callback(hObject, eventdata, handles)
% hObject    handle to cmap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function cmapJet_Callback(hObject, eventdata, handles)
% hObject    handle to cmapJet (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
colormap jet
handles.cmap=colormap;

% --------------------------------------------------------------------
function cmapBone_Callback(hObject, eventdata, handles)
% hObject    handle to cmapBone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
colormap bone
handles.cmap=bone;

% --------------------------------------------------------------------
function cmapHSV_Callback(hObject, eventdata, handles)
% hObject    handle to cmapHSV (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
colormap HSV
handles.cmap = colormap;

% --------------------------------------------------------------------
function cmapgray_Callback(hObject, eventdata, handles)
% hObject    handle to cmapgray (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
colormap gray
handles.cmap=colormap;


% --------------------------------------------------------------------
function Filter_menu_Callback(hObject, eventdata, handles)
% hObject    handle to Filter_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function submed_menu_Callback(hObject, eventdata, handles)
% hObject    handle to submed_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% subtracts a median trace from the image
handles.handles=handles;
S=size(handles.data);
handles.data=handles.data-repmat(median(handles.data,2),1,S(2));
plot_main(handles)
plot_trace(handles)
guidata(hObject,handles)

% --------------------------------------------------------------------
function medfilter_menu_Callback(hObject, eventdata, handles)
% hObject    handle to medfilter_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% applies the built in median filter to the image
prompt={'N Columns:','by M Rows:'};
dlg_title='Enter Dimensions of Filter';
answer = inputdlg(prompt,dlg_title);
if isempty(answer)
    return
end
handles.handles=handles;
N=str2num(answer{1});
M=str2num(answer{2});
handles.data=medfilt2(handles.data,[N M]);
plot_main(handles)
plot_trace(handles)
guidata(hObject,handles)


% --- Executes on button press in undo_pish.
function undo_pish_Callback(hObject, eventdata, handles)
% hObject    handle to undo_pish (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% handles.handles copies handles before an manipulation is carried out so
% we can revert that manipulation
if ~isfield(handles,'handles') % handles.handles wouldnt be set if nothing has happend to undo
    return
end
handles=handles.handles; % reset handles
handles.handles=handles; % get a new copy of handles
plot_main(handles)
plot_trace(handles)
% reset labels in the layers box if a deletion of layers has occured
labels=get_layer_labels(handles);  %get layer labels
set(handles.layers_listbox,'value',1:length(handles.layers)) %give listbox right values
set(handles.layers_listbox,'string',labels) %make listbox display layers
guidata(hObject,handles)



% --- Executes on button press in clear_picks_push.
function clear_picks_push_Callback(hObject, eventdata, handles)
% hObject    handle to clear_picks_push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.Xpick=[];
handles.Ypick=[];
plot_main(handles)
plot_trace(handles)

% --------------------------------------------------------------------
function RWB_menu_Callback(hObject, eventdata, handles)
% hObject    handle to RWB_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
load('RWB.cbar','-mat')
colormap(C)
handles.cmap=colormap;


% --------------------------------------------------------------------
function BkWR_Callback(hObject, eventdata, handles)
% hObject    handle to BkWR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
load('BWR.cbar','-mat')
colormap(C)
handles.cmap=colormap;


% --- Executes on selection change in popup_normalize.
function popup_normalize_Callback(hObject, eventdata, handles)
% hObject    handle to popup_normalize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popup_normalize contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popup_normalize

% This function executes when selecting a normalization method from the
% menu while data is already loaded

% get normalization technique from the menu
norm = cellstr(get(handles.popup_normalize,'String'));
norm = norm{get(handles.popup_normalize,'value')};
handles.norm=get(handles.popup_normalize,'value');
% figure out which normalization it is and then apply
if strcmp(norm,'None           ') && isfield(handles,'dat')
    handles.data=handles.dat.trace; 
elseif strcmp(norm,'By Max. Value  ') && isfield(handles,'dat')
    handles.data=handles.dat.trace/(max(max(handles.dat.trace)));
elseif strcmp(norm,'By Min. Value  ') && isfield(handles,'dat')
    handles.data=handles.dat.trace/(min(min(handles.dat.trace)));
elseif strcmp(norm,'By Mean Value  ') && isfield(handles,'dat')
    handles.data=handles.dat.trace/(nanmean(nanmean(handles.dat.trace)));
elseif strcmp(norm,'By Median Value') && isfield(handles,'dat')
    handles.data=handles.dat.trace/...
        (nanmedian(nanmedian(handles.dat.trace)));
end
plot_main(handles)
plot_trace(handles)
guidata(hObject,handles)
% --- Executes during object creation, after setting all properties.
function popup_normalize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popup_normalize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function geom_axes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to geom_axes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate geom_axes

% This function plots the geometry and location of average/single trace by
% accepting the handles structure
function plot_geom(handles)
if isfield(handles,'single_trace_index') % if a single trace is selected
    if isfield(handles,'XX') % if we are in northing and eastings
        Ix=handles.single_trace_index; % x-index of trace
        % plot geometry with red circle to mark the trace
        H=plot(handles.geom_axes,handles.XX,handles.YY,'k.',handles.XX(Ix),handles.YY(Ix),'ro');
        % plot properties
        set(H(2),'linewidth',2);
        xlabel(handles.geom_axes,'X','fontweight','bold','fontsize',12)
        ylabel(handles.geom_axes,'Y','fontweight','bold','fontsize',12)
        set(handles.geom_axes,'fontweight','bold','linewidth',2,'fontsize',12)
        
    elseif isfield(handles,'lon') % if we are in decimal degrees
        Ix=handles.single_trace_index; % index of trace
        % plot geometry and trace location
        H=plot(handles.geom_axes,handles.lon,handles.lat,'k.',handles.lon(Ix),handles.lat(Ix),'ro');
        % plot properties
        set(H(2),'linewidth',2);
        xlabel(handles.geom_axes,'Long.','fontweight','bold','fontsize',12)
        ylabel(handles.geom_axes,'Lat.','fontweight','bold','fontsize',12)
        set(handles.geom_axes,'fontweight','bold','linewidth',2,'fontsize',12)
        
    end
elseif isfield(handles,'average_trace_index') % if we are using an average trace
    if isfield(handles,'XX') % with eastings and northings
        Ix=sort(handles.average_trace_index); % rearange indices of average limits
        % plot geometry and the range of the average
        H=plot(handles.geom_axes,handles.XX,handles.YY,'k.',handles.XX(Ix(1):Ix(2)),handles.YY(Ix(1):Ix(2)),'ro');
        % plot properties
        set(H(2),'linewidth',2);
        xlabel(handles.geom_axes','X','fontweight','bold','fontsize',12)
        ylabel(handles.geom_axes','Y','fontweight','bold','fontsize',12)
        set(handles.geom_axes,'fontweight','bold','linewidth',2,'fontsize',12)
    elseif isfield(handles,'lon') % we are in decimal degrees
        Ix=sort(handles.average_trace_index); % index of range
        % plot geometry and the range of the average trace
        H=plot(handles.geom_axes,handles.lon,handles.lat,'k.',handles.lon(Ix(1):Ix(2)),handles.lat(Ix(1):Ix(2)),'ro');
        % plot properties
        set(H(2),'linewidth',2);
        xlabel(handles.geom_axes','Long.','fontweight','bold','fontsize',12)
        ylabel(handles.geom_axes','Lat.','fontweight','bold','fontsize',12)
        set(handles.geom_axes,'fontweight','bold','linewidth',2,'fontsize',12)
    end
end
