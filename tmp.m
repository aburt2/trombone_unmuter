%% Estimate Impulse
impulseModel1 = impulseest(chanOne);
impulseModel2 = impulseest(chanTwo);

%% Estimate Transfer Function
np = 10;
nz = 10;
tfModel1 = tfest(chanOne,np);
% tfModel2 = tfest(chanTwo,np);
compare(chanOne,tfModel1,np,nz)

%% Estimate State Space
np = 4;
ssModel1 = ssest(chanOne,0);
% ssModel2 = ssest(chanTwo,np);
compare(chanOne,ssModel1)



%% Get Impulse model parameters
chanB1 = impulseModel1.Numerator;
chanA1 = impulseModel1.Denominator;
chanB2 = impulseModel2.Numerator;
chanA2 = impulseModel2.Denominator;

%% Get Transfer model parameters
tfB1 = tfModel1.Numerator;
tfA1 = tfModel1.Denominator;
tfB2 = tfModel2.Numerator;
tfA2 = tfModel2.Denominator;

%% Save outputs
savePath = 'Audio/Generated/Impulse/';
fs = 1/TsTest{1};
impulseData = saveImpulseSounds(testData,chanB1,chanA1,chanB2,chanA2,testN,fs,savePath);

savePath = 'Audio/Generated/transferfunction/';
fs = 1/TsTest{1};
tfData = saveImpulseSounds(testData,tfB1,tfA1,tfB2,tfA2,testN,fs,savePath);

savePath = 'Audio/Generated/StateSpace/';
fs = 1/TsTest{1};
ssData = saveStateSounds(testData,ssModel1,ssModel2,testN,fs,savePath);

%% Test Impulse Sounds
idx = 9;
mutedsound = testData{idx};
impulseSound = impulseData{idx};
stateSound = ssData{idx};
tfSound = tfData{idx};
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