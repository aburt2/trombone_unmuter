function [tromboneInfo, lastThreshold,lastFreqNum] = analyseSystem(audioPath,freqnum,threshold,linModelSpecs,saveModel)      
    %%% Analyses paired muted and unmuted trombone audio data and outputs parameters for unmuting algorithm for unmuteTrombone.m   
    % Inputs
    %     audioPath: Path to the parent folder where all your audio where your muted and unmuted audio is stored. Make sure that the muted and unmuted audio are stored in folders names muted and unmuted respectively
    %     freqnum: Number of sinusoids you want to add for the additive synthesis
    %     threshold: Minimum threshold value for peak detection
    %     linModelSpecs: Structure containing information for linear model estimation
    %        estimateLinear: boolean used to determine if linear model is estimated
    %        estimator: type of linear model to estimate (ssestimator, or tfestimator)
    %        maxIterations: maximum number of iterations MATLAB can use to estimate the model
    %        order: order of the model (note higher orders require more time to estimate)
    %     saveModel: boolean used to determine if you save the model info as a .mat file
    % Outputs 
    %     tromboneInfo: structure containing results of the analysis
    %        freqValueRatioInfo: Container, with the ratios between frequency peaks
    %        freqValueInfo: Container, with the frequency values of the maximum peaks
    %        freqAmpMap: Container with the amplitude ratios between frequency peaks
    %        freqAmpRatioInfo: Average amplitude ratios between frequency peaks
    %        gain: average gain between unmuted and muted sounds
    %     lastThreshold: threshold used for last run of the analyseSystem (used to automatically rerun the analysis if changed)
    %     lastFreqNum: freqnum used for last run of the analyseSystem (used to automatically rerun the analysis if changed)

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

    % If you want to estimate a linear model
    if linModelSpecs.estimateLinear
        fprintf('Estimating Linear model. Please Wait\n')
        if strcmp(linModelSpecs.estimator,'tfestimator')
            % Load model specs
            tfnp = linModelSpecs.order;
            tfnz = linModelSpecs.order;
            
            % Change number of maximum iterations
            opt = tfestOptions;
            opt.SearchOptions.MaxIterations = linModelSpecs.maxIterations;

            % Estimate Model
            linEstimate = tfest(chanOne,tfnp,tfnz,[],opt);

            % Print model done
            fprintf('Linear Model Estimatation Complete\n')
        elseif strcmp(linModelSpecs.estimator,'ssestimator')
            % Load model specs
            nx = linModelSpecs.order;

            %Change number of maximum iterations
            opt = ssestOptions;
            opt.SearchOptions.MaxIterations = linModelSpecs.maxIterations;

            % Estimate model
            linEstimate = ssest(chanOne,nx,opt);

            % Print model done
            fprintf('Linear Model Estimatation Complete\n')
        elseif strcmp(linModelSpecs.estimator,'inverse')
            % Take FFT of data
            X = fft(chanOne.InputData{1}); %muted
            Y = fft(chanOne.OutputData{1}); %unmuted

            %Remove zeros/very small magnitudes from X
            Xthresh = X;
            inverseThresh = 1e-4;
            Xthresh(abs(Xthresh)<inverseThresh) = inverseThresh;

            % Solve for h
            H = Y(2:end)./Xthresh(2:end);
            linEstimate = real(ifft(H));

            % Print model done
            fprintf('Linear Model Estimatation Complete\n')
        else
            error('Invalid model specification %s',linModelSpecs.estimator)
        end
    end

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
        yfft = yfft(1:floor((clipSize)/2-1)); % Clip fft
    
        % Amplitude ratios
        idx = find(yfft(:,1)>threshold);
        if isempty(idx)
            error('Threshold too high no maximum peaks were found. Please lower threshold')
        end
        if length(idx) < freqnum
            warning('Found less peaks than the specified number, consider lowering threshold')
        end
        amplitudes = yfft(idx);
        [maxGain,~] = max(amplitudes);
        freqs = f(idx); %Frequencies of each cosine component as a ratio from the fundamental
        fundamentalFrequency = pitch(y,fs,WindowLength=clipSize,OverlapLength=0);
        freqsValueRatio = round(freqs/fundamentalFrequency); %Frequencies of each cosine component as a ratio from the fundamental
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
                for k = 1:length(tmpIdx) % find index of the maximum amplitude for the harmonic
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
    % Store frequency amplitude info within a cell
    ampFreqCell = cell(1,length(notes));
    for n = 1:length(ampFreqCell)
        ampFreqCell{n} = ampfreqInfo(n,:);
    end

    %Average information
    freqValueRatioMap = containers.Map(notes,freqValueRatioInfo); %ratio of frequency to the fundamental frequency
    freqValueMap = containers.Map(notes,freqInfo); %frequencie
    freqAmpMap = containers.Map(notes,ampFreqCell); 
    freqAmpRatio = mean(ampfreqInfo,1); %ratio of frequency amplitudes
    avgGain = mean(gainInfo);
    
    % Save model for future use
    tromboneInfo = struct('freqValueRatioInfo',freqValueRatioMap, ...
                      'freqValueInfo',freqValueMap, ...
                      'noteInfo',noteMap, ...
                      'freqAmpMap',freqAmpMap, ...
                      'freqAmpRatioInfo',freqAmpRatio,...
                      'gain',avgGain);

    % Add info if specified
    if linModelSpecs.estimateLinear
        tromboneInfo.linModel = linEstimate;
        tromboneInfo.linModelSpec = linModelSpecs.estimator;
        tromboneInfo.useLinear = true;
    else
        tromboneInfo.useLinear = false;
    end

    % Store previous run info
    lastThreshold = threshold; 
    lastFreqNum = freqnum;
    if saveModel
        save modelData.mat tromboneInfo lastThreshold lastFreqNum -mat
    end
    disp('Model Created, run unmute.m to test')
end