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

%% Raven ------------------------------------------------------------------
%% project settings
myLength=250;
myWidth=250;
myHeight=100;
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
%set source settings
rpf.setSourceViewVectors([-1 0 0]);
rpf.setSourceUpVectors([0 0 -1]);
% set source name
rpf.setSourceNames('test');

%% set materials
materialNames = {'grass', 'anech', 'anech', 'anech', 'anech', 'anech'};
rpf.setRoomMaterialNames(materialNames);

%% Create Settings

for i = 1:20
    disp('New line')
    positions = table(i, :); %#ok<*ST2NM> --- Select i row
    for j = 1:6
        pathFile = pathfile(j)
        taxonomy_positions = positions{:,j}{1};
        n = size(taxonomy_positions, 1);

        if n == 0
            continue
        elseif n == 1
            mySound = generate_new_sound(rpf, taxonomy_positions(1,:), pathFile, 'BRIR');
            continue
        end
        mySound = generate_new_sound(rpf, taxonomy_positions(1,:), pathFile, 'BRIR');
        for k = 2:n
            pathFile = pathfile(j)
            % mySound
            mySound = ita_add(mySound, generate_new_sound(rpf, taxonomy_positions(k,:), pathFile, 'BRIR')) ;
            % adding sound files
            
            disp('-------------------------------------')
            disp('Absolute  position:')
            disp(taxonomy_positions(k, :));
            disp('Relative  position:')
            disp(taxonomy_positions(k, :)+[-125 0 125])
            disp('-------------------------------------')
        end

        break
    end
    write_file(mySound, i);
    break
end


%% Write File
write_file(mySound_binaural, 5)


%% guardar audio polifónico final
function write_file(mySound_binaural, n_iteration)
    ita_write_wav(mySound_binaural,sprintf('wetland_%s%05d.wav', 'binarural_',n_iteration),'nbits',32','overwrite',true);
end

%% 


