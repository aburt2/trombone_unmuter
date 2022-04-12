%% Analyse frequency response of trombone sounds
clc;clear;close
load timeData

%% Create matlab system
soundData = chanOne;
BbOctdata = iddata(chanOneData{1}([1 3]),chanOneData{2}([1 3]),Tsoutput);
Bbdata = iddata(chanOneData{1}([2 4]),chanOneData{2}([2 4]),Tsoutput);
Fdata = iddata(chanOneData{1}([5 6]),chanOneData{2}([5 6]),Tsoutput);

%% Estimate and compare model
data = Bbdata;
np = 5;
Ts = 1/fs;
% model = ssest(data,np,'Ts',Ts);
model = tfest(data,np,'Ts',Ts);
figure
compare(data,model)

% Play sound
udata = iddata([],testData{2}(:,1),Ts);
simOut = sim(model,udata);

soundsc([udata.InputData; zeros(10000,1); simOut.OutputData],fs)