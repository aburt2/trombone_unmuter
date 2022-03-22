%% Analyse frequency response of trombone sounds
clc;clear;close
load modelData
load analysisData

% Plot fft
%% Magnitude Frequency Response
idx = 5;
input = inputData{idx};
measuredOut = outputData{idx};
simulatedOut = [sim(ssModel1,input(:,1)) sim(ssModel2,input(:,2))];

% Find frequency response and plot
subplot(1,3,1)
titlestr = 'Frequency Response of muted Note';
fftplot(input,fs,titlestr)

subplot(1,3,2)
titlestr = 'Frequency Response of Unmuted Note';
fftplot(measuredOut,fs,titlestr)

subplot(1,3,3)
titlestr = 'Frequency Response of Simulated Unmuted Note';
fftplot(simulatedOut,fs,titlestr)