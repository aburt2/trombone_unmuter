function outputData = saveStateSounds(data,ssModel1,ssModel2,filenames,fs,path)
    %%% Save output
    mkdir(path); %make new folder is it doesn't exist
    outputData = cell(1,length(data));
    
    for k = 1:length(data)
        mutedsound = data{k};
        unmutedsound1 = sim(ssModel1,mutedsound(:,1));
        unmutedsound2 = sim(ssModel2,mutedsound(:,2));
        
        % combine into single vector
        unmutedsound = [unmutedsound1 unmutedsound2];
    
        %save sound
        tmp = filenames{k};
        extCheck = strfind(tmp,'.mp3');
        if ~isempty(extCheck)
            tmp(extCheck:end) = '.wav';
        end
        filename = strcat(path,tmp);
        audiowrite(filename,unmutedsound,fs);
        outputData{k} = unmutedsound;
    end
end