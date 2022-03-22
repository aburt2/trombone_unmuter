%test reordering
inN = cell(1,length(inputN));
outN = cell(1,length(inputN));
orderMap = containers.Map;
for i = 1:length(inputN)
    idx = strfind(inputN{i},'-muted')-1;
    inN{i} = inputN{i}(1:idx);
end
for n = 1:length(inputN)
    idx = strfind(outputN{n},'.wav')-1;
    outN{n} = outputN{n}(1:idx);
    orderMap(outN{n}) = n;
end
inMap = [];
outMap = [];
for value = inN
    key = value{1};
    inMap = [inMap orderMap(key)];
end
for value = outN
    key = value{1};
    outMap = [outMap orderMap(key)];
end