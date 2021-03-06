function [unmutedSound,fs] = unmuteTrombone(mutedSound, fs,tromboneInfo,clipSize,w,olap,mix,outputSound,savePth,fileName,saveSound)
    %%% Unmute trombone sound using addative synthesis given muted sound sample
    % Inputs
    %     mutedSound: array of a muted trombone sound
    %     fs: sampling frequency
    %     tromboneInfo: structure containing results of the analysis
    %        freqValueRatioInfo: Container, with the ratios between frequency peaks
    %        freqValueInfo: Container, with the frequency values of the maximum peaks
    %        freqAmpMap: Container with the amplitude ratios between frequency peaks
    %        freqAmpRatioInfo: Average amplitude ratios between frequency peaks
    %        gain: average gain between unmuted and muted sounds
    %     clipSize: window size
    %     w: clipSizex1 array representing the window
    %     olap: overlap between windows as a percentage
    %     mix: ratio between muted sound and addative synthesis (mix = 1, means only the muted sound gets outputted)
    %     outputSound: boolean used to determine if the sound is outputted
    %     savePth: save location of the output sound
    %     saveSound: boolean used to determine if the sound is saved
    % Outputs
    %   unmutedSound: array of the unmuted Sound
    %   fs: sampling frequency

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

    % Initialize notePitch
    noteFreq = 0;

    %Unmute the sound
    for n = 1:nWindows
        fprintf('Generating Window %d/%d \n',n,nWindows); %display current window
        iStart = (n-1) * hop;
        slice = mutedSound( iStart+1:iStart+clipSize);

        % Take fft of slice
        yfft = abs(fft(slice));
        yfft = yfft(1:floor((clipSize)/2-1)); % Clip fft
    
        % Identify the pitch
        hr = harmonicRatio(slice,fs,Window=w,OverlapLength=hop);

        if hr > 0.9
            % Estimate pitch using matlab pitch function
            noteFreq = pitch(slice,fs,Method='SRH',WindowLength=clipSize,OverlapLength=0);
        elseif (noteFreq == 0)
            % If the first sample is too noisy estimate by using maximum of
            % FFT
            [~,idx] = max(yfft);
            noteFreq = f(idx)/2; 
        end

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