function saveSounds(data,chanB1,chanA1,chanB2,chanA2,filenames,fs,path)
    %%% Save output
    mkdir(path); %make new folder is it doesn't exist
    
    for k = 1:length(data)
        mutedsound = data{k};
        unmutedsound1 = filter(chanB1,chanA1,mutedsound(:,1));
        unmutedsound2 = filter(chanB2,chanA2,mutedsound(:,2));
        
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
    end
end