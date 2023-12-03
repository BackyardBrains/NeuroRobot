function experiences = ml_readFcn(fileName)
    if contains(fileName,"loggedData")
        data = load(fileName);
        % experiences = data.episodeData.Experience{1};
        experiences = data.exp;
    else
        experiences = [];
    end
end