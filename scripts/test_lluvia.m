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

%% set material
materialNames = {'grass', 'anech', 'anech', 'anech', 'anech', 'anech'};
rpf.setRoomMaterialNames(materialNames);

%% set simulation parameters
rpf.setGenerateRIR(1);
rpf.setGenerateBRIR(1);
rpf.setSimulationTypeRT(1);
rpf.setSimulationTypeIS(1);
rpf.setNumParticles(60000);
rpf.setISOrder_PS(2);
rpf.setFilterLength(500)

%% Source and receiver data
% set source position
rpf.setSourcePositions([125, 1, -225]);
rpf.setSourceViewVectors([-1 0 0]);
rpf.setSourceUpVectors([0 0 -1]);

% set receiver position
rpf.setReceiverPositions([125, 1.5, -125]);

% set reciever View Vector
rpf.setReceiverViewVectors([0, 0, -1])

% set source name
rpf.setSourceNames('test');
%%
% definir el HRTF
rpf.setReceiverHRTF('ITA-Kunstkopf_HRIR_AP11_Pressure_Equalized_3x3_256.daff');% HRTF binaural
% definir directividad
rpf.setSourceDirectivity('Omnidirectional.daff');% directividad  

%% run simulation
rpf.run

%% generar la respuesta a impulso
RIR = rpf.getBinauralImpulseResponseItaAudio(); % binaural IR

%% Llamar al audio monofónico
mySound = ita_read('D:\mediaData\rain\rain001.wav');
trackLength = mySound.trackLength;% con este comando sabes el largo del audio

%% Amplitud mySound
mySound.time = mySound.time*2;

%% convolución
mySoundConvolved = ita_convolve(mySound, RIR);% audio ya convolucionado, pero un poco más largo
mySoundConvolved_cortado = ita_time_crop(mySoundConvolved,[0 mySound.trackLength],'time');% el audio anterior se corta al largo del audio monofónico original

%% adding  first sound file
mySound_binaural = mySound_time_structure(mySoundConvolved_cortado, false);

%% adding sound files
mySound_binaural = ita_add(mySound_binaural, mySoundConvolved_cortado);

%% write
ita_write_wav(mySound_binaural,sprintf('wetland_%s%05d.wav', 'binarural_',3),'nbits',32','overwrite',true);

%% time structure
function mySoundConvolved_cortado = mySound_time_structure(mySoundConvolved_cortado, random)
    timeDifference = 10 - mySoundConvolved_cortado.trackLength; % 10 sec minus sound length (in sec)
    maxTime = timeDifference;
    minTime = 0;
    if not(random) 
        randTimeOnset = 0;
        randTimeOffset = timeDifference;
    else
        randTimeOnset = round(((maxTime-minTime).*rand(1,1) + minTime),1);
        randTimeOffset = timeDifference - randTimeOnset;
    end
    length1 = uint32(randTimeOnset*mySoundConvolved_cortado.samplingRate);
    length2 = uint32(randTimeOffset*mySoundConvolved_cortado.samplingRate);

    %% binaural
    mySoundConvolved_cortado.timeData = [zeros(length1,2);mySoundConvolved_cortado.timeData;zeros(length2,2)];
end
