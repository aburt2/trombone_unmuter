function [mutedSound, fileName, fs] = choosePiece(pathArray)
%Select piece from list of loaded sounds
%   Detailed explanation goes here
    %Make empty cell arrays
    dataCell = {};
    nameCell = {};
    fsCell = {};
    
    cellIdx = 1;
    %Load all the data from the path
    for n = 1:length(pathArray)
        [tmpData,tmpN,tmpTs] = loadData(pathArray{n});
        for k = 1:length(tmpData)
            dataCell{cellIdx} = tmpData{k};
            nameCell{cellIdx} = tmpN{k};
            fsCell{cellIdx} = 1/tmpTs{k};
            cellIdx = cellIdx + 1;
        end
    end
    disp('Files Loaded')

    %Create display string
    displayStr = '********************************************************\nList of Audio Clips Loaded\n';
    for i = 1:1:length(nameCell)
        pieceStr = strcat(int2str(i),'. %s\n');
        displayStr = strcat(displayStr,pieceStr);
    end
    %display pieces to play
    fprintf(displayStr,nameCell{:});
    waitingInput = true;

    %Grab User Input
    fprintf('\n') % add space between list and user input
    while waitingInput
        pieceChoice = input('Please select one of the pieces above(enter the number): ','s');
        pieceIndex = str2double(pieceChoice);
        if isnan(pieceIndex) %if non number is given
            disp('Invalid piece number, input an integer for the piece you want to play')
        elseif pieceIndex > length(nameCell) %if number greater than number of pieces is given
            disp('Selected piece number is larger than the number of pieces')
        elseif pieceIndex < 0 %check i'm not given an integer
            disp('Invalid piece number, input is less than 1')
        else
            waitingInput = false;
        end
    end
    %Show user what they selected
    fprintf('\n%s has been selected. Outputing file\n',nameCell{pieceIndex})
    fileName = nameCell{pieceIndex};

    %Output sound
    stereoSound = dataCell{pieceIndex};
    mutedSound = mean(stereoSound,2); %take a mono sound
    fs = fsCell{pieceIndex};
end