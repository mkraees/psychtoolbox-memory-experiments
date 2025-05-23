function PerceptualVBLSyncTest(screen, stereomode, fullscreen, doublebuffer, maxduration, vblSync, testdualheadsync, useVulkan)
% PerceptualVBLSyncTest([screen=max][, stereomode=0][, fullscreen=1][, doublebuffer=1][, maxduration=10][, vblSync=1][, testdualheadsync=0][, useVulkan=0])
%
% Perceptual synchronization test for synchronization of Screen('Flip') and
% Screen('WaitBlanking') to the vertical retrace.
%
% Arguments:
% 'screen' Either a single screen handle, or none (in which case the
% display with the maximum id will be used), or a vector of two handles in
% stereomode 10, e.g., [0 1] if you want to output to screens 0 and 1. You
% can also pass a vector of two screens when stereomode is not set to 10.
% In this case two separate (non-stereo) onscreen windows will be opened on
% both displays and they will get flipped in multiflip mode 2. That means
% that the first display (first element of 'screen') is synced to VBL, but
% the 2nd one is synced to bufferswaps of the first one. This is a
% straightforward test to check if two displays of a stereosetup run with a
% synchronized retrace cycle (good!) or if they are phase-shifted or
% drifting against each other (not good!).
%
% 'stereomode' Which stereomode to use? Defaults to zero, ie. no stereo.
%
% 'fullscreen' Fullscreen presentation? Defaults to 1 ie. yes. In
% non-fullscreen mode, no proper synchronization of bufferswaps can be
% expected.
%
% 'doublebuffer' Single- or double-buffering (1). Defaults to 1. In single
% buffer mode there is no sync to retrace, so this is a good way to
% simulate the tearing artifacts that would happen on sync failure, just to
% get an impression.
%
% 'maxduration' Maximum runtime of test: Runs until keypress or maxduration
% seconds have elapsed (Default is 10 seconds).
%
% 'vblSync' If 1, synchronize bufferswaps to vertical retrace of monitor,
% otherwise (setting 0) swap immediately without sync, ie., usually with tearing.
%
% 'testdualheadsync' If non-zero, and 'vblSync' is zero, manually wait until the video
% scanout position reaches half the height of the display, then swap. If this
% is done on a multi-display setup and the video scanout cycles of all the
% participating displays are properly synchronized, you should see a "static"
% crack line roughly at half the height of the display, maybe a bit lower. If
% you see a wandering crack line, at least on some displays, or you see vertical
% offsets of the position of the crack line between displays, then the displays
% are not properly synchronized, ie., not suitable for artifact free binocular
% stimulation. Caveat: This logic has been developed and tested specifically
% for testing on Linux with a single X-Screen spanning multiple displays. It may
% or may not be suitable to assess other operating systems or display configurations.
%
% 'useVulkan' If 1, try to use a Vulkan display backend instead of the
% OpenGL display backend. See 'help PsychVulkan'.
%
% After starting this test, you should see a flickering greyish background
% that flickers in a homogenous way - without cracks or weird moving patterns
% in the flickering area. If you see an imhogenous flicker, this means that
% synchronization of stimulus onset to the vertical retrace doesn't work due
% to some serious bug or limitation of your graphics hardware or its driver.
% If you don't know what this means, you can test this script with parameter
% doublebuffer == 0 to artificially create a synchronization failure.
%
% On many systems you should also see some emerging pattern of yellow horizontal lines.
% These lines should be tightly concentrated/clustered in the topmost area of
% the screen. Lots of yellow lines in the middle or bottom area or even
% randomly distributed lines indicate some bug in the driver of your graphics
% hardware. This is a common problem of all ATI graphics adapters on MacOS-X
% versions earlier than OS-X 10.4.3 when running a dual-display setup...
%
% A second reason for distributed yellow lines could be bad timing on your
% machine, e.g., due to background activity by virus scanners or the Spotlight
% indexing service on OS-X. Turn these off for conducting your studies!
%

% History:
% 01/28/06 mk Written. Replaces the built-in flickertest of Screen('OpenWindow')
%             on multi-display setups. That test wasn't well received :(

% Check for presence of OpenGL PTB.
AssertOpenGL;

if nargin < 4
    doublebuffer = [];
end

if isempty(doublebuffer)
   % Use double-buffered windows by default: Single-buffered ones can't sync to
   % retrace and are discouraged anyway. Setting doublebuffer=0 is an easy way
   % to reproduce the visual pattern created by a complete sync-failure though.
   doublebuffer=1;
end
doublebuffer=doublebuffer+1;

if nargin < 2
    stereomode = [];
end

if isempty(stereomode)
   % Use non-stereo display by default.
   stereomode=0;
end

if nargin < 3
    fullscreen = [];
end

if isempty(fullscreen)
   fullscreen=1;
end

if nargin < 1
    screen = [];
end

if isempty(screen)
    if stereomode == 10
        screen(1) = max(Screen('Screens')) - 1;
        screen(2) = max(Screen('Screens'));
        if screen(1)<0
            error('Stereomode 10 only works on setups with two attached displays!');
        end
    else
        screen=max(Screen('Screens'));
    end
end

if nargin < 5
    maxduration = [];
end

if isempty(maxduration)
    maxduration = 10;
end

if nargin < 6
    vblSync = [];
end

if isempty(vblSync)
    vblSync = 1;
end

if nargin < 7
    testdualheadsync = [];
end

if isempty(testdualheadsync)
    testdualheadsync = 0;
end

if nargin < 8 || isempty(useVulkan)
    useVulkan = 0;
end

thickness = (1-vblSync) * 4 + 1;

try
    if fullscreen
        rect1=[];
        rect2=[];
    else
        rect1=InsetRect(Screen('GlobalRect', screen(1)), 1, 0);
        if length(screen)>1
            rect2=InsetRect(Screen('GlobalRect', screen(2)), 1, 0);
        end
    end

   if stereomode~=10
       % Standard case:
       PsychImaging('PrepareConfiguration');
       PsychImaging('AddTask', 'General', 'UseRetinaResolution');

       if useVulkan
           PsychImaging('AddTask', 'General', 'UseVulkanDisplay');
       end

       [win , winRect]=PsychImaging('OpenWindow', screen(1), 0, rect1, [], doublebuffer, stereomode);
       if length(screen)>1
           PsychImaging('PrepareConfiguration');
           PsychImaging('AddTask', 'General', 'UseRetinaResolution');
           if useVulkan
               PsychImaging('AddTask', 'General', 'UseVulkanDisplay');
           end
           win2 = PsychImaging('OpenWindow', screen(2), 0, rect2, [], doublebuffer, stereomode);
       end
   else
       % Special case for dual-window stereo:

       % Setup master window:
       [win , winRect]=Screen('OpenWindow', screen(1), 0, rect1, [], doublebuffer, stereomode);
       % Setup slave window:
       Screen('OpenWindow', screen(2), 0, rect2, [], doublebuffer, stereomode);
   end

   % The display engines of some 64-Bit ARM platforms do not yet have hardware cursor
   % support, so hide the cursor on those, to avoid software cursor rendering from
   % messing up the display timing for this test script:
   if IsARM && Is64Bit
       HideCursor(win);
   end

   flickerRect = InsetRect(winRect, 100, 0);
   color = 0;
   deadline = GetSecs + maxduration;
   beampos=0;

   ifi = Screen('GetFlipInterval', win);
   winfo = Screen('GetWindowInfo', win);

   % Normally we do not do anything after flip, as a performance optimization:
   dontclear = 2;
   if ~isempty(strfind(winfo.GPUCoreId, 'VC4'))
      % Unless we are on the RaspberryPi with its Broadcom VideoCore gpu,
      % where we do a full clear to background color after each Flip. Why?
      % Because it turns out this gives much better performance! E.g., we can
      % almost do 120 fps stable on a RPi 400 / VideoCore-6 at 1920x1080,
      % whereas without clear we can only do about 60 fps. Not sure why this
      % is, but it could be either a VideoCore 6+ thing do to the use of separate
      % 3D render engine and display engine, and the need to do some buffer
      % passing, with a possible detiling blit, or it could be related to the VideoCore
      % gpu being a tiled renderer. In either case, it might be more efficient to
      % completely invalidate / discard backbuffers, and the driver may get its
      % hint from a full framebuffer clear to trigger this optimization.
      % TODO: Other tiled renderers or split gpu + display engine hardware might
      % benefit from this as well, especially on low powered mobile SoC devices?
      dontclear = 0;
   end

   VBLTimestamp = Screen('Flip', win, 0, 2);

   while ~KbCheck && (GetSecs < deadline)
      % Draw alternating black/white rectangle to left eye view or mono view:
      Screen('FillRect', win, color, flickerRect);

      % If beamposition is available, visualize it via yellow horizontal line:
      if (beampos>=0), Screen('DrawLine', win, [255 255 0], 0, beampos, winRect(3), beampos, thickness); end

      if stereomode > 0
         % Same for right-eye view...
         Screen('SelectStereoDrawBuffer', win, 1);
         Screen('FillRect', win, color, flickerRect);

         if (beampos>=0), Screen('DrawLine', win, [255 255 0], 0, beampos, winRect(3), beampos, thickness); end

         % Back to right eye for next loop iteration:
         Screen('SelectStereoDrawBuffer', win, 0);
      end

      if stereomode == 0 && length(screen)>1
          Screen('FillRect', win2, color, flickerRect);
          Screen('DrawingFinished', win2, 0, 2);
          Screen('DrawingFinished', win, 0, 2);
          multiflip = 0;
      else
          multiflip = 0;
      end

      % Alternate drawing color from white -> black, or black -> white
      color=255 - color;

      if doublebuffer>1
          if vblSync
              % Flip buffer on next vertical retrace, query rasterbeam position on flip, if available:
              [VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, beampos] = Screen('Flip', win, VBLTimestamp + ifi/2, dontclear, [], multiflip); %#ok<ASGLU>
              if exist('win2', 'var')
                [VBLTimestamp, StimulusOnsetTime, FlipTimestamp, Missed, beampos] = Screen('Flip', win2, VBLTimestamp + ifi/2, dontclear, [], multiflip); %#ok<ASGLU>
              end
          else
              % BeampositionQueries based wait until target "tear-flip" position:
              if testdualheadsync == 1 && winfo.VBLEndline ~= -1
                  Screen('DrawingFinished', win, 0, 1);
                  beampos = -1000;
                  while abs(beampos - winRect(4)/2) > 5
                      beampos = Screen('GetWindowInfo', win, 1);
                  end
              end

              % VBLTimestamp based wait until target "tear-flip" position:
              if testdualheadsync == 1 && winfo.VBLEndline == -1
                  Screen('DrawingFinished', win, 0, 1);
                  winfo = Screen('GetWindowInfo', win);
                  WaitSecs('UntilTime', winfo.LastVBLTime + ifi / 2);
              end

              % Flip immediately without sync to vertical retrace, do clear
              % backbuffer after flip for visualization purpose:
              VBLTimestamp = Screen('Flip', win, VBLTimestamp + ifi/2, 0, 2, multiflip);
              % Above flip won't return a 'beampos' in non-VSYNC'ed mode,
              % so we query it manually:
              beampos = Screen('GetWindowInfo', win, 1);

              % Throttle a little bit for visualization purpose:
              WaitSecs('YieldSecs', 0.005);
          end
      else
          % Just wait a bit in non-buffered case:
          pause(0.001);
      end
   end

   Screen('CloseAll');
   return;
catch
   Screen('CloseAll');
end
