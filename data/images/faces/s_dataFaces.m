%% s_dataFacesSpectral
%
% Illustrate how to download some of the spectral face data
%

ieWebGet('browse','pbrtv4');

theFile = ieWebGet('resource type','spectral','resource name','CaucasianMale');
scene = sceneFromFile(theFile,'spectral');
sceneWindow(scene);

% theFile = fullfile(ieRootPath,'local','scenes','spectral','CaucasianMale.mat');
theFile = ieWebGet('resource type','faces','resource name','LoResFemale6');
face = sceneFromFile(theFile,'spectral');
face = sceneSet(face,'wave',420:10:700);

sceneWindow(face);

%% How to scale the level of the light
theLight = sceneGet(face,'illuminant energy');
[r,c,~] = size(theLight);

lightScale = sum(theLight,3);
ieNewGraphWin; mesh(lightScale)


%%
[lightXW, row,col] = RGB2XWFormat(theLight);
spatialScale = sum(lightXW,2);
spectrum = mean(lightXW);
wave = sceneGet(face,'wave');
plotRadiance(wave,spectrum);

%% New light
d65 = ieReadSpectra('d65',wave);   % Energy
tmp = repmat(d65',row*col,1);
for ii=1:numel(spatialScale)
    tmp(ii,:) = spatialScale(ii)*tmp(ii,:);
end
newIll = XW2RGBFormat(tmp,r,c);

%%
theEnergy = sceneGet(face,'energy');

newEnergy = (theEnergy ./ theLight) .* newIll;
face = sceneSet(face,'energy',newEnergy);
face = sceneSet(face,'illuminant energy',newIll);
sceneWindow(face);

%% Nonuniform illumination case

% Using Zheng's methods from isetxyz

%  Create a mask
scene = sceneCreate;
sz = sceneGet(scene,'size');
wave = sceneGet(scene,'wave');

mask = scIlluminationMaskGenerate('mask size',sz,'n light',3);

%  Set up the illuminant functions
iBasis = ieReadSpectra('cieSampledDaylight',wave);
method = 'reallight';
nLights = 3;
lgts = sampleLight(method, nLights, wave, iBasis);

%  Apply them to the scene
scene2 = nonUniformIlluMix(scene, mask, 'illuminant basis',lgts);
sceneWindow(scene2);


