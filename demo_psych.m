% Initialize Psychtoolbox
clear; close all; clc;
Screen('Preference', 'SkipSyncTests', 1); % Skip sync tests for testing
PsychDefaultSetup(2);


try
    % Open the screen
    [win, rect] = PsychImaging('OpenWindow', 0, [255 255 255]); % Black screen
    [xCenter, yCenter] = RectCenter(rect); % Get center of the screen
    
    % Timing durations in seconds
    whiteScreenTime = 0; % 100ms
    fixationTime = 0.2; % 100ms
    numTrials = 10; % Number of trials
    imgDisplayTime = 1.0; % Duration to display the image (customize as needed)
    
    % Load images
    imgFolder = 'stimuli'; % Replace with your folder path
    imgFiles = dir(fullfile(imgFolder, '*.jpg')); % Assuming images are in .jpg format
    if length(imgFiles) < 10
        error('Not enough images in the folder. Ensure there are at least 10 images.');
    end
    
    % Shuffle the image order
    imgOrder = randperm(length(imgFiles), 10); % Randomly pick 10 images
    imgTextures = cell(1, length(imgOrder));
    for i = 1:length(imgOrder)
        imgPath = fullfile(imgFolder, imgFiles(imgOrder(i)).name);
        img = imread(imgPath);
        imgTextures{i} = Screen('MakeTexture', win, img);
    end
    
    % Main task loop
    for trial = 1:numTrials
        % White screen
        Screen('FillRect', win, [255 255 255]); % White color
        Screen('Flip', win);
        WaitSecs(whiteScreenTime);

        % Fixation cross
        Screen('FillRect', win, [255 255 255]); % Black background
        crossSize = 20; % Size of the fixation cross
        Screen('DrawLine', win, [255 255 255], xCenter - crossSize, yCenter, xCenter + crossSize, yCenter, 2);
        Screen('DrawLine', win, [255 255 255], xCenter, yCenter - crossSize, xCenter, yCenter + crossSize, 2);
        Screen('Flip', win);
        WaitSecs(fixationTime);

        % Display the image
        Screen('DrawTexture', win, imgTextures{trial});
        Screen('Flip', win);
        WaitSecs(imgDisplayTime);
    end

    % Close screen and cleanup
    Screen('CloseAll');
catch ME
    Screen('CloseAll');
    rethrow(ME);
end