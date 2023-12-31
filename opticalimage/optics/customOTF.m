function [OTF2D, fSupport] = customOTF(oi,fSupport,wavelength,units)
%Interpolate optics OTF for shift-invariant calculation in optical image
%
% Brief
%  This routine returns appropriate spectral OTF given the spatial
%  sampling in the optical image.
%
% Synopsis
%  [OTF2D,fSupport] = customOTF(oi,[fSupport],[wavelength = :],[units='mm'])
%
% Input
%  oi         - Optical image
%  fSupport   - Frequency support required for the samples in the
%               optical image (default: oiGet(oi,'fSupport',units);
%  wavelength - Wavelengths (nm) used for the spectral OTF (default:
%               oiGet(oi,'wavelength')
%  units      - 'mm','m','um','deg'  (default:  'mm')
%
% Output
%   OTF2D     - Spectral 2D OTF
%   fSupport  - See above
%
% Description
%  In the shift-invariant optics model, custom data are stored in the
%  optics.OTF slot.  This routine reads the otf data and interpolates
%  them to the fSupport and wavelength of the optical image or optics
%  structure.
%
%  The returned OTF is normalized so that all energy is transmitted
%  (i.e., the DC value is 1).  This is done by normalizing the peak
%  value to one. If we ever have a case when the peak is other than
%  the DC, we have a problem with energy conservation - where did the
%  photons go?
%
%  The default units for the frequency support are cycles/millimeters.
%
%  TODO:  We can accept fSupport in
%  various units. But we can also set 'units'.  It is possible that
%  the user sends in fSupport in, say, cyc/deg and sends in units as
%  'mm'.  The case we do not want is fSupport is in cyc/deg and units
%  is in mm.
%
% See also:
%   oiCalculateOTF, dlCore.m
%
% Copyright ImagEval Consultants, LLC, 2003.

if ieNotDefined('oi'),         error('Optical image required.'); end
if ieNotDefined('wavelength'), wavelength = oiGet(oi,'wavelength'); end

% If the user sent in fSupport, they have to deal with units.  If they
% did not, they might have sent in units, in which case we retrieve
% the fSupport with the units they sent in.
if ieNotDefined('fSupport')
    if ieNotDefined('units'),      units = 'mm'; end
    fSupport = oiGet(oi,'fSupport',units); 
end

fx    = fSupport(:,:,1); fy = fSupport(:,:,2);
nX    = size(fx,2);      nY = size(fy,1);
nWave = length(wavelength);

optics     = oiGet(oi,'optics');

% The OTF default units are cycles per millimeter.  But we can use
% other units if specified by the user.
otfSupport = opticsGet(optics,'otfSupport',units);
[X,Y]      = meshgrid(otfSupport.fy,otfSupport.fx);

% Find the OTF at each wavelength. This may require interpolating the
% Stored data.
if length(wavelength) == 1

    OTF2D = opticsGet(optics,'otfData',wavelength);
    % figure(1); mesh(X,Y,OTF2D);
    % figure(1); mesh(X,Y,abs(OTF2D))
    
    % We interpolate the stored OTF2D onto the support grid for the
    % optical image.
    %
    % The OTF2D representation stores DC is in (1,1). So we would want
    % the fSupport to run from 1:N. The otfSupport that we use to
    % create X and Y, runs from -N:N. To make things match up, we
    % apply an fftshift to the OTF2D data prior to interpolating to
    % the spatial frequencies, fx and fy, that are required given the
    % spatial sampling of the optical image.
    %
    OTF2D    = ifftshift(interp2(X, Y, fftshift(OTF2D), fx, fy, 'linear',0));
    
else
    % Same as above, but wavelength by wavelength
    OTF2D = zeros(nY,nX,nWave);
    for ii=1:length(wavelength)
        tmp = opticsGet(optics,'otfData',wavelength(ii));
        OTF2D(:,:,ii) = ...
            fftshift(interp2(X, Y, fftshift(tmp), fx, fy, 'linear',0));
    end
end

end
