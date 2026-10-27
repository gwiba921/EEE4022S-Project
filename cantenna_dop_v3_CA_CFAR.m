function [] = cantenna_dop_v3_CA_CFAR(wavFile)
%
% Produces a Doppler-time spectrogram of measured CW radar data and applies
% column-wise CA-CFAR across the Doppler-frequency/speed bins.
%
% wavFile = filename of the measured .WAV file to process

% Input parameters
FontSizeInPlots = 13;
CPI = 0.05; % seconds

% Constants
c = 299e6; % (m/s) speed of light
fc = 24e9; % (Hz) centre frequency
maxSpeed_m_s = 10; % (m/s) maximum speed to display

% Computations
lamda = c/fc;

% Use a default filename if none is given
if ~exist('wavFile','var')
    wavFile = 'radar_test2.wav';
end

% Read the measured radar data
fprintf('Loading WAV file...\n');
[Y,fs] = audioread(wavFile,'native');
y = -Y(:,1); % Real-valued received signal at baseband

% Compute the spectrogram
NumSamplesPerFrame = 2^(nextpow2(round(CPI*fs)));
OverlapFactor = 0.95;

%[S, f, t] = STFT_GwibaSpectro(y,fs,NumSamplesPerFrame,OverlapFactor);

% Select the time and positive-speed region of interest
[S, f, t] = STFT_GwibaSpectro(y,fs, NumSamplesPerFrame, OverlapFactor);

 Time_sec_Idx = 1:length(t);   %Time_sec_Idx =   find((t <= 2) & (t >= 0));
tVectorOfInterest = t(Time_sec_Idx);

speed_m_per_sec = f*lamda/2;
speed_m_per_sec_Idx = find((speed_m_per_sec <= maxSpeed_m_s) & (speed_m_per_sec >= 2));
% speed_km_per_hr = speed_m_per_sec*(60*60/1000);
% speed_km_per_hr_Idx = find((speed_km_per_hr <= maxSpeed_km_hr) & (speed_km_per_hr >= 0));

% SpeedVectorOfInterest = speed_km_per_hr(speed_km_per_hr_Idx);
% S_OfInterest = S(speed_km_per_hr, :);
SpeedVectorOfInterest = speed_m_per_sec(speed_m_per_sec_Idx);
S_OfInterest = S(speed_m_per_sec_Idx,:);

 %S_OfInterest = S(speed_m_per_sec_Idx, Time_sec_Idx); % Abdul Gaffar 

%S_OfInterestToPlot = abs(S_OfInterest)/max(max(abs(S_OfInterest)));

% Convert the complex STFT values to linear power for CA-CFAR
DataAfterPowerLawDetector = abs(S_OfInterest).^2;
z_temp = DataAfterPowerLawDetector;
MovAvgFilerLength = 10;                        % Abdul Gaffar: compare this to a value of 1, where no suppression is done
z = movmean(z_temp, MovAvgFilerLength, 2);     % Abdul Gaffar: apply a moving average filer
[Rows,Columns] = size(z);

% CA-CFAR parameters
PFA = 10^-3;
RefWindow = 32;
N = RefWindow;
HalfRef = N/2;
GuardCells = 4;

% This alpha multiplies the SUM of all N reference cells
alpha = PFA^(-1/N) - 1;

threshold =NaN(Rows,Columns);
detection = false(Rows,Columns);

% Do not use modulo wrapping on the cropped speed region.
% The first and last speed bins are therefore not tested as CUTs.
firstCUT = HalfRef + GuardCells + 1;
lastCUT = Rows - HalfRef - GuardCells;

if firstCUT > lastCUT
    error(['The selected speed region does not contain enough frequency '
        'bins for the chosen reference and guard cells.']);
end

% Extract one time column from the spectrogram at a time
for ColumnIndex = 1 : Columns

    ExtractedColumn = z(:,ColumnIndex);

    % Apply 1D CA-CFAR across the speed/frequency bins in this column
    for c = firstCUT : lastCUT
        lag = ExtractedColumn(c-GuardCells-HalfRef:c-GuardCells-1);
        lead = ExtractedColumn(c+GuardCells+1:c+GuardCells+HalfRef);

        refCellSum = sum(lead) + sum(lag);

        threshold(c,ColumnIndex) = alpha * refCellSum;
        detection(c,ColumnIndex) = ExtractedColumn(c) > ...
            threshold(c,ColumnIndex);
    end
end
% Prepare the spectrogram for display in dB
MaximumMagnitude = max(max(abs(S_OfInterest)));
S_OfInterestToPlot = abs(S_OfInterest)/(MaximumMagnitude);
Spectrogram_dB = 20*log10(S_OfInterestToPlot);

% Remove CA-CFAR detections below -25 dB.
MinimumDetectionLevel_dB = -25;

detection(Spectrogram_dB < MinimumDetectionLevel_dB) = false;

% Keep only the highest-speed detection in each column.
HighestSpeedDetection = false(Rows,Columns);
HighestSpeed_m_s = NaN(1,Columns);
for ColumnIndex = 1 : Columns

    DetectedRowsInColumn = find(detection(:,ColumnIndex));

    if ~isempty(DetectedRowsInColumn)

        % Select the detection having the highest speed.
        [~,HighestSpeedIndex] = max(SpeedVectorOfInterest(DetectedRowsInColumn));

        SelectedRow = DetectedRowsInColumn(HighestSpeedIndex);

        HighestSpeedDetection(SelectedRow,ColumnIndex) = true;
        HighestSpeed_m_s(ColumnIndex) = SpeedVectorOfInterest(SelectedRow);
    end
end

% Compare the highest-speed detections from all columns and extract the
% overall peak speed for this recording.
ValidDetectionColumns = find(~isnan(HighestSpeed_m_s));
ValidDetectionColumns = ValidDetectionColumns(:).';

if isempty(ValidDetectionColumns)

    MaximumDetectedSpeed_m_s = NaN;
    MaximumSpeedColumn = NaN;
    MaximumSpeedTime_s = NaN;

else

    [MaximumDetectedSpeed_m_s,MaximumSpeedIndex] = max(HighestSpeed_m_s(ValidDetectionColumns));

    MaximumSpeedColumn = ValidDetectionColumns(MaximumSpeedIndex);

    MaximumSpeedTime_s = t(MaximumSpeedColumn);

end

% Calculate the area under the detected radial-speed-versus-time graph.
% The longest continuous run is used so that isolated detections and
% separate detection fragments are not integrated together.

ActiveDetectionColumns = [];
ActiveDetectionTimes_s = [];
ActiveDetectionSpeeds_m_s = [];

EstimatedRadialDistance_m = NaN;
DetectionElapsedTime_s = NaN;
AverageDetectedSpeed_m_s = NaN;

if length(ValidDetectionColumns) >= 2

    % Find positions where the detections stop being consecutive.
    DetectionBreaks = find(diff(ValidDetectionColumns) > 1);

    % Identify the start and end of every continuous detection run.
    RunStartIndices = [1 DetectionBreaks+1];
    RunEndIndices = [DetectionBreaks length(ValidDetectionColumns)];

    RunLengths = RunEndIndices-RunStartIndices+1;

    % Select the longest continuous detection run.
    [~,LongestRunIndex] = max(RunLengths);

    ActiveDetectionColumns = ValidDetectionColumns( ...
        RunStartIndices(LongestRunIndex): ...
        RunEndIndices(LongestRunIndex));

    if length(ActiveDetectionColumns) >= 2

        ActiveDetectionTimes_s = t(ActiveDetectionColumns);

        ActiveDetectionSpeeds_m_s = ...
            HighestSpeed_m_s(ActiveDetectionColumns);

        % Integrate speed with respect to time.
        % Units: (m/s)*s = m.
        EstimatedRadialDistance_m = trapz( ...
            ActiveDetectionTimes_s, ...
            ActiveDetectionSpeeds_m_s);

        % Time between the first and last detections.
        DetectionElapsedTime_s = ...
            ActiveDetectionTimes_s(end)- ...
            ActiveDetectionTimes_s(1);

        % Average radial speed = radial distance/time.
        AverageDetectedSpeed_m_s = ...
            EstimatedRadialDistance_m/ ...
            DetectionElapsedTime_s;

    else

        ActiveDetectionColumns = [];

    end
end

NumberOfTestedCells = (lastCUT-firstCUT+1)*Columns;
NumberOfDetections = sum(detection(:));
DetectionPercentage = NumberOfDetections/NumberOfTestedCells*100;

fprintf('Sampling frequency = %.2f Hz\n',fs);
fprintf('Samples per STFT frame = %d\n',NumSamplesPerFrame);
fprintf('Number of time columns = %d\n',Columns);
fprintf('Number of speed rows = %d\n',Rows);
fprintf('Number of tested cells = %d\n',NumberOfTestedCells);
fprintf('Number of CA-CFAR detections = %d\n',NumberOfDetections);
fprintf('Detected-cell percentage = %.4f%%\n',DetectionPercentage);

if isnan(MaximumDetectedSpeed_m_s)

    fprintf('No valid peak speed was detected for this recording.\n');

else

    fprintf('Peak detected speed for %s = %.2f m/s\n', wavFile,MaximumDetectedSpeed_m_s);

   fprintf('Peak detected speed occurred at %.3f s\n', MaximumSpeedTime_s);

end

if isnan(AverageDetectedSpeed_m_s)

    fprintf(['A continuous detection run containing at least two time ' ...
        'columns was not found, so average speed was not calculated.\n']);

else

    fprintf('Active detection interval = %.3f s to %.3f s\n', ...
        ActiveDetectionTimes_s(1), ...
        ActiveDetectionTimes_s(end));

    fprintf('Elapsed detection time = %.4f s\n', ...
        DetectionElapsedTime_s);

    fprintf('Estimated radial distance = %.4f m\n', ...
        EstimatedRadialDistance_m);

    fprintf('Average detected radial speed for %s = %.2f m/s\n', ...
        wavFile,AverageDetectedSpeed_m_s);

end

% Data-to-threshold ratio: 0 dB means data equals the CA-CFAR threshold
ThresholdRatio_dB = 10*log10((z)./(threshold));

% Locate detections in the complete time-speed region
%[DetectionRows,DetectionColumns] = find(detection);
[DetectionRows,DetectionColumns] = find(HighestSpeedDetection);

% Abdul Gaffar - value in spectrogram for detection
LinearIndices = sub2ind(size(Spectrogram_dB), DetectionRows, DetectionColumns);
ValuesAll = Spectrogram_dB(LinearIndices);
figure; plot(ValuesAll, '*');

% Plot the detected speed-time graph and shade the integrated area.
if ~isnan(AverageDetectedSpeed_m_s)

    figure;

    AreaUnderSpeedGraph = area( ...
        ActiveDetectionTimes_s, ...
        ActiveDetectionSpeeds_m_s);

    AreaUnderSpeedGraph.FaceAlpha = 0.25;
    AreaUnderSpeedGraph.EdgeColor = 'none';

    hold on;

    plot(ActiveDetectionTimes_s, ...
        ActiveDetectionSpeeds_m_s, ...
        'b.-', ...
        'MarkerSize',10, ...
        'LineWidth',1.5);

    xlabel('Time (s)', ...
        'FontSize',FontSizeInPlots);

    ylabel('Detected radial speed (m/s)', ...
        'FontSize',FontSizeInPlots);

    title(sprintf(['Detected Speed-Time Area: Distance = %.3f m, ' ...
        'Average Speed = %.2f m/s'], ...
        EstimatedRadialDistance_m, ...
        AverageDetectedSpeed_m_s));

    set(gca,'FontSize',FontSizeInPlots);
    grid on;

end

% Plot the measured spectrogram and overlay the CA-CFAR results
clims = [-50 0];
figure;
imagesc(t,SpeedVectorOfInterest,Spectrogram_dB,clims);
axis xy;
hold on;



DetectionMarkers = plot(t(DetectionColumns),SpeedVectorOfInterest(DetectionRows),'wx','MarkerSize',5,  'LineWidth',1.0);

xlabel('Time (s)','FontSize',FontSizeInPlots);
ylabel('Radial speed (m/s)','FontSize',FontSizeInPlots);
title('Measured CW Radar Spectrogram with Column-wise CA-CFAR Detections');
set(gca,'FontSize',FontSizeInPlots);
grid on;

ColourScale = colorbar;
ColourScale.FontSize = FontSizeInPlots;
ylabel(ColourScale,'Relative spectrogram magnitude (dB)');
colormap('jet');

legend(DetectionMarkers, 'Detected cell','Location','best');

end
