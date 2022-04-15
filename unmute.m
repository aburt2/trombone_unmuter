%% Unmute trombone sound
clc;clear;close
% Load data
testPath = "Audio/validationSet/";
dataPath = "Audio/chromaticSet";
mutedPath = strcat(dataPath,'/muted/');
unmutedPath = strcat(dataPath,'/unmuted/');
threshold = 4;
freqnum = 10; %Number of sinusoids to add
saveModel = true;

%If there is no saved model data run analyseSystem
try
    load modelData.mat %from analyseSystem.m function
    %If the threshold has been changed run analyseSystem again
    if (lastThreshold ~= threshold) || (lastFreqNum ~= freqnum)
        [tromboneInfo,lastThreshold,lastFreqNum] = analyseSystem(dataPath,'Audio',freqnum,threshold,saveModel);
    end
catch ME
    disp('No saved model data detected running analyseSystem.m to create model')
    [tromboneInfo,lastThreshold,lastFreqNum] = analyseSystem(dataPath,'Audio',freqnum,threshold,saveModel);
end


%  Load Data
% Make cells to store   
pathArray = {testPath,mutedPath};

% Specify Inputs
outputSound = true;
saveSound = false;
mix = 0.05;
clipSize = 4096;
olap = 50;
window = 'hann';
w = olaw('hann',clipSize);
savePth = 'Audio/Generated/';

% Get data
[mutedSound,inputfileName, fs] = choosePiece(pathArray);
fileName = strcat('unMuted',inputfileName);

%Unmute the sound
[unmutedSound,fs] = unmuteTrombone(mutedSound,fs,tromboneInfo,clipSize,w,olap,mix,outputSound,savePth,fileName,saveSound);
