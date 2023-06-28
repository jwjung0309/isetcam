%%  Experiments with flare
% 
% See also v_wvf which might be moved here or renamed v_wvfFlare
%

%%
ieInit;

%% Create some optics with a little defocus and astigmatism

wvf = wvfCreate;    % Default wavefront 5.67 fnumber

% Now create some flare based on the aperture, dust and scratches.
% There are many parameters for this function, including dot mean, line
% mean, dot sd, line sd, line opacity.  They are returned in params
nsides = 3;
pupilAmp = wvfPupilAmplitude(wvf,'nsides',nsides,...
    'dot mean',20, 'dot sd',3, 'dot opacity',0.5, ...
    'line mean',20, 'line sd', 2, 'line opacity',0.5);

wvf = wvfPupilFunction(wvf,'amplitude',pupilAmp);
wvf = wvfComputePSF(wvf,'force',false);  % force as false is important
wvfPlot(wvf,'psf','um',550,20,'airy disk');

%{
ieNewGraphWin([], 'wide');
subplot(1,3,1); wvfPlot(wvf,'image pupil amp','um',550,'no window');
subplot(1,3,2); wvfPlot(wvf,'image pupil phase','um',550,'no window');
subplot(1,3,3); wvfPlot(wvf,'image wavefront aberrations','um',550,'no window');
%}

%% Illustrate with a point array

scenePoint = sceneCreate('point array',384,128);
scenePoint = sceneSet(scenePoint,'fov',1);

oi = oiCompute(wvf,scenePoint);

oi = oiSet(oi,'name',sprintf('wvf-%d',nsides));
oi = oiCrop(oi,'border');
oiWindow(oi); 
oiSet(oi,'gamma',0.5); drawnow;

%% Show the oi PSF
oiPlot(oi,'psf550');
set(gca,'xlim',[-20 20],'ylim',[-20 20]);

%%  There is a lot of similarity in the PSF, but the spatial scale is not the same

[oiApply, pMask, psf] = piFlareApply(scenePoint,'num sides aperture',nsides, ...
    'focal length',wvfGet(wvf,'focal length','m'), ...
    'fnumber',wvfGet(wvf,'fnumber'));
ieNewGraphWin; mesh(getMiddleMatrix(psf(:,:,15),[120,120]));

% And the effects are therefore quite different.
oiApply = oiSet(oiApply,'name','flare');
oiWindow(oiApply);
oiSet(oiApply,'gamma',0.5); drawnow;

%% HDR Test scene. Green repeating circles

sceneHDR = sceneCreate('hdr');
sceneHDR = sceneSet(sceneHDR,'fov',3);
% sceneWindow(sceneHDR);

oi = oiCompute(wvf,sceneHDR);
oi = oiSet(oi,'name','wvf');
oiWindow(oi);
oiSet(oi,'render flag','hdr');
oiSet(oi,'gamma',1); drawnow;

%%
oi = oiCompute(oiApply,sceneHDR);
oi = oiCrop(oi,'border');
oi = oiSet(oi,'name','flare');
oiWindow(oi);
oiSet(oi,'render flag','hdr');
oiSet(oi,'gamma',1); drawnow;

%% Change the number of sides
nsides = 5;
[pupilAmp, params] = wvfPupilAmplitude(wvf,'nsides',nsides,...
    'dot mean',20, 'dot sd',3, 'dot opacity',0.5, ...
    'line mean',20, 'line sd', 2, 'line opacity',0.5);

wvf = wvfPupilFunction(wvf,'amplitude',pupilAmp);
wvf = wvfComputePSF(wvf,'force',false);  % force as false is important
wvfPlot(wvf,'psf','um',550,20,'airy disk');
scenePoint = sceneSet(scenePoint,'fov',1);
oi = oiCompute(wvf,scenePoint);
oi = oiSet(oi,'name',sprintf('wvf-%d',nsides));
oi = oiCrop(oi,'border');
oiWindow(oi); 
oiSet(oi,'render flag','hdr'); drawnow;

%% 
oi = oiCompute(wvf,sceneHDR);
oi = oiCrop(oi,'border');
oiWindow(oi); 

%% Add some blur
wvf = wvfSet(wvf,'zcoeffs',1.5,{'defocus'});

% Now create some flare based on the aperture, dust and scratches.
% There are many parameters for this function, including dot mean, line
% mean, dot sd, line sd, line opacity.  They are returned in params
nsides = 3;
[pupilAmp, params] = wvfPupilAmplitude(wvf,'nsides',nsides,...
    'dot mean',20, 'dot sd',3, 'dot opacity',0.5, ...
    'line mean',20, 'line sd', 2, 'line opacity',0.5);

wvf = wvfPupilFunction(wvf,'amplitude',pupilAmp);
wvf = wvfComputePSF(wvf,'force',false);  % force as false is important
wvfPlot(wvf,'psf','um',550,20,'airy disk');

oi = oiCompute(wvf,sceneHDR);
oi = oiSet(oi,'name','wvf');
oiWindow(oi);
oiSet(oi,'render flag','hdr');
oiSet(oi,'gamma',1); drawnow;

%% Now attend to longitudinal chromatic aberration

%% END