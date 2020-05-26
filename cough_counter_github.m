% Refined script for counting coughs
% Written by Paul Leamy
% Date: 10MAR2020

clc; close all; clear all

% Algorithm development
% 1. Cough counter basic
% Using just the V matrix (right singular values), identify the peaks, in
% the most leptokurtotic distribution, modulate time domain signal
% appropriately.

% Paper notes:
% Directory of signals - quiet_room2
% -------------------
% 1. Load data
% x:    time domain data
% fs:   sampling frequency
% c:    cough samples


fprintf('Loading input data...\n')

mean_values = [];
% Test files that were created
% test_signal_numbers = [1 3 4 5 6 7 8 9 11 12 13 14 15 16 18 19 20 21 22 26 27 29 31 33 34 35];
% test_signal_numbers = [3 4 5 6 7 8 9 11 12 13 14 15 16 18 19 20 21 22 26 27 29 31 33 34 35];
test_signal_numbers = [3 5 9 11 12 13 15 16 31 35];

for test_signal = 5; %test_signal_numbers

out = [];
% Data paths using the files created from scaper
wavfile = strcat('audio/quiet_room2/soundscape',num2str(test_signal),'.wav');
txtfile = strcat('audio/quiet_room2/soundscape',num2str(test_signal),'.txt');
cough_event = strcat('coughs_',num2str(test_signal));

% IMport audio and annotations
[x,fs] = audioread(wavfile);
T = readtable(txtfile,'TextType','string');

% Start and end times (samples)
st = round(T.Var1(:)*fs); 
en = round(T.Var2(:)*fs);

% Annotations
events = T.Var3(:);
c = [];
nc =  [];

% Loop for each event
for i =1:length(st)
    if(strcmp(cough_event,events(i))) 
        [val,pos] = max(x(st(i):en(i)));
        c = [c st(i)+pos];
    else
        [val,pos] = max(x(st(i):en(i)));
        nc = [nc st(i)+pos];
    end
end

% Make mono
x = x(:,1)';

Duration = length(x)/fs/60;         % Total duration
N = length(x);                      % Number of input samples

% Plot signal and annotations
% plot(x); hold on; plot(c,zeros(size(c)),'rv'); plot(nc,zeros(size(nc)),'gx'); legend('Signal','Coughs','Non-coughs'); hold off
% title(num2str(test_signal))

% Extra info
P = length(c);                  % Number of annotated events

% --plot-----------------
% 2. TF transform
fprintf('STFT...\n')

% TF parameters
% ANALYSIS PARAMETERS NEED TO BE ADJUSTED FOR THE DIFFERENT SAMPLING
% FREUENCIES USED IN MY SYNTHETIC SIGNALS AND THE AMI CORPUS - DUH!

wlen = 4096/2; 
awin = hanning(wlen);       % Hamming window
numfreq = wlen;             % Num of freq components
timestep = wlen/2;          % 50% overlap

% STFT
X = abs(spectrogram(x,awin,timestep,numfreq,'onesided'));
numtime = size(X,2);

% --------------------
% Part 3. PCA w/ SVD and ICA and candidate frames
fprintf('SVD...\n')

num_singular_values = 9;
[~,~,V] = svds(X,num_singular_values); clear X

% ICA
IC = fastica(V')'; 

% Kurtosis
fprintf('Kurtosis...\n')
k = kurtosis(IC);

% Sort in descending order
[k_sort,idx] = sort(k,'descend');

% Lets try out some noralsiing of the three candidate Vs
% candidate_activations = abs(IC(:,idx(1:num_singular_values)));
candidate_activations = abs(IC(:,idx(1:num_singular_values))); clear IC

for ca = 1%:3
% Candidate time-activation function
% C = sum(candidate_activations(:,1:3)');

% What do the individual activations achieve?
C = candidate_activations(:,ca);

% --------------------
% Part 5. Peak finding
close all

fprintf('Peak finding...\n')

% Peak thresholds
a = 5;
tau = a*std(C);               % Minimum peak height
MPD = 30;                       % Minimum peak width (timesteps)
% tau = 0.01;

% Find peaks
[pks,locs] = findpeaks(C,'MinPeakHeight',tau,'MinPeakDistance',MPD);
D = length(locs);               % Number of candidate detections

% --------------------
% Part 6. Isolate audio
fprintf('Isolate audio...\n')

win = 1:ceil(fs);                     % Time domain window length
win = win-length(win)/2;                % Centre window from - to +
yy = zeros(length(win),D);              % Empty output array

for i = 1:D
    
    % Find corresponding sample in time domain for given window
    % i.e. locs has analysis wondow for a given peak
    samp = locs(i)*timestep;
    
    % Concatenate output signal
    rng = win+samp;
    if(rng(1) < 1)
        yy(1:rng(end),i) = x(1:rng(end));
    elseif(rng(end) > N)
        yy(1:length(x(rng(1):end)),i) = x(rng(1):end);
    else
        yy(:,i) = x(rng); 
    end
    
end

% Collapse yy into a single column
y = yy(:);

% -------------------- 
% Part 7. Evaluation criteria

% Intemrediate statistic definitions (from C. Bilen 2019 A Framework for the Robust Evaluation of Sound Event Detection)
% TP: Detected event where ratio of overlap between annotated events and
% detected event and duration of detected event is greater than a predefiend
% threshold, rho_DTC
% FP: Detected event where ratio of overlap between annotated events and
% detected event and duration of detected event is less than a predefiend
% threshold, rho_DTC
% FN: Missed cough events 


fprintf('Evaluate performance...\n')
TP = 0; FP = 0;                 % Intermediate stat counters

% Create annotations vector
% annotation_vector = zeros(1,N);
% event_tolerance = 1:fs/2;
% event_win = event_tolerance-floor(length(event_tolerance)/2);

av = zeros(1,numtime);
event_tolerance = 1:fs/2;
event_win = event_tolerance-floor(length(event_tolerance)/2);
event_win = floor(event_win(1)/timestep):ceil(event_win(end)/timestep);

% for event = 1:P
%     rng = c(event) + event_win;
%     annotation_vector(rng) = 1;
% end

for event = 1:P
    rng = round(c(event)/timestep) + event_win;
    av(rng) = 1;
end

% Create detection matrix/vector and tolerance values
% dm = zeros(N,D);
% detection_samples = floor(locs*timestep)+wlen/2;

dm = zeros(numtime,D);
detection_samples = floor(locs*timestep)+wlen/2;
detection_windows = round(detection_samples./timestep);

for d = 1:D
    
    % Get range of samples
    rng = detection_windows(d) + event_win;
    
    % Fill appropriate vacllues where detections happened
    if rng(1) < 1
        dm(1:rng(end),d) = 1;
    elseif rng(end) > numtime
        dm(rng(1):end,d) = 1;
    else
        dm(rng,d) = 1;
    end
    
end

% Detection overlap criteria
rho_DTC = 0.3;

% Vectorise operation
% dv = annotation_vector*dm./length(event_tolerance) > rho_DTC;
dv = (av*dm)./length(event_win) > rho_DTC;

% Intermediate stats
TP = sum(dv);
FP = sum(dv == 0);
FN = P - TP;

% Events that are true positives - idx
idx = 1:D; 
idx = idx(dv);

% Print intermediate stats
fprintf('TP: %d FP: %d FN: %d ',TP,FP,FN)

% Evaluation criteria
TP_ratio = TP/P * 100;              % True positive ratio (%)
FP_rate = FP/(Duration);     % False positive rate (FP/min)
F1_score = (2*TP)/(2*TP + FN + FP); % F1 score

Reduced_duration = length(yy(:))/fs/60; % Reduced duration 

fprintf('\n\n TP ratio: %.2f%% FP rate: %.2f FP/min F1: %.2f Dur_in: %.2f Dur_out: %.2f\n\n',TP_ratio,FP_rate,F1_score,Duration,Reduced_duration)
