%% Unmute trombone sound
clc;clear;close
load modelData.mat %from analyseSystem.m file

% Load data
testPath = "Audio/validationSet/";
dataPath = "Audio/chromaticSet";
mutedPath = strcat(dataPath,'/muted/');
unmutedPath = strcat(dataPath,'/unmuted/');

%  Load Data
% Make cells to store   
[mutedData, mutedN, TsInput] = loadData(mutedPath);
[unmutedData,unmutedN, Tsoutput] = loadData(unmutedPath);
[testData,testN,TsTest] = loadData(testPath);
disp('Files loaded')
testN %display the file names

% Specify Inputs
noteChoice = 'B';
output_sound = false;
save_sound = false;

% Get data
data = dataMap(noteChoice);
data_idx = indexMap(noteChoice);
filter_input = mutedData{data_idx}(:,1);
savepth = 'Audio/Generated/';

% Algorithm parameters
mix = 0;
clipSize = 4096;
olap = 50;
window = 'hann';
w = olaw('hann',clipSize);

% Computed parameters
fs = 1./Tsoutput{1};
f = fs*(0:clipSize-1)/clipSize; %frequency range
hop = floor( clipSize * (100-olap) / 100 );
nWindows = ceil(((length(filter_input)-clipSize)/hop) + 1);

% Add zeros to input to have even windows
nY = clipSize + (nWindows-1) * hop;
testsim = zeros(nY,1);
if nY > length(filter_input)
    dif = nY - length(filter_input);
    filter_input = [filter_input; zeros(dif,1)];
end

%% Unmute
for n = 1:nWindows
    iStart = (n-1) * hop;
    slice = filter_input( iStart+1:iStart+clipSize);

    % Take fft
    YSlice = fft(slice);
    magSlice = abs(YSlice);
    normSlice = magSlice/max(magSlice);

    %Identify main frequency
    [freqPeaks,locs] = findpeaks(normSlice,'NPeaks',1,'MinPeakHeight',0.2);
    
    %Identify nearest frequency(look within an octave)
    dist = 1e9;
    freqs = values(freqMap);
    freqIdx = 1;
    for k = 1:length(freqMap)
        tmp = abs(f(locs) - freqs{k});
        if tmp < dist
            freqIdx = k;
            dist = tmp;
        end
%         tmp = abs(f(locs) - 2*freqs{k}); %test octave
%         if tmp < dist
%             freqIdx = k;
%             dist = tmp;
%         end
    end
    note = keys(freqMap);
    note = note{freqIdx}

    %Other frequencies
    ratios = 1:5;
    addFreq = f(locs)*ratios;
    amps = ampMap(note);
    amps = amps*magSlice(locs);

    %Add cosine waves
    addHarmonics = 0;
    T = 0:1/fs:(clipSize-1)/fs;
    for i = 1:length(addFreq)
        tmp = amps(i)*cos(2*pi*addFreq(i)*T);
        addHarmonics = addHarmonics + tmp;
    end

    %Add back to main function
    tmp = w.*(mix*slice+addHarmonics');
    if (iStart == 0)
        testsim(iStart+1:iStart+clipSize) = tmp;
    else
        testsim(iStart+1:iStart+clipSize) = testsim( iStart+1:iStart+clipSize) + tmp;
    end


end
soundsc(filter_input,fs)
pause(3)
soundsc(testsim,fs)
% filename = strcat(savepth,testN{test_idx});
% audiowrite(filename,testsim,fs);