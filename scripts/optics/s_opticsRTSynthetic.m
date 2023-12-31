%% Ray trace optics model based on synthetic PSFs
%
% Illustrate a *ray trace* calculation uses space-varying and
% wavelength dependent point spread functions.  Sometimes these
% are generated by Zemax models, but they cal also be based on a
% synthetic ray trace data set.
%
% The synthetic point spreads generated here are bivariate
% normals that increase from center to periphery.
%
% See also: rtSynthetic
%
% (c) Imageval Consulting LLC, 2012

%%
ieInit

%% Create a test scene
scene = sceneCreate('point array',256);
% scene = sceneCreate('sweepfrequency',256); % An alternative

scene = sceneSet(scene,'h fov',3);
scene = sceneInterpolateW(scene,550:100:650);
ieAddObject(scene);
sceneWindow;

%% Build the optical image

oi = oiCreate('raytrace');
rtOptics = []; spreadLimits = [1 3]; xyRatio = 1.6;
rtOptics = rtSynthetic(oi,rtOptics,spreadLimits,xyRatio);
oi = oiSet(oi,'optics',rtOptics);
rtPSFVisualize(rtOptics);

%%
oi = oiCompute(oi,scene);
oi = oiSet(oi,'name','Synthetic-RT-Increasing-Gaussian');
oiWindow(oi);

%% Show the PSF
rtPlot(oi,'psf',550,0);
rtPlot(oi,'psf',550,1);

%%
