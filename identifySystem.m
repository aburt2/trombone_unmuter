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
[chanOneData,chanTwoData] = dataPrep(inputData,outputData);

%% Create matlab system
chanOne = iddata(chanOneData{1},chanOneData{2},Tsoutput);
chanTwo = iddata(chanTwoData{1},chanTwoData{2},Tsoutput);

chanModel1 = impulseest(chanOne);
chanModel2 = impulseest(chanTwo);

%% Test model
% Load all test data
testPath = "Audio/validationSet/";
[testData,testN,TsTest] = loadData(testPath);

% Get model parameters
chanB1 = chanModel1.Numerator;
chanA1 = chanModel1.Denominator;
chanB2 = chanModel2.Numerator;
chanA2 = chanModel2.Denominator;

%% Filter Sound
idx = 9;
mutedsound = testData{idx};
fs = 1/TsTest{idx};
unmutedsound1 = filter(chanB1,chanA1,mutedsound(:,1));
unmutedsound2 = filter(chanB2,chanA2,mutedsound(:,2));

% combine into single vector
unmutedsound = [unmutedsound1 unmutedsound2];

%% Play sound
soundsc(mutedsound,fs);
soundsc(unmutedsound,fs);

%% Save outputs
savePath = 'Audio/Generated/';
fs = 1/TsTest{1};
saveSounds(testData,chanB1,chanA1,chanB2,chanA2,testN,fs,savePath)


