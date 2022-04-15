function [tromboneInfo, lastThreshold,lastFreqNum] = analyseSystem(audioPath,AudioFolder,freqnum,threshold,saveModel)    
%%% Estimate the filter parameters
    % Add data to path
    addpath(genpath(AudioFolder));
    
    % Paths to audio
    mutedPath = strcat(audioPath,'/muted/');
    unmutedPath = strcat(audioPath,'/unmuted/');
    
    %  Load Data
    % Make cells to store   
    [mutedData, mutedN, ~] = loadData(mutedPath);
    [unmutedData,unmutedN, Tsoutput] = loadData(unmutedPath);
    fs = 1./Tsoutput{1};
    
    % Take clip of measurements
    clipSize = 4096;
    [chanOneData,~,~,~,~,unmutedN] = dataPrep(mutedData,mutedN,unmutedData,unmutedN,clipSize);
    
    % Create matlab system
    experimentName = cell(size(unmutedN));
    for i = 1:length(unmutedN)
        idx = strfind(unmutedN{i},'.wav')-1;
        experimentName{i} = unmutedN{i}(1:idx);
    end
    chanOne = iddata(chanOneData{1},chanOneData{2},Tsoutput,'ExperimentName',experimentName);
    
    % Test model
    % Split test data by note;
    Bbdata = getexp(chanOne,{'Bb'}); %4
    Bdata = getexp(chanOne,{'B'}); %3
    Cdata = getexp(chanOne,{'C'}); %6
    Dbdata = getexp(chanOne,{'Db'}); %8
    Ddata = getexp(chanOne,{'D'}); %7
    Ebdata = getexp(chanOne,{'Eb'}); %10
    Edata = getexp(chanOne,{'E'}); %9
    Fdata = getexp(chanOne,{'F'}); %11
    Gbdata = getexp(chanOne,{'Gb'}); %13
    Gdata = getexp(chanOne,{'G'}); %12
    Abdata = getexp(chanOne,{'Ab'}); %2
    Adata = getexp(chanOne,{'A'}); %1
    BbOctdata = getexp(chanOne,{'Bboct'}); %5
    
    % Create dictionaries to map data to notes
    dataMap = containers.Map({'Bb','B','C','Db','D','Eb','E','F','Gb','G','Ab','A','Bboct'},{Bbdata,Bdata,Cdata,Dbdata,Ddata,Ebdata,Edata,Fdata,Gbdata,Gdata,Abdata,Adata,BbOctdata});
    noteMap = containers.Map({'Bb','B','C','Db','D','Eb','E','F','Gb','G','Ab','A','Bboct'},{116.54,123.47,130.81,138.59,146.83,155.56,164.81,174.61,185,196,207.65,220,233});
    
    % Analyse system and save details
    freqInfo = cell(1,length(dataMap));
    freqValueRatioInfo = cell(1,length(dataMap)); 
    ampfreqInfo = zeros(length(dataMap),freqnum);
    gainInfo = zeros(1,length(dataMap));
    
    % Get notes from map
    notes = keys(dataMap);
    f = fs*(0:clipSize-1)/clipSize; %frequency range
    
    for n = 1:length(notes)
        key = notes{n}; %grab the note
        data = dataMap(key);

        % Extract time series data
        x = data.InputData;
        y = data.OutputData;

        % Overall gain
        gain = median(abs(y)./abs(x));
    
        % Subtract the data to find missing info
        dif = y - x;
        
        % Take FFT of unmuted data
        yfft = abs(fft(dif));
        yfft = yfft(1:clipSize-1); % Clip fft
    
        % Amplitude ratios
        idx = find(yfft(:,1)>threshold);
        if isempty(idx)
            error('Threshold too high no maximum peaks were found. Please lower threshold')
        end
        if length(idx) < freqnum
            warning('Found less peaks than the specified number, consider lowering threshold')
        end
        amplitudes = yfft(idx);
        [maxGain,fundIdx] = max(amplitudes);
        freqs = f(idx); %Frequencies of each cosine component as a ratio from the fundamental
        freqsValueRatio = floor(freqs/f(fundIdx)); %Frequencies of each cosine component as a ratio from the fundamental
        freqRatio = amplitudes/maxGain; %Amplitudes of each cosine component

        %Sort information in ascending order from fundamental frequency
        [sortedFreqsRatio,sortIdx] = sort(freqsValueRatio);
        sortedFreqs = freqs(sortIdx);
        sortedAmpRatio = freqRatio(sortIdx);

        %Ignore duplicate frequencies
        uniqueIdx = [];
        fullRange = 1:length(sortedFreqsRatio);
        for i = 1:max(sortedFreqsRatio)
            tmp = max(sortedAmpRatio(sortedFreqsRatio==i));
            searchRange = fullRange(sortedFreqsRatio==i); %range of indices we are searching through
            if isempty(tmp)
                warning('Missing Harmonic Number %d',i)
            else
                tmpIdx = find(sortedAmpRatio==tmp);
                for k = 1:length(tmpIdx)
                    if any(tmpIdx(k) == searchRange)
                        uniqueIdx = [uniqueIdx tmpIdx(k)];
                    end
                end  
            end    
        end 

        %Remove duplicates
        freqsRatio = sortedFreqsRatio(uniqueIdx);
        ampRatio = sortedAmpRatio(uniqueIdx);
        freqs = sortedFreqs(uniqueIdx);
    
        %Ensure freqnum is not larger than the found frequencies
        if (freqnum > length(ampRatio))
            ampRatio = [ampRatio zeros(1,freqnum-length(ampRatio))];
        end
        if (freqnum > length(freqs))
            freqs = [freqs zeros(1,freqnum-length(freqs))];
        end
        if (freqnum > length(freqsRatio))
            freqsRatio = [freqsRatio zeros(1,freqnum-length(freqsRatio))];
        end
        
        %Store information in cell array
        freqInfo{n} = freqs(1:freqnum);
        freqValueRatioInfo{n} = freqsRatio(1:freqnum);
        ampfreqInfo(n,:) = ampRatio(1:freqnum);
        gainInfo(n) = gain;
    end
    
    %Average information
    freqValueRatioMap = containers.Map(notes,freqValueRatioInfo); %ratio of frequency to the fundamental frequency
    freqValueMap = containers.Map(notes,freqInfo); %frequencie
    freqAmpRatio = mean(ampfreqInfo,1); %ratio of frequency amplitudes
    avgGain = mean(gainInfo);
    
    % Save model for future use
    tromboneInfo = struct('freqValueRatioInfo',freqValueRatioMap, ...
                      'freqValueInfo',freqValueMap, ...
                      'noteInfo',noteMap, ...
                      'freqAmpRatioInfo',freqAmpRatio,...
                      'gain',avgGain);
    % Store previous run info
    lastThreshold = threshold; 
    lastFreqNum = freqnum;
    if saveModel
        save modelData.mat tromboneInfo lastThreshold lastFreqNum -mat
    end
    disp('Model Created, run unmute.m to test')
end