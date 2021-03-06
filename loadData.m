function [data,fileNames,Ts] = loadData(path,filetype)
    %%% Loads all the audio files from a folder
    %Inputs
    %   path: Path to parent folder where the audio is located
    %   filetype: filetype for audio(by default .wav)
    %Outputs
    %   data: cell array containing each file
    %   filenames: cell array containing each file name
    %   Ts: cell array containing the sampling Period of each file
    %%%
    if nargin == 1
        filetype = '.wav';
    end
    
    % Grab all the files
    searchCon = strcat('*',filetype);
    searchPath = strcat(path,searchCon);
    listing = dir(searchPath);
    Ts = cell(1,length(listing));
    data = cell(1,length(listing));
    fileNames = cell(1,length(listing));

    for k = 1:length(listing)
        fileN = strcat(path,listing(k).name);
        [y,fs] = audioread(fileN);
        data{k} = y;
        Ts{k} = 1/fs; 
        fileNames{k} = listing(k).name;
    end
end
