% Refined script for counting cough
% Written by Paul Leamy
% Date: 10MAR2020

clc; close all; clear all

% Algorithm development
% 1. Cough counter basic
% Using just the V matrix (right singular values), identify the peaks, in
% the most leptokurtotic distribution, modulate time domain signal
% appropriately.

% See Scaper for creating soundscapes. 
% https://github.com/justinsalamon/scaper

% -------------------
% 1. Load data

% x:    time domain data
% fs:   sampling frequency
% c:    cough samples

fprintf('Loading input data...\n')

% Test files that were created
test_signal_numbers = [1 3 4 5 6 7 8 9 11 12 13 14 15 16 18 19 20 21 22 26 27 29 31 33 34 35];
out = [];

for test_signal = test_signal_numbers

% Data paths using the files created from scaper
wavfile = strcat('audio/soundscapes/soundscape',num2str(test_signal),'.wav');
txtfile = strcat('audio/soundscapes/soundscape',num2str(test_signal),'.txt');
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

% Plot signal and annotations
plot(x); hold on; plot(c,zeros(size(c)),'rv'); plot(nc,zeros(size(nc)),'gx'); legend('Signal','Coughs','Non-coughs'); hold off
title(num2str(test_signal))
%%
% Extra info
P = length(c);                  % Number of annotated events

% -------------------
% 2. TF transform
fprintf('STFT...\n')

% TF parameters
% ANALYSIS PARAMETERS NEED TO BE ADJUSTED FOR THE DIFFERENT SAMPLING
% FREUENCIES USED IN MY SYNTHETIC SIGNALS AND THE AMI CORPUS - DUH!

wlen = 4096/2; 
%wlen = floor(fs*0.04);
awin = hanning(wlen);       % Hamming window
numfreq = wlen;             % Num of freq components
timestep = wlen/2;          % 50% overlap

% STFT
X = abs(spectrogram(x,awin,timestep,numfreq,'onesided'));

% Median filter
% X = medfilt2(X,[5 1]);

% Xmean = mean(X')';  
% Xmean = repmat(Xmean,1,size(Xhalf,2));
% imagesc(log(medfilt2(Xhalf,[5 1]))); axis xy

% --------------------
% Part 3. PCA w/ SVD and ICA and candidate frames
fprintf('SVD...\n')

num_singular_values = 9;
[U,S,V] = svds(X,num_singular_values);

% ICA
IC = fastica(V')';

% Kurtosis
fprintf('Kurtosis...\n')
k = kurtosis(IC);

% Sort in descending order
[k_sort,idx] = sort(k,'descend');

% Lets try out some noralsiing of the three candidate Vs
candidate_activations = abs(IC(:,idx(1:9)));

% Normalise

% Candidate time-activation function
C = sum(candidate_activations(:,1:3)');

% Nomalise C
% C = C./max(C);

% --------------------
% Part 5. Peak finding
close all

fprintf('Peak finding...\n')

% Peak thresholds
a = 8;
tau = a*std(C);               % Minimum peak height
MPD = 30;                       % Minimum peak width (timesteps)
% tau  = 0.3;

% Find peaks
[pks,locs] = findpeaks(C,'MinPeakHeight',tau,'MinPeakDistance',MPD);
D = length(locs);               % Number of candidate detections

% --------------------
% Part 6. Isolate audio
fprintf('Isolate audio...\n')

win = 1:ceil(fs*2);                     % Time domain window length
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
    elseif(rng(end) > length(x))
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
annotation_vector = zeros(size(x));
event_tolerance = 1:fs/2;
event_win = event_tolerance-floor(length(event_tolerance)/2);

for event = 1:P
    rng = c(event) + event_win;
    annotation_vector(rng) = 1;
end

% Create detection vector and tolerance values
detection_vector = zeros(size(x));
detection_samples = floor(locs*timestep)+wlen/2;

% Detection overlap tolerance
rho_DTC = 0.3;

idx = [];
% Carry out detection tolerance for event (slightly altered)
fprintf('Evaluation progress: ')
for event = 1:D
    
    % Print progress
    fprintf('%.2f\n',event/D);
    
    % Get current range
    rng = detection_samples(event) + event_win;
    
    % Reset detection vector
    detection_vector(:) = 0;
    if rng(1) < 1
        detection_vector(1:rng(end)) = 1;
    else
        detection_vector(rng) = 1;
    end
    
    % Compute overlap, ratio, and determine relevant detections for
    % Detection tolerance criteria
    DTC = sum(annotation_vector & detection_vector) / length(event_tolerance);
    
    % Determine if a relvant detection was made  
    if DTC > rho_DTC % If so, continue to determine GTC
        TP = TP + 1;
        idx = [idx event];
    else
        FP = FP + 1;    % Increment FP count
    end
    
    % BACKSPACES
    fprintf('\b\b\b\b\b') 

end
fprintf('\n')

% Determine number of false negatives (Missed coughs)
FN = P - TP;

% Print intermediate stats
fprintf('TP: %d FP: %d FN: %d ',TP,FP,FN)

% Evaluation criteria
TP_ratio = TP/P * 100;              % True positive ratio (%)
FP_rate = FP/(length(x)/fs/60);     % False positive rate (FP/min)
F1_score = (2*TP)/(2*TP + FN + FP); % F1 score

Precision = TP/(TP+FP);             % Precision
Recall = TP/(TP+FN);                % Recall         

Duration = length(x)/fs/60;         % Total duration
Reduced_duration = length(y)/fs/60; % Reduced duration 


fprintf('\n\n TP ratio: %.2f%% FP rate: %.2f FP/min F1: %.2f Dur_in: %.2f Dur_out: %.2f\n\n',TP_ratio,FP_rate,F1_score,Duration,Reduced_duration)

% Wrtie to .txt file
fileID = fopen('results.txt','a');
fprintf(fileID,'Num: %d TP ratio: %.2f%% FP rate: %.2f FP/min F1: %.2f Dur_in: %.2f Dur_out: %.2f\n',test_signal,TP_ratio,FP_rate,F1_score,Duration,Reduced_duration);
fclose(fileID);

fileID = fopen('results_tex.txt','a');
fprintf(fileID,'%d & %.2f & %.2f & %.2f \\\\ \n',test_signal,TP_ratio,FP_rate,Reduced_duration);
fclose(fileID);

out = [out;test_signal,TP_ratio,FP_rate,Reduced_duration];
end

%%
% Visual  performance
close all
subplot(2,1,1)
findpeaks(C,'MinPeakHeight',tau,'MinPeakDistance',MPD)
hold on
plot(round(c./timestep),zeros(size(c)),'rv')
plot(locs(idx),zeros(size(locs(idx))),'gx')
plot(1:length(C),tau*ones(size(C)),'k--')
%ylim([-0.1 1])

subplot(2,1,2)
plot(0:length(x)-1,x)
hold on
plot(c,zeros(size(c)),'rv')
plot(locs(idx).*timestep,zeros(size(idx)),'gx')
axis tight

%% Play back GUI
close all

global cnt;
cnt = 0;

% Make  a figure
figure;

% Axes
ax_h = axes('units','normalized',...
    'position',[0.1 .3 .8 0.6]);

% Pushbutton
next_h = uicontrol('style','pushbutton',...
    'string','play next',...
    'units','normalized',...
    'position',[0.3 0 0.2 0.2],...
    'callback',{@play_function,yy});

% Pushbutton
last_h = uicontrol('style','pushbutton',...
    'string','play last',...
    'units','normalized',...
    'position',[0.6 0 0.2 0.2],...
    'callback',{@last_function,yy});


% Function definitions

% Play nest sound
function play_function(object_handle,event,ip)
    
    global cnt;
    
    if cnt < size(ip,2)
        cnt = cnt + 1;
    else
        disp('Max reached...')
    end
    
    % Plot data
    plot(0:length(ip)-1,ip(:,cnt),'r--')
    xlabel 'Sample'
    ylabel 'Amplitude'
    msg = strcat('Event: ',num2str(cnt),'/',num2str(size(ip,2))); 
    title(msg)
    
    % Playback signal
    clear sound
    sound(ip(:,cnt),44100)


end
% Play last sound
function last_function(object_handle,event,ip)
    
    global cnt;
    
    if cnt > 1
        cnt = cnt - 1;
    else
        disp('Min reached...')
    end
    
    % Plot data
    plot(0:length(ip)-1,ip(:,cnt),'r--')
    xlabel 'Sample'
    ylabel 'Amplitude'
    msg = strcat('Event: ',num2str(cnt),'/',num2str(size(ip,2))); 
    title(msg)
    
    % Playback signal
    clear sound
    sound(ip(:,cnt),44100)


end