function [chanOneData,chanTwoData] = dataPrep(inputData,outputData)
    %Makes each audioclip the same length
    %   Detailed explanation goes here
    
    %check length of input and output data for each experiment is the same
    if (length(inputData) ~= length(outputData))
        error('Input and output data havce different lengths')
    end
    
    %Make temporary cells
    chanOneIn = cell(1,length(inputData));
    chanOneOut = cell(1,length(inputData));
    chanTwoIn = cell(1,length(inputData));
    chanTwoOut = cell(1,length(inputData));
    
    for k = 1:length(inputData)
        inSize = size(inputData{k},1);
        outSize = size(outputData{k},1);
        if (outSize >= inSize)
            tmp = outputData{k};
            outputData{k} = tmp(1:inSize,:);
        else
            tmp = inputData{k};
            inputData{k} = tmp(1:outSize,:);
        end
        %Get input channel information
        chanOneIn{k} = inputData{k}(:,1);
        chanTwoIn{k} = inputData{k}(:,2);
    
        %get output channel information
        chanOneOut{k} = outputData{k}(:,1);
        chanTwoOut{k} = outputData{k}(:,2);
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