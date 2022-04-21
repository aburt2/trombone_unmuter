function [chanOneData,chanTwoData,inputData,inputN,outputData,outputN] = dataPrep(inputData,inputN,outputData,outputN,clipSize)
    %Makes each audioclip the same length, and stores channel one and two
    %data in two data structures
    %Inputs
    %   inputData,outputData: cell array containing N stereo sound samples
    %   inputN,outputN: cell array containing N names of the sound samples
    %   clipSize: clipped size for experiment data
    %Outputs   
    %   chanOneData,chanTwoData: experiment data for channel one and two
    %   inputData,outputData: cell array containing N stereo sound samples
    %   inputN,outputN: cell array containing N names of the sound samples
    
    %check length of input and output data for each experiment is the same
    if (length(inputData) ~= length(outputData))
        error('Input and output data havce different lengths')
    end

    %remove -muted from inputN
    % Grab list of file names
    inN = cell(1,length(inputN));
    outN = cell(1,length(inputN));
    orderMap = containers.Map;
    for i = 1:length(inputN)
        idx = strfind(inputN{i},'-muted')-1;
        if isempty(idx)
            idx = strfind(inputN{i},'.wav')-1;
        end
        inN{i} = inputN{i}(1:idx);
    end
    for n = 1:length(inputN)
        idx = strfind(outputN{n},'.wav')-1;
        outN{n} = outputN{n}(1:idx);
        orderMap(outN{n}) = n;
    end

    % Order matrices so trials are in the right order
    inMap = [];
    for value = inN
        key = value{1};
        inMap = [inMap orderMap(key)];
    end
    inputN = inputN(inMap);
    inputData = inputData(inMap);
    
    %Make temporary cells
    chanOneIn = cell(1,length(inputData));
    chanOneOut = cell(1,length(inputData));
    chanTwoIn = cell(1,length(inputData));
    chanTwoOut = cell(1,length(inputData));
    
    % Iterate through input and output to clip the data to the clipSize
    for k = 1:length(inputData)
        inSize = size(inputData{k},1);
        outSize = size(outputData{k},1);
        if (outSize/2 <= clipSize)
            clipSize = outSize/2-1;
        elseif (inSize/2 <= clipSize)
            clipSize = inSize/2-1;
        end
        %Take the middle of the note
        tmpIn = inputData{k}(floor(inSize/2):floor(inSize/2)+clipSize-1,:);
        tmpOut = outputData{k}(floor(outSize/2):floor(outSize/2)+clipSize-1,:);

        %Get input channel information
        chanOneIn{k} = tmpIn(:,1);
        chanTwoIn{k} = tmpIn(:,2);
    
        %get output channel information
        chanOneOut{k} = tmpOut(:,1);
        chanTwoOut{k} = tmpOut(:,2);
    end
    % Make output cells
    chanOneData = cell(1,2);
    chanTwoData = cell(1,2);

    %Add Channel One data
    chanOneData{1} = chanOneOut;
    chanOneData{2} = chanOneIn;
    
    %Add Channel Two Data
    chanTwoData{1} = chanTwoOut;
    chanTwoData{2} = chanTwoIn;
end