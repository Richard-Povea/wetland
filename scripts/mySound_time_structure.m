function [mySoundConvolved_cortado, randTimeOnset, endTime] = mySound_time_structure(mySoundConvolved_cortado, random, path)
    if path
        mySoundConvolved_cortado = ita_read(mySoundConvolved_cortado);
    end
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

    %% fill zeros
    channels = mySoundConvolved_cortado.dimensions;
    mySoundConvolved_cortado.timeData = [zeros(length1,channels);mySoundConvolved_cortado.timeData;zeros(length2,channels)];
end