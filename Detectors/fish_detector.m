
clear
close

% videoLabeler('.\Video\IMG_6791.mov')

available_gtruths = dir('.\gTruths');
ntruths = size(available_gtruths, 1);
labelData_array = [];
dataSource_array = [];

for ntruth = 1:ntruths-2
    load(horzcat('.\gTruths\gTruth', num2str(ntruth), '.mat'))
    dataSource_array=[dataSource_array; gTruth.DataSource.Source];
    labelData_array=[labelData_array; gTruth.LabelData];    
end

PhotoshootsDirs=["dir1", "dir2", "dir3"];

LoadData = load(fullfile(LabelingDir,PhotoshootsDirs(1),'gTruth.mat'));
gTruth = LoadData.gTruth;
dataSource_array = gTruth.DataSource.Source;
LabelData_array=gTruth.LabelData;
LabelDefinitions=gTruth.LabelDefinitions;
for i=2:length(PhotoshootsDirs)
    LoadData=load(fullfile(LabelingDir,PhotoshootsDirs(i),'gTruth.mat'));
    gTruth=LoadData.gTruth;
    dataSource_array=[dataSource_array;gTruth.DataSource.Source];
    LabelData_array=[LabelData_array;gTruth.LabelData];
end
gtSource=groundTruthDataSource(dataSource_array);
gTruth=groundTruth(gtSource,LabelDefinitions,LabelData_array);