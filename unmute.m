%% Unmute trombone sound
clc;clear;close
% Load data
testPath = "Audio/validationSet/";
dataPath = "Audio/chromaticSet";
mutedPath = strcat(dataPath,'/muted/');
unmutedPath = strcat(dataPath,'/unmuted/');
threshold = 1;
freqnum = 10; %Number of sinusoids to add
saveModel = true;

%Specify linear model
% Supported Estimators: tfestimator, ssestimator, inverse
% Note that large order models take a long time to estimate
linModelSpecs = struct('estimateLinear',false, ...
                        'estimator', 'ssestimator', ...
                        'maxIterations',100, ...,
                        'order', 3);
rerun = false;

%If there is no saved model data run analyseSystem
try
    load modelData.mat %from analyseSystem.m function

    %If the threshold has been changed run analyseSystem again
    if ((lastThreshold ~= threshold) || (lastFreqNum ~= freqnum)) || rerun
        fprintf('Updating model\n')
        [tromboneInfo,lastThreshold,lastFreqNum] = analyseSystem(dataPath,freqnum,threshold,linModelSpecs,saveModel);
    end
catch ME
    fprintf('No saved model data detected running analyseSystem.m to create model\n')
    [tromboneInfo,lastThreshold,lastFreqNum] = analyseSystem(dataPath,freqnum,threshold,linModelSpecs,saveModel);
end


%  Load Data
% Make cells to store   
pathArray = {testPath,mutedPath};

% Specify Inputs
outputSound = true;
saveSound = false;
mix = 0.03;
clipSize = 4096;
olap = 50;
window = 'hann';
w = olaw('hann',clipSize);
savePth = 'Audio/Generated/';
preProcess = false;

% Get data
[mutedSound,inputfileName, fs] = choosePiece(pathArray);
fileName = strcat('unMuted',inputfileName);

%Run trombone sound through linear model (emphasises first harmonic)
% Grab linear model if specified
if tromboneInfo.useLinear
    fprintf('Passing sound through linear model\n')
    
    linModel = tromboneInfo.linModel;
    estimator = tromboneInfo.linModelSpec;
    udata = iddata([],mutedSound,1/fs);

    % Pass through linear model to emphasize first harmonic
    if (strcmp(estimator,'tfestimator') || strcmp(estimator,'ssestimator'))
        ysim = sim(linModel,udata);
        processedMutedSound = ysim.OutputData;
    elseif strcmp(estimator,'inverse')
        % Extend impulse response to length of signal
        zeroSize = size(filter_input,1)-size(h,1);
        h0 = [h ;zeros(zeroSize,1)];
        processedMutedSound = conv(filter_input,h0); %convolution
    end

    %Unmute the sound
    [unmutedSound,fs] = unmuteTrombone(processedMutedSound,fs,tromboneInfo,clipSize,w,olap,mix,outputSound,savePth,fileName,saveSound);
elseif preProcess
    % TODO: add basic filter to remove noise
    processedMutedSound = mutedSound;
    [unmutedSound,fs] = unmuteTrombone(processedMutedSound,fs,tromboneInfo,clipSize,w,olap,mix,outputSound,savePth,fileName,saveSound);
else
    %Unmute the sound
    [unmutedSound,fs] = unmuteTrombone(mutedSound,fs,tromboneInfo,clipSize,w,olap,mix,outputSound,savePth,fileName,saveSound);
end


