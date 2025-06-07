[audio, fs] = audioread('Highway sound sample 1.wav');
audio = mean(audio, 2); % Convert to mono

% Parameters
win_len = round(0.2 * fs);   % 200 ms window
hop = round(0.1 * fs);       % 50% overlap
n_frames = floor((length(audio) - win_len) / hop);

% Initialize
spectral_energy = zeros(1, n_frames);
dominant_freqs = zeros(1, n_frames);

% Spectral analysis per frame
for i = 1:n_frames
    idx = (i-1)*hop + (1:win_len);
    frame = audio(idx) .* hamming(win_len);
    
    Y = abs(fft(frame));
    Y = Y(1:floor(end/2));
    f = linspace(0, fs/2, length(Y));
    
    spectral_energy(i) = sum(Y.^2);
    [~, max_idx] = max(Y);
    dominant_freqs(i) = f(max_idx);
end

% Smooth energy and detect onsets
smoothed_energy = movmean(spectral_energy, 5);
threshold = 0.25 * max(smoothed_energy);
vehicle_frames = smoothed_energy > threshold;
onsets = find(diff([0 vehicle_frames]) == 1);
onset_times = (onsets * hop) / fs;

% Classification
vehicle_types = strings(1, length(onsets));
for j = 1:length(onsets)
    freq = dominant_freqs(onsets(j));
    if freq >= 1000
        vehicle_types(j) = "Bike";
    elseif freq >= 100 && freq < 1000
        vehicle_types(j) = "Car";
    elseif freq > 0 && freq < 100
        vehicle_types(j) = "Truck";
    else
        vehicle_types(j) = "Unknown";
    end
end

% Count types
num_bikes = sum(vehicle_types == "Bike");
num_cars = sum(vehicle_types == "Car");
num_trucks = sum(vehicle_types == "Truck");

% === PLOT 1: Spectral Energy with Color-Coded Vehicle Detections ===
% Separate arrays for plotting
bike_times = []; bike_vals = [];
car_times = []; car_vals = [];
truck_times = []; truck_vals = [];
unknown_times = []; unknown_vals = [];

for k = 1:length(onsets)
    t = onset_times(k);
    y = smoothed_energy(onsets(k));
    switch vehicle_types(k)
        case "Bike"
            bike_times(end+1) = t;
            bike_vals(end+1) = y;
        case "Car"
            car_times(end+1) = t;
            car_vals(end+1) = y;
        case "Truck"
            truck_times(end+1) = t;
            truck_vals(end+1) = y;
        otherwise
            unknown_times(end+1) = t;
            unknown_vals(end+1) = y;
    end
end

figure;
plot(((1:n_frames)*hop)/fs, smoothed_energy, 'k', 'DisplayName', 'Spectral Energy'); hold on;
yline(threshold, 'r--', 'DisplayName', 'Threshold');
plot(bike_times, bike_vals, 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'Bike');
plot(car_times, car_vals, 'bo', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', 'Car');
plot(truck_times, truck_vals, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 8, 'DisplayName', 'Truck');
plot(unknown_times, unknown_vals, 'ko', 'MarkerFaceColor', 'k', 'MarkerSize', 8, 'DisplayName', 'Unknown');

xlabel('Time (s)');
ylabel('Spectral Energy');
title(sprintf('Vehicle Detection and Classification\nCars: %d | Bikes: %d | Trucks: %d', ...
    num_cars, num_bikes, num_trucks));
legend('Location', 'northwest');
grid on;

% === PLOT 2: Dominant Frequency vs Time ===
figure;
hold on;
scatter(bike_times, dominant_freqs(onsets(vehicle_types == "Bike")), 60, 'r', 'filled', 'DisplayName', 'Bike');
scatter(car_times, dominant_freqs(onsets(vehicle_types == "Car")), 60, 'b', 'filled', 'DisplayName', 'Car');
scatter(truck_times, dominant_freqs(onsets(vehicle_types == "Truck")), 60, 'g', 'filled', 'DisplayName', 'Truck');
scatter(unknown_times, dominant_freqs(onsets(vehicle_types == "Unknown")), 60, 'k', 'filled', 'DisplayName', 'Unknown');

xlabel('Time (s)');
ylabel('Dominant Frequency (Hz)');
title('Dominant Frequency vs Time by Vehicle Type');
legend('Location', 'northeast');
grid on;

% === Display Table in Console ===
disp("Detected Vehicles:");
disp(table(onset_times', vehicle_types', 'VariableNames', {'Time_s', 'Type'}));
