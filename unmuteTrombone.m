function [unmutedSound,fs] = unmuteTrombone(mutedSound, fs,tromboneInfo,clipSize,w,olap,mix,outputSound,savePth,fileName,saveSound)
%Unmute trombone sound given arguments

    %Unpack tromboneinfo
    freqAmpRatio = tromboneInfo.freqAmpRatioInfo;
    unmutedGain = tromboneInfo.gain;

    %Compute some parameters
    f = fs*(0:clipSize-1)/clipSize; %frequency range
    hop = floor( clipSize * (100-olap) / 100 );
    nWindows = ceil(((length(mutedSound)-clipSize)/hop) + 1);
    
    % Add zeros to input to have even windows
    nY = clipSize + (nWindows-1) * hop;
    testsim = zeros(nY,1);
    if nY > length(mutedSound)
        dif = nY - length(mutedSound);
        mutedSound = [mutedSound; zeros(dif,1)];
    end

    %Unmute the sound
    for n = 1:nWindows
        fprintf('Generating Window %d/%d \n',n,nWindows); %display current window
        iStart = (n-1) * hop;
        slice = mutedSound( iStart+1:iStart+clipSize);
    
        % Take fft
        YSlice = fft(slice);
        magSlice = abs(YSlice);
    
        %Identify main frequency
        [~,idx] = max(magSlice);
    
        % Compensate for messy FFT
        noteFreq = f(idx)/2; %maximum peak tends to be the second harmonic for most notes in the muted data
        % Pull the information needed from containers
        harmRatio = 1:length(freqAmpRatio);
        freqInfo = noteFreq*harmRatio;
 
        %Add cosine waves
        addHarmonics = 0;
        T = 0:1/fs:(clipSize-1)/fs;
        for i = 1:length(freqInfo)
            tmp = freqAmpRatio(i)*cos(2*pi*freqInfo(i)*T);
            addHarmonics = addHarmonics + tmp;
        end
        %Normalize both the slice and the added harmonics
        normHarmonics = addHarmonics*(max(abs(slice))/max(abs(addHarmonics)));
    
        %Add back to main function
        tmp = w.*(mix*slice+(1-mix)*normHarmonics');
        if (iStart == 0)
            testsim(1:clipSize) = tmp;
        else
            testsim(iStart+1:iStart+clipSize) = testsim( iStart+1:iStart+clipSize) + tmp;
        end
    end
    %Normalize output
    unmutedSound = unmutedGain*testsim;
    if max(abs(testsim))>1
        unmutedSound = testsim/max(testsim); 
    end
    
    %Output sound
    if outputSound
        pauseLength = ceil(length(mutedSound)/fs)+1;
        sound(mutedSound,fs)
        pause(pauseLength)
        sound(unmutedSound,fs)
    end
    
    %Save sound
    if saveSound
        filename = strcat(savePth,fileName);
        audiowrite(filename,unmutedSound,fs);
    end
end