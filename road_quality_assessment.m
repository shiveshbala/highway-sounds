% Road Quality Estimation from Highway Audio (.wav)
clear;

%% Load .wav Audio File
[signal, fs] = audioread('Highway sound sample 1.wav');  % Replace with your .wav file
signal = signal(:,1);  % Use mono channel if stereo

% Normalize signal
signal = signal - mean(signal);
signal = signal / max(abs(signal));

t = (0:length(signal)-1)/fs;

% Filter to isolate low-frequency road noise
% Bandpass filter between 20 Hz and 300 Hz
filt = designfilt('bandpassiir','FilterOrder',6, ...
    'HalfPowerFrequency1',20,'HalfPowerFrequency2',300, ...
    'SampleRate',fs);
filteredSignal = filtfilt(filt, signal);

%% Analyze Vibration
rmsVal = rms(filteredSignal);
peakVal = max(abs(filteredSignal));
stdDev = std(filteredSignal);

%% Determine Road Quality
if rmsVal < 0.05 && peakVal < 0.2
    quality = 'Smooth Road';
elseif rmsVal < 0.1 && peakVal < 0.5
    quality = 'Moderate Road';
else
    quality = 'Rough Road';
end

%% Display Results
fprintf('--- Road Quality Report from Audio ---\n');
fprintf('RMS Value: %.3f\n', rmsVal);
fprintf('Peak Value: %.3f\n', peakVal);
fprintf('Standard Deviation: %.3f\n', stdDev);
fprintf('Estimated Road Quality: %s\n', quality);

%% Plot the Signal
figure;
plot(t, filteredSignal);
xlabel('Time (s)');
ylabel('Normalized Amplitude');
title(['Filtered Audio Signal - ' quality]);
grid on;
