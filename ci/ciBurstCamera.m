classdef ciBurstCamera < ciCamera
    %CIBURSTCAMERA Sub-class of ciCamera that adds burst and bracketing
    %   Basic multi-capture functionality, to be used for testing
    %   and as a base class for additional enhancements
    
    % History:
    %   Initial Version: D.Cardinal 12/2020

    properties
    end
    
    methods
        function obj = ciBurstCamera()
            %CIBURSTCAMERA Construct an instance of this class
            %   First invoke our parent ciCamera class
            obj = obj@ciCamera();

        end
        
       function ourPicture = TakePicture(obj, aCIScene, intent, options)
           
           arguments
               obj;
               aCIScene;
               intent;
               options.numHDRFrames = 3;
               options.numBurstFrames = 3;
               options.imageName char = '';
               options.reRender (1,1) {islogical} = true;
           end
           if ~isempty(options.imageName)
               obj.isp.ip = ipSet(obj.isp.ip, 'name', options.imageName);
           end
           obj.numHDRFrames = options.numHDRFrames;
           obj.numBurstFrames = options.numBurstFrames;
           
           ourPicture = TakePicture@ciCamera(obj, aCIScene, intent, 'reRender', options.reRender);
           
       end
       
       % Decides on number of frames and their exposure times
       % based on the preview image passed in from the camera module
       function [expTimes] = planCaptures(obj, previewImages, intent)

           % by default set our base exposure to simple auto-exposure
           oi = oiCompute(previewImages{1},obj.cmodule.oi);
           baseExposure = [autoExposure(oi, obj.cmodule.sensor)];

          
           switch intent
               case 'HDR'
                   % Bracket the requested number of frames around our base
                   % exposure. TBD might be an AutoHDR based on overall
                   % scene dynamic range.
                   numFrames = obj.numHDRFrames;
                   frameOffset = (numFrames -1) / 2;
                   if numFrames > 1 && ~isodd(numFrames)
                       numFrames = numFrames + 1;
                   end
                   expTimes = repmat(baseExposure, 1, numFrames);
                   expTimes = expTimes.*(2.^[-1*frameOffset:1:frameOffset]);
               case 'Burst'
                   % For now this is a very simple algorithm that just
                   % takes the base exposure and divides it into the number
                   % of frames.
                   numFrames = obj.numBurstFrames;
                   frameOffset = (numFrames -1) / 2;
                   if numFrames > 1 && ~isodd(numFrames)
                       numFrames = numFrames + 1;
                   end
                   % Future: Algorithm here to calculate number of images and
                   % exposure time based on estimated processing power,
                   % lighting, and possibly motion/intent
                   expTimes = repmat(baseExposure/numFrames, 1, numFrames);
                   
               otherwise
                   % just do what the base camera class would do
                   [expTimes] = planCaptures@ciCamera(obj, previewImages, intent);
           end
       end
       
       % Here we over-ride default processing to compute a photo after we've
       % captured one or more frames. This allows burst & hdr, for example:
       function ourPhoto = computePhoto(obj, sensorImages, intent)

           switch intent
               case 'HDR'
                   % ipCompute for HDR assumes we have an array of voltages
                   % in a single sensor, NOT an array of sensors
                   % so first we merge our sensor array into one sensor
                   % For now this is simply concatenating, but could be
                   % more complex in a sub-class that wanted to be more
                   % clever
                   sensorImage = obj.isp.mergeSensors(sensorImages);
                   sensorImage = sensorSet(sensorImage,'exposure method', 'bracketing');
 
% what if we don't bother limiting to demosaic?
                   ipHDR = ipSet(obj.isp.ip, 'render demosaic only', 'true');
                   ipHDR = ipSet(obj.isp.ip, 'combination method', 'longest');
                   
                   ipHDR = ipCompute(ipHDR, sensorImage);
                   ourPhoto = ipHDR;
               case 'Burst'
                   % baseline is just sum the voltages
                   sensorImage = obj.isp.mergeSensors(sensorImages);
                   sensorImage = sensorSet(sensorImage,'exposure method', 'burst');

                   ipBurst = ipSet(obj.isp.ip, 'render demosaic only', 'true');
                   ipBurst = ipSet(ipBurst, 'combination method', 'sum');
                   
                   % old ipBurstMotion  = ipCompute(ipBurstMotion,sensorBurstMotion);
                   ipBurst = ipCompute(ipBurst, sensorImage);
                   ourPhoto = ipBurst;
               otherwise
                   ourPhoto = computePhoto@ciCamera(obj, sensorImages, intent);
           end
           %{
           % generic base code
           for ii=1:numel(sensorImages)
               sensorWindow(sensorImages(ii));
               ourPhoto = obj.isp.compute(sensorImages(ii));
               ipWindow(ourPhoto);
           end
           %}
           
       end
    end
end

