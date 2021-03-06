

datetimestr =  datestr(datetime('now'), "yyyy-mm-dd-HH-MM-SS");
logdir = "outcomes/" + datetimestr + '/';
mkdir(logdir);
saveCsvsDir = logdir+"csvs/";
saveImagesDir = logdir+"images/";
mkdir(saveCsvsDir);
mkdir(saveImagesDir);

payoffCsvFiles = [];
cd payoff
payoffCsvFileStructs = dir("*.csv");
payoffCsvFiles = string({payoffCsvFileStructs.name});
payoffMatrixes = [];
payoffNames = [];
for i = 1:length(payoffCsvFiles)
    payoffCsvFile =  payoffCsvFiles(i);
    payoffMatrix = csvread(payoffCsvFile,1,1);
    payoffMatrixes = cat(3,payoffMatrixes, payoffMatrix);
    % 少々雑
    payoffName = split(payoffCsvFile,".csv");
    payoffName = payoffName(1);
    payoffNames = [payoffNames, payoffName];
end
cd ..

mutationValue = 0.01;
% 更新幅
dt = 0.1;
maxCount = 2000;
stopThreshold = 0.00001;


mutationRates = ones(length(payoffMatrix));
nStragtegies = length(payoffMatrix);
for i = 1:nStragtegies
    for j = 1:nStragtegies
        if i == j
            mutationRates(i,j) = 1 - mutationValue;
        else
            mutationRates(i,j) = mutationValue/(nStragtegies-1);
        end
    end
end

tStart=tic;
for ip = 1:length(payoffMatrixes(1,1,:))
    payoffName = payoffNames(ip);
    payoffMatrix = payoffMatrixes(:,:,ip);
    rd = {
    @(populations) mutationRD1(payoffMatrix, populations, mutationRates);
    @(populations) mutationRD2(payoffMatrix, populations, mutationValue);
    @(populations) mutationRD3(payoffMatrix, populations, mutationRates);
    @(populations) mutationRD4(payoffMatrix, populations, mutationRates);
    @(populations) mutationRD5(payoffMatrix, populations, mutationValue);
    };
    for ir = 1:length(rd)
        populations = ones(length(payoffMatrix),1) ./ length(payoffMatrix);
        count = 0;
        i = 1;
        populationsHistories = zeros(length(populations)+1, maxCount);
        populationsHistories(:,i) = [count; populations];
        tic;
        for count = 0:dt:maxCount
            i = i+1;
            dx = rd{ir}(populations);
            populations = populations + (dx * dt);
            populationsHistories(:,i) = [count; populations];
            %if max(reshape(dx,1,[])) < stopThreshold || count > maxCount
        end
        toc;
        fileName = "rd"+ ir + "_" + payoffName +".csv";
        csvwrite(saveCsvsDir + fileName, populationsHistories.')
        
        figure;
        plot(populationsHistories(1,:).' , populationsHistories(2:end, : ).');
        ylim([0 1]);
        f = gcf;
        fileName =  "rd"+ ir + "_"  + payoffName + ".png";
        exportgraphics(f, saveImagesDir + fileName);
        
        disp(populations);
    end
end
toc(tStart);

% 強化学習のサーベイ論文
function dv = mutationRD1(payoffMatrix, populations, mutationRates)
    strategyAveragePayoffs = payoffMatrix * populations;
    populationAveragePayoff =  populations.' * strategyAveragePayoffs;
    dv = populations.*((strategyAveragePayoffs - populationAveragePayoff)) ...
        + sum(mutationRates .* (repmat(populations,1,length(populations))-repmat(populations.',length(populations), 1))).';  
end

% 新レプリーター
function dv = mutationRD2(payoffMatrix, populations, mutationValue)
    strategyAveragePayoffs = payoffMatrix * populations;
    populationAveragePayoff =  populations.' * strategyAveragePayoffs;
    dv = populations.*((strategyAveragePayoffs - populationAveragePayoff)) ...
        + mutationValue .* (repmat(1/length(populations), length(populations), 1) - populations);  
end

% 旧レプリーター
function dv = mutationRD3(payoffMatrix, populations, mutationRates)
    strategyAveragePayoffs = payoffMatrix  * populations;
    populationAveragePayoff =  populations.' * strategyAveragePayoffs;
    dv = sum(repmat(populations,1,length(populations)) .* repmat(strategyAveragePayoffs,1,length(strategyAveragePayoffs)) .* mutationRates).' - populations .* populationAveragePayoff;
end

% 旧レプリーター Johaness
function dv = mutationRD4(payoffMatrix, populations, mutationRates)
    strategyAveragePayoffs = payoffMatrix  * populations;
    newPopulation = sum(repmat(populations,1,length(populations)) .* repmat(strategyAveragePayoffs,1,length(strategyAveragePayoffs)) .* mutationRates).';
    dv = newPopulation/sum(newPopulation) -  populations;
end

% 新レプリーター Johaness
function dv = mutationRD5(payoffMatrix, populations, mutationValue)
    strategyAveragePayoffs = payoffMatrix * populations;
    newPopulation = populations.*strategyAveragePayoffs ...
        + mutationValue .* (repmat(1/length(populations), length(populations), 1) - populations);  
    dv = newPopulation/sum(newPopulation) -  populations;
end