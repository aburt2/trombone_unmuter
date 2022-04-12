%% Analyse frequency response of trombone sounds
clc;clear;close
load timeData

%% Create matlab system
soundData = chanOne;
BbOctdata = iddata(chanOneData{1}([1 3]),chanOneData{2}([1 3]),Tsoutput);
Bbdata = iddata(chanOneData{1}([2 4]),chanOneData{2}([2 4]),Tsoutput);
Fdata = iddata(chanOneData{1}([5 6]),chanOneData{2}([5 6]),Tsoutput);

%% Note 
data = Bbdata;
X = fft(data.InputData{1});
Y = fft(data.OutputData{1});
H = X(2:end)./Y(2:end);
h = real(ifft(H));
y = conv(data.OutputData{1},h);
soundsc(y,fs);