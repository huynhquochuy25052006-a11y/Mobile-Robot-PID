`az%% 
function varargout = CameraAndPlot(varargin)
% CAMERAANDPLOT MATLAB code for CameraAndPlot.fig
%      CAMERAANDPLOT, by itself, creates a new CAMERAANDPLOT or raises the existing
%      singleton*.
%
%      H = CAMERAANDPLOT returns the handle to a new CAMERAANDPLOT or the handle to
%      the existing singleton*.
%
%      CAMERAANDPLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CAMERAANDPLOT.M with the given input arguments.
%
%      CAMERAANDPLOT('Property','Value',...) creates a new CAMERAANDPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CameraAndPlot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CameraAndPlot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CameraAndPlot

% Last Modified by GUIDE v2.5 30-Nov-2025 21:36:14

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CameraAndPlot_OpeningFcn, ...
                   'gui_OutputFcn',  @CameraAndPlot_OutputFcn, ...
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


% --- Executes just before CameraAndPlot is made visible.
function CameraAndPlot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CameraAndPlot (see VARARGIN)
global NowX NowY
NowX = 0; 
NowY = 0;

global newRow
newRow = [];

set(handles.eightUnitText,'Visible','off');
set(handles.velEightText,'Visible','off');

global KpL KiL KdL NL KpR KiR KdR NR
KpL = [21.091, 30.939, 19.878];
KiL = [43.548, 56.02, 37.341];
KdL = [2.16, 3.839, 2.372];
NL = [26.788, 35.368, 35.368];

KpR = [16.822, 30.882, 16.159];
KiR = [42.609, 56.968, 37.236];
KdR = [1.36, 3.758, 1.529];
NR = [26.788, 35.368, 35.368];

set(gcf, 'Units', 'pixels');
screenSize = get(0, 'ScreenSize'); % [left bottom width height]
set(gcf, 'Position', screenSize);

handles.dataLog = [];

handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CameraAndPlot wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = CameraAndPlot_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


%function updateFrame(hFig)
    %if ~ishandle(hFig)
        %return;
    %end
    %handles = guidata(hFig);
    %if isfield(handles, 'cam') && ~isempty(handles.cam)
        %img = fliplr(snapshot(handles.cam));
        %imshow(img, 'Parent', handles.axes1);
        %if ~isfield(handles, 'camImg') || ~ishandle(handles.camImg)
            %axes(handles.axes1);
            %handles.camImg = imshow(img, 'Parent', handles.axes1);
        %else
            %set(handles.camImg, 'CData', img);  % C?p nh?t nhanh h?n imshow
        %end
        %drawnow limitrate;
    %end

function updateFrame(hFig)
    if ~ishandle(hFig)
        return;
    end

    handles = guidata(hFig);
    imgPath = 'E:\Nghien_Cuu_Khoa_Hoc_2025_2026\MOBILE ROBOT\Final\Final\Code\Matlab\guide\trajImg.png';
    if exist(imgPath, 'file') ~= 2
        return;
    end

    fileInfo = dir(imgPath);
    if isempty(fileInfo) || fileInfo.bytes < 5000
        return;
    end

    try
        img = imread(imgPath);
    catch
        return;
    end

    % --- Hi?n th? ?nh trên axes ---
    axes(handles.axes1);
    if ~isfield(handles, 'camImg') || ~ishandle(handles.camImg)
        handles.camImg = imshow(img, 'Parent', handles.axes1);
    else
        set(handles.camImg, 'CData', img);
    end

    drawnow limitrate;
    guidata(hFig, handles);


function timerCallback(~, ~, hObject)
global serialObj isRunning t1
global NowX NowY
global pySocket
global newRow
handles = guidata(hObject); % L?y handles m?i nh?t c?a GUI

if (~isscalar(isRunning) || ~islogical(isRunning) || ~isRunning || ...
    ~isfield(handles,'traj') || isempty(handles.traj) || ~all(ishandle(handles.traj)))
    disp('Khong chay dc 1');
    return;
end

%if get(handles.cameraMode,'Value') == true && get(handles.encoderMode,'Value') == false
%    msg = sprintf('Xd:%.2f,Yd:%.2f', dataDraw(handles.i,1), dataDraw(handles.i,2));
%    fprintf(serialObj, msg);
%    pause(0.02);
%    fprintf('Xd:%.2f,Yd:%.2f\n',dataDraw(handles.i,1), dataDraw(handles.i,2));
%    handles.i = handles.i + 1;
%    guidata(hObject, handles);
%end

if get(handles.encoderMode,'Value') == true || get(handles.cameraMode,'Value') == true
    if serialObj.BytesAvailable > 0
        try
            line = fgetl(serialObj);
            line = strtrim(line);
            if isempty(line)
                return;
            end
            dataSer = str2double(strsplit(line, ','));
            if any(isnan(dataSer))
                return;
            end
            if numel(dataSer) >= 2
                if get(handles.cameraMode,'Value') == false
                    addpoints(handles.traj, dataSer(1), dataSer(2));
                    NowX = dataSer(1);
                    NowY = dataSer(2);
                end
            end
            if numel(dataSer) >= 3
                addpoints(handles.velR, t1.TasksExecuted, dataSer(3));
                addpoints(handles.velR9, t1.TasksExecuted, dataSer(3));
            end
            if numel(dataSer) >= 4
                addpoints(handles.velL, t1.TasksExecuted, dataSer(4));
                addpoints(handles.velL10, t1.TasksExecuted, dataSer(4));
                addpoints(handles.velModel, t1.TasksExecuted, (dataSer(3)+dataSer(4))/2.0);
            end
            if numel(dataSer) >= 5
                addpoints(handles.velRTraj, t1.TasksExecuted, dataSer(5));
                addpoints(handles.velRTraj9, t1.TasksExecuted, dataSer(5));
            end
            if numel(dataSer) >= 6
                addpoints(handles.velLTraj, t1.TasksExecuted, dataSer(6));
                addpoints(handles.velLTraj10, t1.TasksExecuted, dataSer(6));
                addpoints(handles.velModelTraj, t1.TasksExecuted, (dataSer(5)+dataSer(6))/2.0);
                addpoints(handles.velModelError, t1.TasksExecuted, ((dataSer(3)+dataSer(4))/2.0)-((dataSer(5)+dataSer(6))/2.0));
                newRow = [t1.TasksExecuted, dataSer(3:6)];        
            end
            %drawnow limitrate nocallbacks;
            %disp('Da nhan Serial');
        catch
            %disp('Khong nhan Serial');
        end
    end
end

if get(handles.cameraMode,'Value') == true
    if pySocket.BytesAvailable > 0
        try
            pyMsg = fscanf(pySocket);
            %pyMsg = readline(pySocket);
            %disp(['Received: ' strtrim(pyMsg)]);
            pyMsg = strtrim(pyMsg);
            if isempty(pyMsg)
                return;
            end
            if strcmp(pyMsg, 'START')
                fprintf(serialObj, 'STARTCAM');
                disp('Da gui STARTCAM');
            end
            dataPy = str2double(strsplit(pyMsg, ','));
            if any(isnan(dataPy))
                return;
            end
            if numel(dataPy) >= 3
                addpoints(handles.traj, dataPy(1), dataPy(2));
                NowX = dataPy(1);
                NowY = dataPy(2);
                Cam = sprintf('xC:%.2f,yC:%.2f,pC:%.2f\n', dataPy(1), dataPy(2), dataPy(3));
                fprintf(serialObj, Cam);
                %fprintf('xC:%.2f,yC:%.2f,pC:%.2f\n', dataPy(1), dataPy(2), dataPy(3));
            end
            %drawnow limitrate nocallbacks;
            %disp('Da nhan Serial');
        catch
            %disp('Khong nhan Serial');
        end
    end
    %updateFrame(hObject)
    if ~ishandle(hObject)
        return;
    end

    handles = guidata(hObject);
    %imgPath = 'K:\STUDY\Final\Python\trajImg.png';
    imgPath = 'K:\STUDY\Final\Code\Matlab\guide\trajImg.png';
    if exist(imgPath, 'file') ~= 2
        return;
    end

    fileInfo = dir(imgPath);
    if isempty(fileInfo) || fileInfo.bytes < 5000
        return;
    end

    try
        img = imread(imgPath);
    catch
        return;
    end

    % --- Hi?n th? ?nh trên axes ---
    axes(handles.axes1);
    if ~isfield(handles, 'camImg') || ~ishandle(handles.camImg)
        handles.camImg = imshow(img, 'Parent', handles.axes1);
    else
        set(handles.camImg, 'CData', img);
    end

    drawnow limitrate;
    guidata(hObject, handles);
end

if ~isempty(newRow)
    handles.dataLog = [handles.dataLog; newRow];
end
guidata(handles.figure1, handles);
drawnow limitrate nocallbacks;

% --- Executes on button press in Connect.
function Connect_Callback(hObject, eventdata, handles)
% hObject    handle to Connect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global serialObj isRunning t1
%global t1 serialObj isRunning
isRunning = false;

% Serial setup
comPort = 'COM3';
baudRate = 115200;
old = instrfind('Port', comPort);
if ~isempty(old)
    fclose(old);
    delete(old);
end

handles.i = 1;
serialObj = serial(comPort, 'BaudRate', baudRate, 'Terminator', 'LF', 'Timeout', 1);
serialObj.InputBufferSize = 4096;
fopen(serialObj);
t1 = timer('ExecutionMode', 'fixedRate', 'Period', 0.01, 'TimerFcn', {@timerCallback, hObject}); % truy?n hObject vào
guidata(hObject, handles);


% --- Executes on button press in Disconnect.
function Disconnect_Callback(hObject, eventdata, handles)
% hObject    handle to Disconnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global serialObj isRunning pySocket
if isRunning
    %fprintf(serialObj, 'STOP\n');
    isRunning = false;
    fclose(serialObj);
    delete(serialObj);
    clear serialObj;
    fclose(pySocket);
    delete(pySocket);
    clear pySocket;
    system('taskkill /IM pythonw.exe /F');
end


% --- Executes on button press in StartModel.
function StartModel_Callback(hObject, eventdata, handles)
% hObject    handle to StartModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global t1 serialObj isRunning enablePaint

if get(handles.CircleTraj,'Value') == 1
    fprintf(serialObj, 'STARTCIRCLE');
    disp('Da gui STARTCIRCLE');
elseif get(handles.EightTraj,'Value') == 1
    fprintf(serialObj, 'STARTEIGHT');
    disp('Da gui STARTEIGHT');
elseif get(handles.ManualTraj,'Value') == 1
    fprintf(serialObj, 'STARTPTOP');
    disp('Da gui STARTPTOP');
elseif get(handles.DrawTraj,'Value') == 1
    fprintf(serialObj, 'STARTPAINT');
    enablePaint = true;
    disp('Da gui STARTPAINT');
end
%pause(0.1);

if ~isRunning
    axes(handles.axes2);
    hold on;
    axis([-50, 50, -50, 50]);
    grid on;
    traj = animatedline('Color', 'b', 'LineWidth', 2, 'Marker', '.', 'MaximumNumPoints', 5000);
    trajCam = animatedline('Color', 'g', 'LineWidth', 2, 'Marker', '.', 'MaximumNumPoints', 5000);
    if get(handles.cameraMode,'Value') == false && get(handles.encoderMode,'Value') == true
        legend('Trajectory', 'Encoder Trajectory');
    elseif get(handles.cameraMode,'Value') == true && get(handles.encoderMode,'Value') == false
        legend('Trajectory', 'Camera Trajectory');
    end
    title('Trajectory');
    xlabel('x [cm]');
    ylabel('y [cm]');
    handles.traj = traj;
    handles.trajCam = trajCam;
    
    axes(handles.axes3);
    hold on;
    axis([0,2000,-110,110]);
    grid on;
    velRTraj = animatedline('Color', 'r', 'LineWidth', 3, 'Marker', '.', 'MaximumNumPoints', 5000);
    velR = animatedline('Color', 'b', 'LineWidth', 1, 'Marker', '.', 'MaximumNumPoints', 5000);
    if get(handles.cameraMode,'Value') == false && get(handles.encoderMode,'Value') == true
        legend('Right Velocity Desired', 'Right Velocity - Encoder');
    elseif get(handles.cameraMode,'Value') == true && get(handles.encoderMode,'Value') == false
        legend('Right Velocity Desired', 'Right Velocity - Camera');
    end
    title('Right Velocity');
    xlabel('Time [x 0.01s]');
    ylabel('Speed [cm/s]');
    handles.velR = velR;
    handles.velRTraj = velRTraj;
    
    axes(handles.axes9);
    hold on;
    axis([0,2000,-110,110]);
    grid on;
    velRTraj9 = animatedline('Color', 'r', 'LineWidth', 3, 'Marker', '.', 'MaximumNumPoints', 5000);
    velR9 = animatedline('Color', 'b', 'LineWidth', 1, 'Marker', '.', 'MaximumNumPoints', 5000);
    if get(handles.cameraMode,'Value') == false && get(handles.encoderMode,'Value') == true
        legend('Right Velocity Desired', 'Right Velocity - Encoder');
    elseif get(handles.cameraMode,'Value') == true && get(handles.encoderMode,'Value') == false
        legend('Right Velocity Desired', 'Right Velocity - Camera');
    end
    title('Right Velocity');
    xlabel('Time [x 0.01s]');
    ylabel('Speed [cm/s]');
    handles.velR9 = velR9;
    handles.velRTraj9 = velRTraj9;
    
    axes(handles.axes4);
    hold on;
    axis([0,2000,-110,110]);
    grid on;
    velLTraj = animatedline('Color', 'r', 'LineWidth', 3, 'Marker', '.', 'MaximumNumPoints', 5000);
    velL = animatedline('Color', 'b', 'LineWidth', 1, 'Marker', '.', 'MaximumNumPoints', 5000);
    if get(handles.cameraMode,'Value') == false && get(handles.encoderMode,'Value') == true
        legend('Left Velocity Desired', 'Left Velocity - Encoder');
    elseif get(handles.cameraMode,'Value') == true && get(handles.encoderMode,'Value') == false
        legend('Left Velocity Desired', 'Left Velocity - Camera');
    end
    title('Left Velocity');
    xlabel('Time [x 0.01s]');
    ylabel('Speed [cm/s]');
    handles.velL = velL;
    handles.velLTraj = velLTraj;
    
    axes(handles.axes10);
    hold on;
    axis([0,2000,-110,110]);
    grid on;
    velLTraj10 = animatedline('Color', 'r', 'LineWidth', 3, 'Marker', '.', 'MaximumNumPoints', 5000);
    velL10 = animatedline('Color', 'b', 'LineWidth', 1, 'Marker', '.', 'MaximumNumPoints', 5000);
    if get(handles.cameraMode,'Value') == false && get(handles.encoderMode,'Value') == true
        legend('Left Velocity Desired', 'Left Velocity - Encoder');
    elseif get(handles.cameraMode,'Value') == true && get(handles.encoderMode,'Value') == false
        legend('Left Velocity Desired', 'Left Velocity - Camera');
    end
    title('Left Velocity');
    xlabel('Time [x 0.01s]');
    ylabel('Speed [cm/s]');
    handles.velL10 = velL10;
    handles.velLTraj10 = velLTraj10;
    
    axes(handles.axes5);
    hold on;
    axis([0,2000,-100,100]);
    grid on;
    velModelTraj = animatedline('Color', 'r', 'LineWidth', 3, 'Marker', '.', 'MaximumNumPoints', 5000);
    velModel = animatedline('Color', 'b', 'LineWidth', 1, 'Marker', '.', 'MaximumNumPoints', 5000);
    if get(handles.cameraMode,'Value') == false && get(handles.encoderMode,'Value') == true
        legend('Model Velocity Desired', 'Model Velocity - Encoder');
    elseif get(handles.cameraMode,'Value') == true && get(handles.encoderMode,'Value') == false
        legend('Model Velocity Desired', 'Model Velocity - Camera');
    end
    title('Model Velocity');
    xlabel('Time [x 0.01s]');
    ylabel('Speed [cm/s]');
    handles.velModel = velModel;
    handles.velModelTraj = velModelTraj;
    
    axes(handles.axes6);
    hold on;
    axis([0,2000,-30,30]);
    grid on;
    velModelError = animatedline('Color', 'b', 'LineWidth', 1, 'Marker', '.', 'MaximumNumPoints', 5000);
    if get(handles.cameraMode,'Value') == true && get(handles.encoderMode,'Value') == false
        legend('Error Velocity Camera');
    elseif get(handles.cameraMode,'Value') == false && get(handles.encoderMode,'Value') == true
        legend('Error Velocity Encoder');
    end
    title('Error Velocity');
    xlabel('Time [x 0.01s]');
    ylabel('Speed [cm/s]');
    handles.velModelError = velModelError;
    
    guidata(hObject, handles);

    isRunning = true;
    start(t1);
end



% --- Executes on button press in StopModel.
function StopModel_Callback(hObject, eventdata, handles)
% hObject    handle to StopModel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global t1 serialObj isRunning
if isRunning
    fprintf(serialObj, 'STOP');
    isRunning = false;
    stop(t1);
    clear t1;
end

% --- Executes on button press in Clear.
function Clear_Callback(hObject, eventdata, handles)
% hObject    handle to Clear (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'traj') && ishandle(handles.traj)
    clearpoints(handles.traj);
    clearpoints(handles.velR);
    clearpoints(handles.velRTraj);
    clearpoints(handles.velR9);
    clearpoints(handles.velRTraj9);
    clearpoints(handles.velL);
    clearpoints(handles.velLTraj);
    clearpoints(handles.velL10);
    clearpoints(handles.velLTraj10);
    clearpoints(handles.velModel);
    clearpoints(handles.velModelTraj);
    clearpoints(handles.velModelError);
end
drawnow;
handles.dataLog = [];
guidata(hObject, handles);


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global t1 serialObj isRunning
try
    isRunning = false;
    stop(t1);
    delete(t1);
catch
end
try
    fclose(serialObj);
    clear serialObj;
catch
end
% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes on button press in DrawTrajectory.
function DrawTrajectory_Callback(hObject, eventdata, handles)
% hObject    handle to DrawTrajectory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
t = 1:100;
w = pi/32;
if get(handles.CircleTraj,'Value') == true
    r = str2double(get(handles.radius,'String'));
    assignin('base','radiusWS',r);
    %load_system('K:\STUDY\Final\Code\Matlab\Simulink\Circle.slx');
    load_system('E:\Nghien_Cuu_Khoa_Hoc_2025_2026\MOBILE ROBOT\Final\Final\Code\Matlab\Simulink\CircleDiscrete.slx');
    %set_param('Circle','SimulationCommand','update');
    %set_param('Circle','SimulationCommand','start');
    set_param('CircleDiscrete','SimulationCommand','update');
    set_param('CircleDiscrete','SimulationCommand','start');
    
    x = r*cos(w*t);
    y = r*sin(w*t);
    
    cla(handles.axes2);
    axes(handles.axes2);
    hold(handles.axes2, 'on');
    plot(x,y,'r:','LineWidth',3);
    %axis([min(x)-20,max(x)+20,min(y)-20,max(y)+20]);
    axis([-50,50,-50,50]);
    legend('Circle Trajectory');
    xlabel('x');
    ylabel('y');
    grid on;
elseif get(handles.EightTraj,'Value') == true
    a = str2double(get(handles.a,'String'));
    b = str2double(get(handles.b,'String'));
    assignin('base','aWS',a);
    assignin('base','bWS',b);
    %load_system('K:\STUDY\Final\Code\Matlab\Simulink\Eight.slx');
    load_system('E:\Nghien_Cuu_Khoa_Hoc_2025_2026\MOBILE ROBOT\Final\Final\Code\Matlab\Simulink\EightDiscrete.slx');
    %set_param('Eight','SimulationCommand','update');
    %set_param('Eight','SimulationCommand','start');
    set_param('EightDiscrete','SimulationCommand','update');
    set_param('EightDiscrete','SimulationCommand','start');
    x = a*sin(w*t);
    y = (b/2)*sin(2*w*t);
    
    cla(handles.axes2);   % xóa toàn b? n?i dung trong axes2
    axes(handles.axes2);
    hold(handles.axes2, 'on');
    plot(x,y,'r:','LineWidth',3);
    %axis([min(x)-20,max(x)+20,min(y)-20,max(y)+20]);
    axis([-50,50,-50,50]);
    legend('Eight Trajectory'); 
    xlabel('x');
    ylabel('y');
    grid on;
end

% --- Executes on button press in SMLSys.
function SMLSys_Callback(hObject, eventdata, handles)
% hObject    handle to SMLSys (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.CircleTraj,'Value') == true
    %set_param('Circle','SimulationCommand','start'); % c?p nh?t mô hình
    set_param('CircleDiscrete','SimulationCommand','start');
    xSim = evalin('base','xCircle');
    ySim = evalin('base','yCircle');
    
    xCirTraj = xSim.Data;
    yCirTraj = ySim.Data;
    
    axes(handles.axes2);
    hold on;
    plot(xCirTraj,yCirTraj,'b','LineWidth',3);
    %axis([min(xCirTraj)-20,max(xCirTraj)+20,min(yCirTraj)-20,max(yCirTraj)+20]);
    axis([-50,50,-50,50]);
    grid on;
elseif get(handles.EightTraj,'Value') == true
    %set_param('Eight','SimulationCommand','start');
    set_param('EightDiscrete','SimulationCommand','start');
    xSim = evalin('base','xEight');
    ySim = evalin('base','yEight');
    
    xEightTraj = xSim.Data;
    yEightTraj = ySim.Data;
    
    axes(handles.axes2);
    hold on;
    plot(xEightTraj,yEightTraj,'b','LineWidth',3);
    %axis([min(xEightTraj)-20,max(xEightTraj)+20,min(yEightTraj)-20,max(yEightTraj)+20]);
    axis([-50,50,-50,50]);
    grid on;
end

function radius_Callback(hObject, eventdata, handles)
% hObject    handle to radius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of radius as text
%        str2double(get(hObject,'String')) returns contents of radius as a double

% --- Executes during object creation, after setting all properties.
function radius_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function a_Callback(hObject, eventdata, handles)
% hObject    handle to a (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of a as text
%        str2double(get(hObject,'String')) returns contents of a as a double


% --- Executes during object creation, after setting all properties.
function a_CreateFcn(hObject, eventdata, handles)
% hObject    handle to a (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function b_Callback(hObject, eventdata, handles)
% hObject    handle to b (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of b as text
%        str2double(get(hObject,'String')) returns contents of b as a double


% --- Executes during object creation, after setting all properties.
function b_CreateFcn(hObject, eventdata, handles)
% hObject    handle to b (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function KpLeftGain_Callback(hObject, eventdata, handles)
% hObject    handle to KpLeftGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of KpLeftGain as text
%        str2double(get(hObject,'String')) returns contents of KpLeftGain as a double
KpLeft = str2double(get(handles.KpLeftGain,'String'));
assignin('base','KpLeftWS',KpLeft);


% --- Executes during object creation, after setting all properties.
function KpLeftGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to KpLeftGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function KiLeftGain_Callback(hObject, eventdata, handles)
% hObject    handle to KiLeftGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of KiLeftGain as text
%        str2double(get(hObject,'String')) returns contents of KiLeftGain as a double
KiLeft = str2double(get(handles.KiLeftGain,'String'));
assignin('base','KiLeftWS',KiLeft);

% --- Executes during object creation, after setting all properties.
function KiLeftGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to KiLeftGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function KdLeftGain_Callback(hObject, eventdata, handles)
% hObject    handle to KdLeftGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of KdLeftGain as text
%        str2double(get(hObject,'String')) returns contents of KdLeftGain as a double
KdLeft = str2double(get(handles.KdLeftGain,'String'));
assignin('base','KdLeftWS',KdLeft);

% --- Executes during object creation, after setting all properties.
function KdLeftGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to KdLeftGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ManualTraj.
function ManualTraj_Callback(hObject, eventdata, handles)
% hObject    handle to ManualTraj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global manualPoints manualLine
global NowX NowY

set(handles.eightUnitText,'Visible','off');
set(handles.velEightText,'Visible','off');

set(handles.axes2, 'Visible', 'on');
axes(handles.axes2);
cla(handles.axes2); 
hold(handles.axes2, 'on');
axis([-50,50,-50,50]);
grid on;

manualPoints = [NowX,NowY];
manualLine = plot(handles.axes2, manualPoints(:,1), manualPoints(:,2), 'r--o', 'LineWidth', 2, 'MarkerFaceColor', 'r');

set(handles.figure1, 'WindowButtonDownFcn', {@manualClickCallback, handles});


function manualClickCallback(src, ~, handles)
global manualPoints manualLine 
global serialObj

clickType = get(src, 'SelectionType');
cp = get(handles.axes2, 'CurrentPoint');
x = cp(1,1);
y = cp(1,2);
if strcmp(clickType, 'normal')
    manualPoints = [manualPoints; x y];
    set(manualLine, 'XData', manualPoints(:,1), 'YData', manualPoints(:,2));
    drawnow;
elseif strcmp(clickType, 'alt')
    handles.manualTraj.x = manualPoints(:,1);
    handles.manualTraj.y = manualPoints(:,2);
    guidata(src, handles);
    
    assignin('base', 'xManual', manualPoints(:,1));
    assignin('base', 'yManual', manualPoints(:,2));
    
    set(src, 'WindowButtonDownFcn', '');
    
    try
        fprintf(serialObj, 'UPTRAJ');
        pause(0.1);
        
        for i = 1:size(manualPoints)
            msg = sprintf('X:%.3f,Y:%.3f\n', manualPoints(i,1), manualPoints(i,2));
            fprintf(serialObj, msg);
            pause(0.01);
        end
        
        fprintf(serialObj, 'END');
        pause(0.1);
        
        disp('Gui thanh cong');
        msgbox('Gui thanh cong', 'Announcement');
    catch
        disp('Khong gui duoc');
        msgbox('Khong gui duoc', 'Announcement');
    end
end
%legend('Trajectory');


% --- Executes on button press in update.
function update_Callback(hObject, eventdata, handles)
% hObject    handle to update (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global serialObj
r = str2double(get(handles.radius,'String'));
a = str2double(get(handles.a,'String'));
b = str2double(get(handles.b,'String'));
v = str2double(get(handles.velocity,'String'));
KpL = str2double(get(handles.KpLeftGain,'String'));
KiL = str2double(get(handles.KiLeftGain,'String'));
KdL = str2double(get(handles.KdLeftGain,'String'));
NL = str2double(get(handles.NLeftGain,'String'));
KpR = str2double(get(handles.KpRightGain,'String'));
KiR = str2double(get(handles.KiRightGain,'String'));
KdR = str2double(get(handles.KdRightGain,'String'));
NR = str2double(get(handles.NRightGain,'String'));

%Bat dau gui du lieu moi
data = sprintf('r:%.3f,a:%.3f,b:%.3f,v:%.3f,pL:%.3f,iL:%.3f,dL:%.3f,nL:%.3f,pR:%.3f,iR:%.3f,dR:%.3f,nR:%.3f',...
r,a,b,v,KpL,KiL,KdL,NL,KpR,KiR,KdR,NR);
fprintf(serialObj,data);
pause(0.1);
fprintf(serialObj, 'UPLOAD');
disp('Da gui Upload');
pause(0.5);
%Hoan thanh gui du lieu
fprintf(serialObj, 'DONEUP');
disp('Da gui DoneUp');
msgbox('Da cap nhat cac thong so', 'Annoucement');


% --- Executes on button press in CircleTraj.
function CircleTraj_Callback(hObject, eventdata, handles)
% hObject    handle to CircleTraj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.eightUnitText,'Visible','off');
set(handles.velEightText,'Visible','off');
% Hint: get(hObject,'Value') returns toggle state of CircleTraj

% --- Executes on button press in EightTraj.
function EightTraj_Callback(hObject, eventdata, handles)
% hObject    handle to EightTraj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.eightUnitText,'Visible','on');
set(handles.velEightText,'Visible','on');
% Hint: get(hObject,'Value') returns toggle state of EightTraj


function KpRightGain_Callback(hObject, eventdata, handles)
% hObject    handle to KpRightGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of KpRightGain as text
%        str2double(get(hObject,'String')) returns contents of KpRightGain as a double
KpRight = str2double(get(handles.KpRightGain,'String'));
assignin('base','KpRightWS',KpRight);


% --- Executes during object creation, after setting all properties.
function KpRightGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to KpRightGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function KiRightGain_Callback(hObject, eventdata, handles)
% hObject    handle to KiRightGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of KiRightGain as text
%        str2double(get(hObject,'String')) returns contents of KiRightGain as a double
KiRight = str2double(get(handles.KiRightGain,'String'));
assignin('base','KiRightWS',KiRight);

% --- Executes during object creation, after setting all properties.
function KiRightGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to KiRightGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function KdRightGain_Callback(hObject, eventdata, handles)
% hObject    handle to KdRightGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of KdRightGain as text
%        str2double(get(hObject,'String')) returns contents of KdRightGain as a double
KdRight = str2double(get(handles.KdRightGain,'String'));
assignin('base','KdRightWS',KdRight);

% --- Executes during object creation, after setting all properties.
function KdRightGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to KdRightGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function velocity_Callback(hObject, eventdata, handles)
% hObject    handle to velocity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of velocity as text
%        str2double(get(hObject,'String')) returns contents of velocity as a double


% --- Executes during object creation, after setting all properties.
function velocity_CreateFcn(hObject, eventdata, handles)
% hObject    handle to velocity (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function NLeftGain_Callback(hObject, eventdata, handles)
% hObject    handle to NLeftGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NLeftGain as text
%        str2double(get(hObject,'String')) returns contents of NLeftGain as a double


% --- Executes during object creation, after setting all properties.
function NLeftGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NLeftGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function NRightGain_Callback(hObject, eventdata, handles)
% hObject    handle to NRightGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NRightGain as text
%        str2double(get(hObject,'String')) returns contents of NRightGain as a double


% --- Executes during object creation, after setting all properties.
function NRightGain_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NRightGain (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in reload.
function reload_Callback(hObject, eventdata, handles)
% hObject    handle to reload (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global serialObj

fprintf(serialObj, 'OPEN');
disp('Da gui OPEN');
pause(0.05);
if serialObj.BytesAvailable > 0
    line = fgetl(serialObj);
    line = strtrim(line);
    if ~isempty(line)
        data = str2double(strsplit(line, ','));
        if numel(data) >= 12 && all(~isnan(data))
            set(handles.radius, 'String', num2str(data(1)));
            set(handles.a, 'String', num2str(data(2)));
            set(handles.b, 'String', num2str(data(3)));
            set(handles.velocity, 'String', num2str(data(4)));
            set(handles.KpLeftGain, 'String', num2str(data(5)));
            set(handles.KiLeftGain, 'String', num2str(data(6)));
            set(handles.KdLeftGain, 'String', num2str(data(7)));
            set(handles.NLeftGain, 'String', num2str(data(8)));
            set(handles.KpRightGain, 'String', num2str(data(9)));
            set(handles.KiRightGain, 'String', num2str(data(10)));
            set(handles.KdRightGain, 'String', num2str(data(11)));
            set(handles.NRightGain, 'String', num2str(data(12)));
            pause(0.1);
            fprintf(serialObj, 'RELOADED');
            msgbox('Da tai lai du lieu', 'Announcement');
        else
            disp('1');
        end
    else
        disp('2');    
    end
else
    disp('3');  
end


% --- Executes on button press in DrawTraj.
function DrawTraj_Callback(hObject, eventdata, handles)
% hObject    handle to DrawTraj (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DrawTraj

set(handles.eightUnitText,'Visible','off');
set(handles.velEightText,'Visible','off');

val = get(hObject, 'Value');

if val == 1
    set(handles.axes2, 'Visible', 'on');
    %set(handles.axes2, 'Visible', 'off');
    axes(handles.axes2);
    cla(handles.axes2);
    hold(handles.axes2, 'on');
    axis(handles.axes2, [-50,50,-50,50]);
    grid(handles.axes2, 'on');
    axis(handles.axes2, 'manual');
    set(handles.axes2, 'ButtonDownFcn', {@startDraw, handles});
else
    set(handles.axes2, 'Visible', 'off');
    set(handles.axes2, 'ButtonDownFcn', '');
    set(gcf, 'WindowButtonMotionFcn', '');
    set(gcf, 'WindowButtonUpFcn', '');
end

function startDraw(hObject, ~, handles)
    clickType = get(gcf, 'SelectionType');
    
    if strcmp(clickType, 'alt')
        sendData(hObject,handles);
        return;
    end
    
    handles = guidata(hObject);
    set(gcf, 'WindowButtonMotionFcn', @mouseMove);
    set(gcf, 'WindowButtonUpFcn', @mouseUp);

    points = get(hObject, 'CurrentPoint');
    handles.drawX = points(1,1);
    handles.drawY = points(1,2);

    axes(handles.axes2);
    handles.hLine = plot(handles.axes2, handles.drawX, handles.drawY, 'r--', 'LineWidth', 3);
    guidata(hObject, handles);
    
function mouseMove(~, ~)
    handles = guidata(gcf);

    if ~isfield(handles, 'hLine') || ~ishandle(handles.hLine)
        return;
    end
    
    points = get(handles.axes2, 'CurrentPoint');
    handles.drawX(end+1) = points(1,1);
    handles.drawY(end+1) = points(1,2);

    set(handles.hLine, 'XData', handles.drawX, 'YData', handles.drawY);
    guidata(gcf, handles);
    
function mouseUp(~, ~)
    set(gcf, 'WindowButtonMotionFcn', '');
    set(gcf, 'WindowButtonUpFcn', '');
    handles = guidata(gcf);
    guidata(gcf, handles);
    
function sendData(hObject,handles)
    handles = guidata(hObject);
    resolution = str2double(get(handles.paintRes,'String'));
    global sendDone serialObj
    sendDone = false;
    if ~isfield(handles, 'drawX') || isempty(handles.drawX)
        disp('Chua co du lieu');
        msgbox('Chua co du lieu', 'Announcement');
        handles.drawX = [];
        handles.drawY = [];
        return;
    else
        fprintf(serialObj, 'PAINT');
        pause(0.02)
        dataDraw = [handles.drawX(:), handles.drawY(:)];
        for j = 1:resolution:size(dataDraw, 1)
            msg = sprintf('Xd:%.2f,Yd:%.2f', dataDraw(j,1), dataDraw(j,2));
            fprintf(serialObj, msg);
            pause(0.02);
            fprintf('%.2f,%.2f\n',dataDraw(j,1), dataDraw(j,2));         
        end
        fprintf(serialObj, 'ENDPAINT');
        handles.drawX = [];
        handles.drawY = [];
        guidata(hObject, handles);
        disp('Co du lieu');
        msgbox('Co du lieu', 'Announcement');
        return;
    end

    %comPort = 'COM8';
    %baudRate = 115200;
    %s = serial(comPort, 'BaudRate', baudRate);
    %fopen(s);

    %fprintf(s, 'DRAW');
    %pause(1);

    %dataDraw = [handles.drawX(:), handles.drawY(:)];
    
    %for i = 1:length(dataDraw)
    %    msg = sprintf('Xd:%.3f,Yd:%.3f\n', dataDraw(i,1), dataDraw(i,2));
    %    fprintf(s, msg);
    %    pause(0.02);
    %end
    
    %fprintf(s, 'ENDDRAW');
    %pause(1);

    %fclose(s);
    %delete(s);
    %clear s;
    %handles.drawX = [];
    %handles.drawY = [];
    %guidata(handles.figure1, handles);
    %disp('Da gui du lieu DRAW');
    %msgbox('Da gui du lieu DRAW', 'Announcement');

% --- Executes on button press in cameraMode.
function cameraMode_Callback(hObject, eventdata, handles)
% hObject    handle to cameraMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cameraMode
global serialObj
set(handles.encoderMode,'Value',0);
fprintf(serialObj, 'CAMERA');

% --- Executes on button press in encoderMode.
function encoderMode_Callback(hObject, eventdata, handles)
% hObject    handle to encoderMode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hint: get(hObject,'Value') returns toggle state of encoderMode
global serialObj
set(handles.cameraMode,'Value',0);
fprintf(serialObj, 'ENCODER');

% --- Executes on selection change in PIDMenu.
function PIDMenu_Callback(hObject, eventdata, handles)
% hObject    handle to PIDMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns PIDMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from PIDMenu
global KpL KiL KdL NL KpR KiR KdR NR
val = get(handles.PIDMenu,'Value');
set(handles.KpLeftGain, 'String', KpL(val));
set(handles.KiLeftGain, 'String', KiL(val));
set(handles.KdLeftGain, 'String', KdL(val));
set(handles.NLeftGain, 'String', NL(val));
set(handles.KpRightGain, 'String', KpR(val));
set(handles.KiRightGain, 'String', KiR(val));
set(handles.KdRightGain, 'String', KdR(val));
set(handles.NRightGain, 'String', NR(val));
    

% --- Executes during object creation, after setting all properties.
function PIDMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PIDMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in HomeTab.
function HomeTab_Callback(hObject, eventdata, handles)
% hObject    handle to HomeTab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.HomePage,'Visible','on');
set(handles.VelPage,'Visible','off');
set(handles.PIDPage,'Visible','off');

% --- Executes on button press in VelTab.
function VelTab_Callback(hObject, eventdata, handles)
% hObject    handle to VelTab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.HomePage,'Visible','off');
set(handles.VelPage,'Visible','on');
set(handles.PIDPage,'Visible','off');

% --- Executes on button press in PIDTab.
function PIDTab_Callback(hObject, eventdata, handles)
% hObject    handle to PIDTab (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.HomePage,'Visible','off');
set(handles.VelPage,'Visible','off');
set(handles.PIDPage,'Visible','on');

% --- Executes on button press in UpdatePID.
function UpdatePID_Callback(hObject, eventdata, handles)
% hObject    handle to UpdatePID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
PLeft = str2double(get(handles.KpLeftGain,'String'));
ILeft = str2double(get(handles.KiLeftGain,'String'));
DLeft = str2double(get(handles.KdLeftGain,'String'));
NLeft = str2double(get(handles.NLeftGain,'String'));

PRight = str2double(get(handles.KpRightGain,'String'));
IRight = str2double(get(handles.KiRightGain,'String'));
DRight = str2double(get(handles.KdRightGain,'String'));
NRight = str2double(get(handles.NRightGain,'String'));

assignin('base','PLeftWS',PLeft);
assignin('base','ILeftWS',ILeft);
assignin('base','DLeftWS',DLeft);
assignin('base','NLeftWS',NLeft);
assignin('base','PRightWS',PRight);
assignin('base','IRightWS',IRight);
assignin('base','DRightWS',DRight);
assignin('base','NRightWS',NRight);

load_system('E:\Nghien_Cuu_Khoa_Hoc_2025_2026\MOBILE ROBOT\Final\Final\Code\Matlab\Simulink\PIDGuideOnLoadDiscrete.slx');
%set_param('Circle','SimulationCommand','update');
%set_param('Circle','SimulationCommand','start');
set_param('PIDGuideOnLoadDiscrete','SimulationCommand','update');
set_param('PIDGuideOnLoadDiscrete','SimulationCommand','start');
msgbox('Da cap nhat thong so PID vao Simulink', 'Announcement');

% --- Executes on button press in ShowRSButton.
function ShowRSButton_Callback(hObject, eventdata, handles)
% hObject    handle to ShowRSButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set_param('PIDGuideOnLoadDiscrete','SimulationCommand','start');

stepSim = evalin('base','StepRS');
RSLeftSim = evalin('base','ResponeLeft');
RSRightSim = evalin('base','ResponeRight');

stepPlot = stepSim.Data;
RSLeftPlot = RSLeftSim.Data;
RSRightPlot = RSRightSim.Data;

cla(handles.axes7);
axes(handles.axes7);
plot(stepPlot,'r--','LineWidth',2);
hold on;
plot(RSLeftPlot,'b','LineWidth',2);
axis([0,50,0,max(RSLeftPlot)+10]);
title('Left Motor Step Respone');
xlabel('Time [s]');
ylabel('Speed [cm/s]');
grid on;

cla(handles.axes8);
axes(handles.axes8);
plot(stepPlot,'r--','LineWidth',2);
hold on;
plot(RSRightPlot,'b','LineWidth',2);
axis([0,50,0,max(RSRightPlot)+10]);
title('Right Motor Step Respone');
xlabel('Time [s]');
ylabel('Speed [cm/s]');
grid on;


% --- Executes on button press in pythonConnect.
function pythonConnect_Callback(hObject, eventdata, handles)
% hObject    handle to pythonConnect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global pySocket

%set(handles.encoderMode,'Value',0);

pythonFile = 'E:\Nghien_Cuu_Khoa_Hoc_2025_2026\MOBILE ROBOT\Final\Final\Python\test3.py';
[~, out] = system('tasklist | find "python"');

if isempty(out)
    system(sprintf('start cmd /k python "%s"', pythonFile));
    %system(sprintf('start /MIN pythonw "%s"', pythonFile));
    disp('Python server started.');
else
    disp('Python server is already running.');
end

disp('Starting Python server...');
pause(5);

pySocket = tcpip('localhost', 5000, 'NetworkRole', 'client');
set(pySocket, 'InputBufferSize', 4096);
set(pySocket, 'Timeout', 1);

try
    fopen(pySocket);
    disp('Da ket noi voi Python');
catch ME
    disp('Khong ket noi duoc voi Python');
    disp(ME.message);
    return;
end


% --- Executes on button press in savedataLog.
function savedataLog_Callback(hObject, eventdata, handles)
% hObject    handle to savedataLog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = guidata(hObject);
data = handles.dataLog;
filename = strcat(get(handles.nameFile,'String'), '.xlsx');
xlswrite(filename, data);
msgbox('Da luu du lieu vao excel', 'Announcement');


function nameFile_Callback(hObject, eventdata, handles)
% hObject    handle to nameFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of nameFile as text
%        str2double(get(hObject,'String')) returns contents of nameFile as a double


% --- Executes during object creation, after setting all properties.
function nameFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to nameFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function paintRes_Callback(hObject, eventdata, handles)
% hObject    handle to paintRes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of paintRes as text
%        str2double(get(hObject,'String')) returns contents of paintRes as a double


% --- Executes during object creation, after setting all properties.
function paintRes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to paintRes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in zoombtn.
function zoombtn_Callback(hObject, eventdata, handles)
% hObject    handle to zoombtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(handles.zoombtn, 'Value') == true
    zoom on;
elseif get(handles.zoombtn, 'Value') == false
    zoom off;
end
