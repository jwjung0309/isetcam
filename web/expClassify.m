% playground for experimenting with classification
%
% start with Googlenet, vgg, resnet, can use others.
% Note that they will error the first time, require an add-in to be
% downloaded. Link to the download appears in the script window, 
% or can be found using the add-in explorer

%%
net = resnet50; % vgg19; googlenet;

% user points us to the folder of previously downloaded images they want to
% test. They can get those using imgBrowser+Flickr+curating+save, or
% however ...

%%
inputFolder = uigetdir(fullfile(isetRootPath, "local", "images"), "Choose folder with the original images.");
%inputFolder = fullfile(isetRootPath,'local','images','dogs');
inputFiles = dir(fullfile(inputFolder,'*.jpg'));

outputOIFolder = fullfile(inputFolder,'opticalimage');
if ~exist(outputOIFolder,'dir'), mkdir(outputOIFolder); end

oi = oiCreate;

%% Make the optical images
wave = 400:10:700;

for ii = 1:numel(inputFiles)
    sceneFileName = fullfile(inputFiles(ii).folder, inputFiles(ii).name);
    ourScene = sceneFromFile(sceneFileName,'rgb',[],'reflectance-display',wave);
    [~,thisFileName,~] = fileparts(inputFiles(ii).name);
    ourScene = sceneSet(ourScene,'name',thisFileName);

    % we pre-compute the optical image so it can be cached for future
    oi = oiCompute(oi, ourScene);

    % Cropping principles:
    %   oiSize = sceneSize * (1 + 1/4))
    %   sceneSize = oiGet(oi,'size')/(1.25);
    %   [sceneSize(1)/8 sceneSize(2)/8 sceneSize(1) sceneSize(2)]
    %   rect = [row col height width]

    sz     = sceneGet(ourScene,'size');
    rect   = round([sz(2)/8 sz(1)/8 sz(2) sz(1)]);
    oi = oiCrop(oi,rect);
    % oiWindow(oiTest);
    
    save(fullfile(outputOIFolder,[oiGet(oi,'name'),'.mat']),'oi');
end

%%  Set sensor and ip parameters and create sample images with those parameters

sensor = sensorCreate;
sensor = sensorSetSizeToFOV(sensor,35,ourScene,oi);
ip     = ipCreate;
outputRGB = fullfile(inputFolder,'ip');
if ~exist(outputRGB,'dir'), mkdir(outputRGB); end

chdir(outputOIFolder);
oiList = dir(fullfile(outputOIFolder,'*.mat'));

for ii=1:numel(oiList)
    % oiRGB = oiGet(ourOI,'rgb image');
    % ieNewGraphWin; imagescRGB(oiRGB)
    load(oiList(ii).name,'oi');
    sensor = sensorCompute(sensor,oi);
    % sensorWindow(sensor);
    
    ip  = ipCompute(ip,sensor);
    rgb = ipGet(ip,'result');
    
    [fPath, fName, fExt] = fileparts(sceneFileName);
    ourOutputFileName = fullfile(outputRGB, sprintf('%s.jpg',oiGet(oi,'name')));
    imwrite(rgb,ourOutputFileName);
end

%%  Let's classify with the ResNet

ipFolder = fullfile(inputFolder,'ip');

inputSize = net.Layers(1).InputSize;

% We would want to run our classifier on the original folder
%  and the camera images and djinn up some comparison info, depending on
%  what we decide we want to use as a metric. Right now just runs on the
%  original image folder and prints out what it finds.

totalScore = 0;
for ii = 1:length(inputFiles)
    % Classify each of the original downloaded images
    ourGTFileName = fullfile(inputFiles(ii).folder, inputFiles(ii).name);
    ourGTImage = imread(ourGTFileName);
    ourGTImage = imresize(ourGTImage,inputSize(1:2));
    [label, scores] = classify(net,ourGTImage);
    disp(label)
    [~,idx] = sort(scores,'descend');
    idx = idx(1:5);
    classNamesGTTop = net.Layers(end).ClassNames(idx);
    scoresGTTop = scores(idx);
    
    % for now we just output the top classes for each image, but of
    % course would want to do something smart with them & scores
    disp(strcat("Classes for GT image: ", fullfile(inputFiles(ii).folder, inputFiles(ii).name)));
    disp(classNamesGTTop) % the top 5 possible classes
    
    % Classify using the simulated images, through the sensor
    ipFileName = fullfile(ipFolder, inputFiles(ii).name);
    
    ourTestImage = imread(ipFileName);
    ourTestImage = imresize(ourTestImage,inputSize(1:2));
    [label, scores] = classify(net,ourTestImage);
    disp(label)

    % The scores are worst to best when sorted this way?
    [~,idx] = sort(scores,'descend');
    idx = idx(1:5);
    classNamesTestTop = net.Layers(end).ClassNames(idx);
    scoresTestTop = scores(idx);
    
    % for now we just output the top classes for each image, but of
    % course would want to do something smart with them & scores
    disp(strcat("Classes for our Simulated Test image: ", ipFileName));
    disp(classNamesTestTop)% the top 5 possible classes
    
    imageScore = length(find(ismember(classNamesGTTop, classNamesTestTop)));
    totalScore = totalScore + imageScore;
    disp(strcat("Image Matching Score: ", string(imageScore)));
    
end

%%
disp(strcat("Total score for: ", string(length(inputFiles)), " images is: ", string(totalScore)));

%%