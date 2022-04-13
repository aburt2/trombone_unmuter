%%% Estimate the filter parameters

%% Add data to path
clc;clear;close
addpath(genpath('Audio'));

% Paths to audio
dataPath = "Audio/chromaticSet";
mutedPath = strcat(dataPath,'/muted/');
unmutedPath = strcat(dataPath,'/unmuted/');
testPath = "Audio/validationSet/";

%  Load Data
% Make cells to store   
[mutedData, mutedN, TsInput] = loadData(mutedPath);
[unmutedData,unmutedN, Tsoutput] = loadData(unmutedPath);
[testData,testN,TsTest] = loadData(testPath);
fs = 1./Tsoutput{1};

% Take clip of measurements
clipSize = 4096;
[chanOneData,chanTwoData,mutedClipData,mutedN,unmutedClipData,unmutedN] = dataPrep(mutedData,mutedN,unmutedData,unmutedN,clipSize);

%% Create matlab system
experimentName = cell(size(unmutedN));
for i = 1:length(unmutedN)
    idx = strfind(unmutedN{i},'.wav')-1;
    experimentName{i} = unmutedN{i}(1:idx);
end
chanOne = iddata(chanOneData{1},chanOneData{2},Tsoutput,'ExperimentName',experimentName);
chanTwo = iddata(chanTwoData{1},chanTwoData{2},Tsoutput,'ExperimentName',experimentName);

%% Test model
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

dataMap = containers.Map({'Bb','B','C','Db','D','Eb','E','F','Gb','G','Ab','A','Bboct','all'},{Bbdata,Bdata,Cdata,Dbdata,Ddata,Ebdata,Edata,Fdata,Gbdata,Gdata,Abdata,Adata,BbOctdata,allData});
indexMap = containers.Map({'Bb','B','C','Db','D','Eb','E','F','Gb','G','Ab','A','Bboct','all'},{4,3,6,8,7,10,9,11,13,12,2,1,5,5});

%% Undo effect of mute
noteChoice = 'Bboct';
output_sound = false;
save_sound = false;

% Get data
data = dataMap(noteChoice);
data_idx = indexMap(noteChoice);
filter_input = mutedData{data_idx}(:,1);
filter_output = unmutedData{data_idx}(:,1);

%Estimator choice
estimator = 'inverse';
savepth = strcat('Audio/Generated/',estimator);

%Transfer Estimator parameters
tfnp = 40;
tfnz = 20;
tfopt = tfestOptions;
tfopt.SearchOptions.MaxIterations = 100;

%State Space Estimator parameters
ssn = 3;
ssopt = ssestOptions;
ssopt.SearchOptions.MaxIterations = 100;

%Inverse Filter parameters
threshold = 1e-4;

if strcmp(estimator,'tfestimator')
    udata = iddata([],filter_input,1/fs);
    tfEstimate = tfest(data,tfnp,tfnz,[],tfopt);
    ysim = sim(tfEstimate,udata);
    ysim = ysim.OutputData;
elseif strcmp(estimator,'statespace')
    udata = iddata([],filter_input,1/fs);
    ssEstimate = ssest(data,ssn,ssopt);
    ysim = sim(ssEstimate,udata);
    ysim = ysim.OutputData;
elseif strcmp(estimator,'inverse')
    % Take FFT of data
    X = fft(data.InputData); %muted
    Y = fft(data.OutputData); %unmuted
    %Remove zeros/very small magnitudes from X
    Xthresh = X;
    Xthresh(abs(Xthresh)<threshold) = threshold;
    % Solve for h
    H = Y(2:end)./Xthresh(2:end);
    h = real(ifft(H));
    % Extend impulse response to length of signal
    zeroSize = size(filter_input,1)-size(h,1);
    h0 = [h ;zeros(zeroSize,1)];
    ysim = conv(filter_input,h0); %convolution
end
% Output sound
if output_sound
    soundsc(filter_output,fs)
    pause(3)
    soundsc(ysim,fs)
end
% Save audio file
if save_sound
    filename = strcat(savepth,unmutedN{data_idx});
    audiowrite(filename,ysim,fs);
end
%% Simulated the test pieces
test_idx = 1;
filter_input = testData{test_idx}(:,1);
if strcmp(estimator,'tfestimator')
    udata = iddata([],filter_input,1/fs);
    testsim = sim(tfEstimate,udata);
    testsim = testsim.OutputData;    
elseif strcmp(estimator,'statespace')
    testsim = sim(ssEstimate,udata);
    testsim = testsim.OutputData;
elseif strcmp(estimator,'inverse')
    zeroSize = size(filter_input,1)-size(h,1);
    h0 = [h ;zeros(zeroSize,1)];
    testsim = conv(filter_input,h0); %convolution
end
soundsc(testsim,fs)
filename = strcat('Audio/Generated/transferfunction/',testN{test_idx});
audiowrite(filename,testsim,fs);
%% Plot FFT
%Clip simulated output for fft
yclip = ysim(floor(length(ysim)/2):floor(length(ysim)/2)+clipSize-1); 

%Plot all the graphs
subplot(2,3,1)
graphTitle1 = strcat("FFT of muted ",noteChoice);
fftplot(data.InputData,fs,'mag',graphTitle1)

subplot(2,3,2)
graphTitle2 = strcat("FFT of unmuted ",noteChoice);
fftplot(data.OutputData,fs,'mag',graphTitle2)

subplot(2,3,3)
graphTitle3 = strcat("FFT of simulated unmuted ",noteChoice);
fftplot(yclip,fs,'mag',graphTitle3)

subplot(2,3,4)
graphTitle1 = strcat("FFT of muted ",noteChoice);
fftplot(data.InputData,fs,'phase',graphTitle1)

subplot(2,3,5)
graphTitle2 = strcat("FFT of unmuted ",noteChoice);
fftplot(data.OutputData,fs,'phase',graphTitle2)

subplot(2,3,6)
graphTitle3 = strcat("FFT of simulated unmuted ",noteChoice);
fftplot(yclip,fs,'phase',graphTitle3)

% Plot FFT of inverse filter
if strcmp(estimator,'inverse')
    figure
    graphTitle4 = strcat("Inverse filter frequency Response for ",noteChoice);
    fftplot(h,fs,'mag',graphTitle4)
end