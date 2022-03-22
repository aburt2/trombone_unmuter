%%% Estimate the filter parameters

%% Add data to path
clc;clear;close
addpath(genpath('Audio'));

% Create data paths
dataPath = "Audio/testSet";
inputPath = strcat(dataPath,'/Muted/');
outputPath = strcat(dataPath,'/Unmuted/');

%%  Load Data
% Make cells to store   
[inputData, inputN, TsInput] = loadData(inputPath);
[outputData,outputN, Tsoutput] = loadData(outputPath);

%% Equalize measurements
clipSize = 2000;
[chanOneData,chanTwoData,inputData,inputN,outputData,outputN] = dataPrep(inputData,inputN,outputData,outputN,clipSize);

%% Create matlab system
chanOne = iddata(chanOneData{1},chanOneData{2},Tsoutput);
chanTwo = iddata(chanTwoData{1},chanTwoData{2},Tsoutput);

%% Estimate Impulse
impulseModel1 = impulseest(chanOne);
impulseModel2 = impulseest(chanTwo);

%% Estimate Transfer Function
np = 3;
ssModel1 = ssest(chanOne,np);
ssModel2 = ssest(chanTwo,np);

%% Test model
% Load all test data
testPath = "Audio/validationSet/";
[testData,testN,TsTest] = loadData(testPath);

% Get model parameters
chanB1 = impulseModel1.Numerator;
chanA1 = impulseModel1.Denominator;
chanB2 = impulseModel2.Numerator;
chanA2 = impulseModel2.Denominator;

%% Save outputs
savePath = 'Audio/Generated/Impulse/';
fs = 1/TsTest{1};
impulseData = saveImpulseSounds(testData,chanB1,chanA1,chanB2,chanA2,testN,fs,savePath);

savePath = 'Audio/Generated/StateSpace/';
fs = 1/TsTest{1};
ssData = saveStateSounds(testData,ssModel1,ssModel2,testN,fs,savePath);

%% Test Impulse Sounds
idx = 9;
mutedsound = testData{idx};
impulseSound = impulseData{idx};
stateSound = ssData{idx};
%% Plot three sounds
subplot(3,1,1)
plot(mutedsound)
title('Muted Sound')
subplot(3,1,2)
plot(impulseSound)
title('Impulse Model Prediction')
subplot(3,1,3)
plot(stateSound)
title('State Space Model Predicition')

%% Play sound
soundsc(mutedsound,fs);
soundsc(impulseSound,fs);
soundsc(stateSound,fs)