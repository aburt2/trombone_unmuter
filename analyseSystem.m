%%% Estimate the filter parameters

%% Add data to path
clc;clear;close
addpath(genpath('Audio'));

% Paths to audio
dataPath = "Audio/chromaticSet";
mutedPath = strcat(dataPath,'/muted/');
unmutedPath = strcat(dataPath,'/unmuted/');

%  Load Data
% Make cells to store   
[mutedData, mutedN, TsInput] = loadData(mutedPath);
[unmutedData,unmutedN, Tsoutput] = loadData(unmutedPath);
fs = 1./Tsoutput{1};

% Take clip of measurements
clipSize = 4096;
[chanOneData,chanTwoData,mutedClipData,mutedN,unmutedClipData,unmutedN] = dataPrep(mutedData,mutedN,unmutedData,unmutedN,clipSize);

% Create matlab system
experimentName = cell(size(unmutedN));
for i = 1:length(unmutedN)
    idx = strfind(unmutedN{i},'.wav')-1;
    experimentName{i} = unmutedN{i}(1:idx);
end
chanOne = iddata(chanOneData{1},chanOneData{2},Tsoutput,'ExperimentName',experimentName);
chanTwo = iddata(chanTwoData{1},chanTwoData{2},Tsoutput,'ExperimentName',experimentName);

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

%Put all data as a single experiment
allInputs = zeros(length(chanOne.InputData)*clipSize,1);
for n = 1:length(chanOne.InputData)-1
    allInputs(n*clipSize:(n+1)*clipSize-1) = chanOne.InputData{n+1};
end
allData = iddata([],allInputs,TsInput{1});

dataMap = containers.Map({'Bb','B','C','Db','D','Eb','E','F','Gb','G','Ab','A','Bboct'},{Bbdata,Bdata,Cdata,Dbdata,Ddata,Ebdata,Edata,Fdata,Gbdata,Gdata,Abdata,Adata,BbOctdata});
indexMap = containers.Map({'Bb','B','C','Db','D','Eb','E','F','Gb','G','Ab','A','Bboct'},{4,3,6,8,7,10,9,11,13,12,2,1,5});

%% Analyse system and save details
% Average amplitude ratios, noise to add, phase envelope estimation
freqnum = 8;
ampfreqInfo = cell(1,length(dataMap));
freqInfo = cell(1,length(dataMap));
ratioInfo = cell(1,length(dataMap));
notes = keys(dataMap);
f = fs*(0:clipSize-1)/clipSize; %frequency range
threshold = 0.05;

for n = 1:length(notes)
    key = notes{n}; %grab the note
    data = dataMap(key);
    data_idx = indexMap(key);
    % Extract time series data
    x = data.InputData;
    y = data.OutputData;
    
    % Take FFT of data
    Y = abs(fft(y))/max(abs(fft(y))); %unmuted

    % Average time gain
    ratio = mean(max(y)/max(x));

    % Amplitude ratios
    [freqPeaks,locs] = findpeaks(Y,'NPeaks',freqnum,'MinPeakHeight',threshold);
    freqPeaks = freqPeaks/max(freqPeaks);
    freqs = f(locs(1:freqnum));

    %Store information in cell array
    ratioInfo{n} = ratio;
    ampfreqInfo{n} = freqPeaks;
    freqInfo{n} = freqs(1);
end

%Create dictionary
freqMap = containers.Map(notes,freqInfo);
ampMap = containers.Map(notes,ampfreqInfo);
ratioMap = containers.Map(notes,ratioInfo);

%% Save model for future use
save modelData.mat dataMap indexMap freqMap ampMap ratioMap threshold -mat
