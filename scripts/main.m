%% Clear
clear
clc
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
RECIEVER = 'binaural'; %Options: binaural, mono, stereo, ambisonics

%% Data to save
audioNames = {};
classes = {};
startTimes = {};
endTimes = {};
relativePositions = {};
relativePositionsSph = {};
orientations = {};

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
rpf.setGenerateRIR(1);
rpf.setGenerateBRIR(1);
rpf.setSimulationTypeRT(1);
rpf.setSimulationTypeIS(1);
rpf.setNumParticles(60000);
rpf.setISOrder_PS(2);
rpf.setFilterLength(500)

%% Source and reciever settings
% set receiver settings
rpf.setReceiverPositions([125, 1.5, -125]);
rpf.setReceiverViewVectors([0, 0, -1])

switch RECIEVER
    case 'binaural'
        rpf.setReceiverHRTF('ITA-Kunstkopf_HRIR_AP11_Pressure_Equalized_3x3_256.daff');% HRTF binaural
        IR = 'BRIR';
    case 'mono'
        rpf.setReceiverHRTF('Omnidirectional.daff');% HRTF mono
        IR = 'IR';
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
        IR = 'BRIR';
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
    positions = table(i_main, :); %#ok<*ST2NM> --- Vector que contiene los vectores de las posiciones para el ambiente 
    n = {'N','S','E','O'};
    random_number = randi(4);
    orientation = chose_orientation(n{random_number});
    rpf.setSourceViewVectors(orientation);
    name = sprintf('wetland_%s_%05d.wav', RECIEVER,i_main);

    for class = 1:6 %Se recorre cada clase a travéz de la variable  'class'
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
            % adding sound files
            
%             disp('-------------------------------------')
%             disp('Absolute  position:')
%             disp(taxonomy_positions(k, :));
%             disp('Relative  position:')
%             disp(taxonomy_positions(k, :)+[-125 0 125])
%             disp('-------------------------------------')
             %save data
            audioNames{end+1} = name;
            classes{end+1} = class;
            startTimes{end+1} = timeOnSett;
            endTimes{end+1} = round(timeOffSet, 1);
            aux = position+[-125, -1.5, 125];
            relativePositions{end+1} = aux;
            aux = num2cell(aux);
            [x,y,z] = aux{:};
            [azimuth,elevation,r] = cart2sph(x, z, y);
            relativePositionsSph{end+1} = [azimuth*180/pi, elevation*180/pi, r];
            orientations{end+1} = orientation;
            break
        end
    end
    write_file(mySound, i_main);
    break
end
%%
write_table(audioNames, classes, startTimes, endTimes)
write_positions_table(relativePositions, relativePositionsSph, orientations)
%%
function orientation = chose_orientation(coordinate)
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

function write_table(audioNames, classes, startTimes, endTimes)
    data = [audioNames.', classes.', startTimes.', endTimes.'];
    data = cell2table(data, "variableNames", ...
                            {'AudioNames', 'Classes', 'StartTimes', 'EndTimes'});
    writetable(data,'data_table.csv')
end

function write_positions_table(relativePositions, relativePositionsSph, orientations)
    data = [relativePositions.', relativePositionsSph.', orientations.'];
    data = cell2table(data, "variableNames", ...
                            {'relativePositions', 'relativePositionsSph', 'orientations'});
    writetable(data,'data_positions_table.csv')
end
