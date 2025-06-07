[audio, fs] = audioread('Highway sound sample 1.wav');
audio = mean(audio, 2); %  converts stereo to mono audio

% Parameters
win_len = round(0.2 * fs);  % 200 ms window
hop = round(0.1 * fs);      % 50% overlap
n_frames = floor((length(audio) - win_len) / hop);

% Initialize
spectral_energy = zeros(1, n_frames);
dominant_freqs = zeros(1, n_frames);

% Loop over frames
for i = 1:n_frames
    idx = (i-1)*hop + (1:win_len);
    frame = audio(idx) .* hamming(win_len); % windowing

    % FFT
    Y = abs(fft(frame));
    Y = Y(1:floor(end/2)); % single-sided spectrum
    f = linspace(0, fs/2, length(Y));

    % Spectral energy and dominant freq
    spectral_energy(i) = sum(Y.^2);
    [~, max_idx] = max(Y);
    dominant_freqs(i) = f(max_idx);
end

% Smooth and threshold spectral energy
smoothed_energy = movmean(spectral_energy, 5);
threshold = 0.26* max(smoothed_energy);
vehicle_frames = smoothed_energy > threshold;
onsets = find(diff([0 vehicle_frames]) == 1);
vehicle_count = length(onsets);

% Time axis
t = ((1:n_frames) * hop) / fs;
onset_times = (onsets * hop) / fs;

% Plot spectral energy
figure;
plot(t, smoothed_energy, 'b'); hold on;
yline(threshold, 'r--', 'Threshold');
plot(onset_times, smoothed_energy(onsets), 'ro', 'MarkerFaceColor', 'r');
xlabel('Time (s)'); ylabel('Spectral Energy');
title(['Vehicle Detection via FFT - Count: ', num2str(vehicle_count)]);
legend('Spectral Energy', 'Threshold', 'Detected Vehicles');
grid on;
