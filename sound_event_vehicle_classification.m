%% MATLAB Script for Analyzing a .wav File: Vehicle Detection & Classification
% This script loads a .wav file (e.g., a highway recording), segments events
% based on energy, and then classifies each event as a Truck, Car, or Motorbike 
% by averaging the dominant frequency over the event segment.
%
% Instructions:
% 1. Place your .wav file in the MATLAB working folder.
% 2. Adjust parameters (frame length, threshold factor, and frequency boundaries)
%    if needed.
% 3. Run the script to see the plotted energy profile and event statistics.

%% 1. Load the Audio File
[fileName, filePath] = uigetfile('*.wav', 'Select your highway .wav file');
if isequal(fileName, 0)
    error('No file selected. Please select a .wav file.');
end
fullFileName = fullfile(filePath, fileName);
[audio, fs] = audioread(fullFileName);
fprintf('Analyzing file: %s\n', fullFileName);

% If stereo, convert to mono by averaging channels
if size(audio,2) > 1
    audio = mean(audio, 2);
end

%% 2. Plot the Time-Domain Waveform
t_audio = (0:length(audio)-1) / fs;
figure;
plot(t_audio, audio);
xlabel('Time (s)'); ylabel('Amplitude');
title('Audio Waveform');
grid on;

%% 3. Framing & Feature Extraction
% Set parameters for frame-based processing
win_len = round(0.2 * fs);  % 200 ms window
hop = round(0.1 * fs);      % 50% overlap gives a hop of 200ms*0.5 = 100 ms
n_frames = floor((length(audio) - win_len) / hop);

% Preallocate for speed
spectral_energy = zeros(1, n_frames);
dominant_freqs = zeros(1, n_frames);

% Process each frame: apply window, compute FFT, then spectral features
for i = 1:n_frames
    idx = (i-1)*hop + (1:win_len);
    frame = audio(idx) .* hamming(win_len); % Windowing the frame
    
    % FFT and single-sided spectrum calculation
    Y = abs(fft(frame));
    Y = Y(1:floor(end/2));  % Keep only positive frequencies
    f = linspace(0, fs/2, length(Y));
    
    % Spectral energy and dominant frequency for the frame
    spectral_energy(i) = sum(Y.^2);
    [~, max_idx] = max(Y);
    dominant_freqs(i) = f(max_idx);
end

%% 4. Dynamic Event Detection
% Smooth the spectral energy for stable detection
smoothed_energy = movmean(spectral_energy, 5);

% Set a dynamic threshold – here 50% of the maximum smoothed energy.
threshold = 0.5 * max(smoothed_energy);

% Create a binary mask where energy exceeds the threshold
vehicle_mask = smoothed_energy > threshold;

% Group contiguous frames into events by detecting rising and falling edges.
padded_mask = [0, vehicle_mask, 0];
mask_diff = diff(padded_mask);
event_start_frames = find(mask_diff == 1);
event_end_frames   = find(mask_diff == -1) - 1;
n_events = numel(event_start_frames);

fprintf('Detected %d event segments based on energy thresholding.\n', n_events);

%% 5. Vehicle Classification Using Averaged Dominant Frequency
% Define classification frequency boundaries (tune these as needed)
truck_max_freq   = 300;   % below 300 Hz: Truck
car_max_freq     = 1000;   % 300 Hz to 500 Hz: Car
% Above 500 Hz, classify as Motorbike

% Preallocate storage for classification results
vehicle_types = cell(n_events, 1);
event_avg_freq = zeros(n_events, 1);
event_times    = zeros(n_events, 1);

% Loop over each detected event and classify
for i = 1:n_events
    frames = event_start_frames(i) : event_end_frames(i);
    
    % Compute the event's average dominant frequency
    avg_dom_freq = mean(dominant_freqs(frames));
    event_avg_freq(i) = avg_dom_freq;
    
    % Use the average frequency for classification
    if avg_dom_freq < truck_max_freq
        vehicle_types{i} = 'Truck';
    elseif avg_dom_freq < car_max_freq
        vehicle_types{i} = 'Car';
    else
        vehicle_types{i} = 'Motorbike';
    end
    
    % Estimate event time for display based on the mean frame index.
    mean_frame = mean(frames);
    event_times(i) = (mean_frame * hop) / fs;
    
    % Display event details
    fprintf('Event %d at %.2f sec: Avg. Dominant Frequency = %.2f Hz -> %s\n', ...
        i, event_times(i), avg_dom_freq, vehicle_types{i});
end

%% 6. Plot the Detection Results
t_frames = ((1:n_frames) * hop) / fs;
figure;
plot(t_frames, smoothed_energy, 'b', 'LineWidth', 1.5); hold on;
yline(threshold, 'r--', 'Threshold', 'LineWidth', 2);
% Mark the center of each event on the plot
plot(event_times, smoothed_energy(round(mean([event_start_frames; event_end_frames]))), ...
    'ko', 'MarkerFaceColor', 'g', 'MarkerSize', 8);
xlabel('Time (s)'); ylabel('Smoothed Spectral Energy');
title(['Detected Events & Vehicle Classification in ', fileName]);
legend('Smoothed Energy','Threshold','Detected Event Centers');
grid on;

%% 7. Summary of Detected Vehicles
truckCount    = sum(strcmp(vehicle_types, 'Truck'));
carCount      = sum(strcmp(vehicle_types, 'Car'));
motorbikeCount = sum(strcmp(vehicle_types, 'Motorbike'));

fprintf('\nSummary:\n');
fprintf('Total Events Detected: %d\n', n_events);
fprintf('Trucks: %d\n', truckCount);
fprintf('Cars: %d\n', carCount);
fprintf('Motorbikes: %d\n', motorbikeCount);
