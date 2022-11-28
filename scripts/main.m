%% Clear
clear
clc
tic %init timer

%% RNG
global myStream myStream2 RNG %#ok<GVMIS> 
myStream = RandStream('mlfg6331_64');
myStream2 = RandStream("mrg32k3a");
RandStream.setGlobalStream(myStream);

%% Import data
table = import_data;
N_CLASES = size(table, 2);
clases = {'frog', 'bird', 'dog', 'vehicle', 'step', 'murmullo', 'rain',  'wind'};

%% Project settings ------------------------------------------------------------------
global RECIEVER %#ok<GVMIS> 
[START, END, RECIEVER] = import_params;
overwrite = confirm_overwrite;
%-------------------------------------------------------------------------------------
%% Skip data
RNG = skip_data(table, START);

%% Labels para csv de salida
matrixlabel = ({'audioNames', 'classes', 'pathfile', 'startTimes', 'endTimes', ...
    'relative_x', 'relative_y', 'relative_z',...
    'relative_azimuth', 'relative_elevation', 'distance', ...
    'orientations',  'wind', 'rain'});

%% Raven project settings
myLength=250;
myWidth=250;
myHeight=50;
projectName = ['tutorial_1' num2str(myLength) 'x' num2str(myWidth) 'x' num2str(myHeight)];

%% create project and set input data
rpf = itaRavenProject('C:\ITASoftware\Raven\RavenInput\Classroom\Classroom.rpf');   % modify path if not installed in default directory
rpf.copyProjectToNewRPFFile(['C:\ITASoftware\Raven\RavenInput\' projectName '.rpf' ]);
rpf.setProjectName(projectName);
rpf.setModelToShoebox(myLength,myWidth,myHeight);

%% set simulation parameters
% activate image source simulation
rpf.setSimulationTypeIS(1);

% activate ray tracing simulation
rpf.setSimulationTypeRT(1);

% create mono room impulse response
rpf.setGenerateRIR(1);

% create binaural room impulse response
rpf.setGenerateBRIR(1);

rpf.setNumParticles(60000);
rpf.setISOrder_PS(2);
rpf.setFilterLength(500);

rpf.setExportHistogram(0);

%% Source and reciever settings
% set receiver settings
rpf.setReceiverPositions([125, 2, -125]);
rpf.setReceiverViewVectors([0, 0, -1])

switch RECIEVER
    case 'mono'
        rpf.setReceiverHRTF('HRTF_Omni+Fig8.daff');% HRTF mono
        IR = 'IR';
    case 'binaural'
        rpf.setReceiverHRTF('ITA-Kunstkopf_HRIR_AP11_Pressure_Equalized_3x3_256.daff');% HRTF binaural
        IR = 'BRIR';
    case 'stereo'
        rpf.setReceiverHRTF('StereoPanningReceiver.daff');% HRTF stereo
        IR = 'BRIR';
    case 'ambisonics'
        rpf.setGenerateBRIR(0);     % deactivate binaural filters 
        rpf.setGenerateRIR(0);      % deactivate mono filters
        rpf.setGenerateISHOA(1);    % activate HOA for image sources
        rpf.setGenerateRTHOA(1);    % activate HOA for ray tracing 
        rpf.setAmbisonicsOrder(1);  % set HOA Order
        rpf.setReceiverHRTF('ITA-Kunstkopf_HRIR_AP11_Pressure_Equalized_3x3_256.daff');% HRTF binaural
        IR = 'ambisonics';
    otherwise
        fprintf('%s not founded', RECIEVER)
        
end

%set source settings
rpf.setSourceViewVectors([-1 0 0]);
rpf.setSourceUpVectors([0 0 -1]);
rpf.setSourceDirectivity('Omnidirectional.daff');% directividad  

% set source name
rpf.setSourceNames('test');

%% set materials
materialNames = {'grass', 'anech', 'anech', 'anech', 'anech', 'anech'};
rpf.setRoomMaterialNames(materialNames);

%%
%bg_frogs(rpf)
normalize

%% BG NOISE
BG_NOISE_PATH = 'bg_noise.wav';
%distance
BG_NOISE_DISTANCE = 30; %Distance between reciever and bg_noise (+- Z)
DISTANCE = 50; %Distance between reciever and source (+- Z)
%Sounds
bgNoise = bg_noise(rpf, BG_NOISE_PATH, BG_NOISE_DISTANCE);
bg_rain = bg_noise(rpf, pathfile('rain', false), DISTANCE);
bg_wind = bg_noise(rpf, pathfile('wind', false), DISTANCE);

%% MAIN LOOP

for i_main = START:END %Iteración por los ambientes, desde STRAT hasta END, definidos en Project settings
    disp('New line')
    mySound = bgNoise;
    myStream2.Substream = i_main;

    %% rain
    if random_binary(1)
       mySound = ita_add(mySound, bg_rain);
       rain = true;
    else
       rain = false;
    end

    %% wind
    if random_binary(1)
       mySound = ita_add(mySound, bg_wind);
       wind = true;
    else
       wind = false;
    end

    %% Orientations
    positions = table(i_main, :); %#ok<*ST2NM> --- Vector que contiene los vectores de las posiciones para el ambiente 
    n = {'N','S','E','O'};
    random_number = randi(myStream2, 4);
    [vector_orientation, orientation] = chose_orientation(n{random_number});
    rpf.setSourceViewVectors(vector_orientation);
    name = sprintf('wetland_%s_%05d.wav', RECIEVER,i_main);

    %% Event by class 
    for class = clases(1:6) %Se recorre cada clase a travéz de la variable  'class'
        taxonomy_positions = positions{:,class}{1}; %Vector de posiciones de todos los eventos de la clase
        n_event_class = size(taxonomy_positions, 1); %Número de eventos de la clase

        if n_event_class == 0 %Si la clase no tiene eventos en el ambiente i, continua a la siguiente clase
            continue
        end
        for k = 1:n_event_class
            pathFile = pathfile(class{1});
            position = taxonomy_positions(k,:);
            % mySound
            [new_sound, timeOnSett, timeOffSet] = generate_new_sound(rpf, position, pathFile);
            mySound = ita_add(mySound, new_sound) ;
            relative_position = position+[-125, -2, 125];
            relative_position = num2cell(relative_position);
            [x,y,z] = relative_position{:};
            [azimuth,elevation,r] = cart2sph(x, z, y);

            matrixlabel = ([matrixlabel; {name, class, pathFile, timeOnSett, timeOffSet, ...
                            x, y, z, ...
                           azimuth*180/pi, elevation*180/pi, r, ...
                           orientation, wind, rain}]);            
        end
    end
%% Save Sound
    write_file(mySound, i_main);
end
%% Export
write_table(matrixlabel, overwrite)
toc %stop timer

%% Functions
function [orientation, coordinate] = chose_orientation(coordinate)
    switch coordinate
        case 'N'
            orientation = [0, 0, -1];
        case 'S'
            orientation = [0, 0, 1];
        case 'E'
            orientation = [1, 0, 0];
        case 'O'
            orientation = [-1, 0, 0];
    end
end
  
function write_table(matrixlabel, overwrite)
    global RECIEVER
    C = matrixlabel(2:end,:);
    Table = cell2table(C);
    labels = string({matrixlabel{1,:}});
    Table.Properties.VariableNames = labels;
    path = sprintf('.\\Data_generated\\final_data_table_%s.csv', RECIEVER);

    if ~overwrite
        csv = readtable(path);
        Table = ([csv; Table]);
    end
    writetable(Table, path)
end

function logic_vars =  random_binary(n)
    global myStream2 
    logic_vars = randi(myStream2, [0 1],n,1);
end

function mySound = bg_noise(rpf, path, distance)

    [mySound, ~, ~] = generate_new_sound(rpf, [125, 1, -125+distance], path);
    [newSound, ~, ~] = generate_new_sound(rpf, [125, 1, -125.5-distance], path);
    mySound =  ita_add(mySound, newSound);
end

function data = import_data()
    %% Import Data
    data  = readtable('test_20_events.csv','ReadRowNames',true, 'TextType', 'string');
    frog = data.frog;
    bird = data.bird;
    dog = data.dog;
    vehicle = data.car;
    step = data.step;
    murmullo = data.murmullo;
    %% Numeric data
    frog = cellfun(@str2num,frog,'un',0);
    bird = cellfun(@str2num,bird,'un',0);
    dog = cellfun(@str2num,dog,'un',0);
    vehicle = cellfun(@str2num,vehicle,'un',0);
    step = cellfun(@str2num,step,'un',0);
    murmullo = cellfun(@str2num,murmullo,'un',0);
    
    %% List data
    data = table(frog, bird, dog, vehicle, step, murmullo);
end

function n_events = skip_data(data, start)
    n_events = 0;
    if start == 1
        n_events = n_events+1;
        return
    end
    for i = 1:start-1
        a = data(i,:);
        for j = a
            var = j.Variables;
            n_events = size(var{1}, 1) + n_events;
        end
    end
    n_events = n_events+1;
end

function [START, END, RECIEVER] = import_params()
    arrays = 'ambisonics binaural mono stereo'; %Posibles arreglos

    data = split(readlines("params.txt"));
    [START, END, RECIEVER] = data{:, 3};

    if ~any(ismember(arrays, RECIEVER))
        error('%s is not valid as an array, please change it for:\n%s', RECIEVER, arrays);
    end
    START = str2num(START);
    END = str2num(END);
end
