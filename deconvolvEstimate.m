%% Analyse frequency response of trombone sounds
clc;clear;close
load timeData

%% Create matlab system
soundData = fft(iddata(chanOneData{2},chanOneData{1},Tsoutput));
BbOctdata = fft(iddata(chanOneData{2}([1 3]),chanOneData{1}([1 3]),Tsoutput));
Bbdata = fft(iddata(chanOneData{2}([2 4]),chanOneData{1}([2 4]),Tsoutput));
Fdata = fft(iddata(chanOneData{2}([5 6]),chanOneData{1}([5 6]),Tsoutput));

%% Estimate and compare model
data = Bbdata;
np = 8;
Ts = 1/fs;
model = tfest(data,np,'Ts',Ts);
figure
compare(data,model)

% Play sound
udata = iddata([],chanTwoData{1}(2),Ts);
simOut = sim(model,udata);

sound([udata.InputData; zeros(10000,1); simOut.OutputData],fs)