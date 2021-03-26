clear; close all

%% Wavelength range of the IMEC sensor
wl=(460:620)';

%% Load actual imec calibration file
sensorname='CMV2K-SSM4x4-470_620-9.4.6.8'
filterqe = load(fullfile('calibrationfiles_imec',[sensorname '.mat'])); filterqe=filterqe.filterqe;
wl_calibration=400:1000;

%% Generate file for ISET
data = interp1(wl_calibration,filterqe,wl)
comment = 'multispectral filters from imec file generated by generateImecQEfile.m'
% filterNames= arrayfun(@num2str, 1:numel(cwl), 'UniformOutput', false);

filterNames{1}='';
for i=1:size(data,2)
    cwl=wl(find(data(:,i)==max(data(:,i))))
    filterNames{i}= ['k-' num2str(cwl)]
end

inData.wavelength = wl;
inData.data = data;
inData.filterNames = filterNames;
inData.comment = comment;
fname = fullfile(isetRootPath,'data','sensor','imec','qecurves',['imec-' sensorname '.mat'])
ieSaveColorFilter(inData, fname);
% save('multispectral.mat','wavelength','data','comment','filterNames')

%%
theseFilters = ieReadColorFilter(wl,fname);
ieNewGraphWin;
plot(wl,theseFilters);