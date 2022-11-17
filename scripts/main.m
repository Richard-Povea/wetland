%% Clear
clear
clc
tic %init temer
%% RNG
rng('default')
%% Import Data
data  = readtable('test_20_events.csv','ReadRowNames',true, 'TextType', 'string');
frogs = data.frog;
birds = data.bird;
dogs = data.dog;
cars = data.car;
steps = data.step;
murmullos = data.murmullo;
%% Numeric data
frogs = cellfun(@str2num,frogs,'un',0);
birds = cellfun(@str2num,birds,'un',0);
dogs = cellfun(@str2num,dogs,'un',0);
cars = cellfun(@str2num,cars,'un',0);
steps = cellfun(@str2num,steps,'un',0);
murmullos = cellfun(@str2num,murmullos,'un',0);

%% List data
table = table(frogs, birds, dogs, cars, steps, murmullos);

%% Project settings ------------------------------------------------------------------
START = 1;
END = 5;
RECIEVER = 'ambisonics'; %Options: binaural, mono, stereo, ambisonics
% Labels
matrixlabel = ({'audioNames', 'classes', 'startTimes', 'endTimes', 'relativePositions', ...
    'relativePositionsSph', 'orientations',  'wind', 'rain'});

%% Rven project settings
myLength=250;
myWidth=250;
myHeight=50;
projectName = [ 'tutorial_1' num2str(myLength) 'x' num2str(myWidth) 'x' num2str(myHeight) ];

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
rpf.setReceiverPositions([125, 1.5, -125]);
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

%% MAIN LOOP

for i_main = START:END %Iteración por los ambientes, desde STRAT hasta END, definidos en Project settings
    disp('New line')
    mySound = empty_audio;

    % rain
    if random_binary(1)
       mySound = add_noise(mySound,7);
       rain = true;
    else
       rain = false;
    end

    % wind
    if random_binary(1)
       mySound = add_noise(mySound,8);
       wind = true;
    else
       wind = false;
    end
    
    positions = table(i_main, :); %#ok<*ST2NM> --- Vector que contiene los vectores de las posiciones para el ambiente 
    n = {'N','S','E','O'};
    random_number = randi(4);
    [vector_orientation, orientation] = chose_orientation(n{random_number});
    rpf.setSourceViewVectors(vector_orientation);
    name = sprintf('wetland_%s_%05d.wav', RECIEVER,i_main);

    for class = 1:5 %Se recorre cada clase a travéz de la variable  'class'
        pathFile = pathfile(class);
        taxonomy_positions = positions{:,class}{1}; %Vector de posiciones de todos los eventos de la clase
        n_event_class = size(taxonomy_positions, 1); %Número de eventos de la clase

        if n_event_class == 0 %Si la clase no tiene eventos en el ambiente i, continua a la siguiente clase
            continue
        end
        for k = 1:n_event_class
            pathFile = pathfile(class);
            position = taxonomy_positions(k,:);
            % mySound
            [new_sound, timeOnSett, timeOffSet] = generate_new_sound(rpf, position, pathFile, IR);
            mySound = ita_add(mySound, new_sound) ;
            aux = position+[-125, -1.5, 125];
            aux = num2cell(aux);
            [x,y,z] = aux{:};
            [azimuth,elevation,r] = cart2sph(x, z, y);

            matrixlabel = ([matrixlabel; {name, class,timeOnSett, timeOffSet, aux, ...
                           [azimuth*180/pi, elevation*180/pi, r], orientation, wind, rain}]);
            
        end
    end
    write_file(mySound, i_main, RECIEVER);
end
%% Export
write_table(matrixlabel, RECIEVER)
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

function mySound = empty_audio()
    mySound = itaAudio;
    mySound.samplingRate = 44100;
    mySound.channelNames{1} = 'channel 1';
    mySound.trackLength = 10;
    mySound.time = zeros(mySound.trackLength*mySound.samplingRate,2);
end

function write_table(matrixlabel, reciever)
    C = matrixlabel(2:end,:);
    Table = cell2table(C);
    labels = {matrixlabel{1,:}};
    Table.Properties.VariableNames = labels;
    writetable(Table, sprintf('final_data_table_%s.csv', reciever))
end

function logic_vars =  random_binary(n)
    logic_vars = randi([0 1],n,1);
end

function mySound = add_noise(my_sound, class)
    mySound = ita_add(my_sound, mySound_time_structure(pathfile(class), true, true));
end