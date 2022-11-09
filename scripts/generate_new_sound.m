function [mySound_binaural, TimeOnset, TimeOffset] = generate_new_sound(rpf, position, sound, IR)
    % set source settings
    rpf.setSourcePositions(position);
    % run simulation
    rpf.run
    
    % generar la respuesta a impulso
    switch IR
        case 'BRIR'
            IR = rpf.getBinauralImpulseResponseItaAudio(); % binaural IR
        case 'IR'
            IR = rpf.getImpulseResponseItaAudio(); % mono IR
    end
    
    % Llamar al audio monofónico
    mySound = ita_read(sound);
    
    % convolución
    mySoundConvolved = ita_convolve(mySound, IR);% audio ya convolucionado, pero un poco más largo
    mySoundConvolved_cortado = ita_time_crop(mySoundConvolved,[0 mySound.trackLength],'time');% el audio anterior se corta al largo del audio monofónico original
    
    % adding sound file
    [mySound_binaural, TimeOnset, TimeOffset] = mySound_time_structure(mySoundConvolved_cortado, true);
end

%% time structure
function [mySoundConvolved_cortado, randTimeOnset, endTime] = mySound_time_structure(mySoundConvolved_cortado, random)
    soundLength = mySoundConvolved_cortado.trackLength;
    timeDifference = 10 - soundLength; % 10 sec minus sound length (in sec)
    maxTime = timeDifference;
    minTime = 0;
    if not(random) 
        randTimeOnset = 0;
        randTimeOffset = timeDifference - mySoundConvolved_cortado;
    else
        randTimeOnset = round(((maxTime-minTime).*rand(1,1) + minTime),1);
        randTimeOffset = timeDifference - randTimeOnset;
    end
    length1 = uint32(randTimeOnset*mySoundConvolved_cortado.samplingRate);
    length2 = uint32(randTimeOffset*mySoundConvolved_cortado.samplingRate);
    endTime = randTimeOnset + soundLength;

    %% binaural
    mySoundConvolved_cortado.timeData = [zeros(length1,2);mySoundConvolved_cortado.timeData;zeros(length2,2)];
end