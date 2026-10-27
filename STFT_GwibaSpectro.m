% Short Time Fourier Transform (STFT) Function written by EEE4022 student:
% Gwiba Nonkenge 
% Year: 2026

function [Spectro, fv, tv] = STFT_GwibaSpectro(y,fs, N, OF)

% Inputs
%  y - signal of interest (can be real values or complex values)
%  fs  - sampling frequency of the signal in Hz
%  N - Number of samples in a single frame. Should be a power of 2 
%  OF - Overlap factor between successive frames (decimal value). Example: 0.5 means there is 50% overlap of samples between successive  frames
%
% Outputs
% Spectro - computed spectrogram (matrix, complex numbers)
% fv = frequency vector (Hz)
% tv - time vector (s)

y = single(y(:));                            % Coverting the signal y to a column-vector                           
ylen = size(y,1);                    % Signal Length
% Symmetric Hann window, written explicitly to avoid toolbox dependence.
window =  (0.5 - 0.5*cos(2*pi*(0:N-1)/(N-1)))'; %Hann window
% Taylor window parameters
%nbar = 4;                            % Number of nearly constant-level sidelobes
%sll = -60;                           % Maximum sidelobe level relative to mainlobe peak (dB)
%window = taylorwin(N,nbar,sll);       % Taylor window
Overlap_NumSamples = floor(OF*N); % convert to integer value 

hopSize = N -Overlap_NumSamples;
numFrames = 1 + floor((ylen-N)/hopSize);
frameStartIndices = 1 + (0:numFrames-1)*hopSize;
Spectro = zeros(N,numFrames);

for frameNumber = 1:numFrames
    firstIndex = frameStartIndices(frameNumber);
    lastIndex = firstIndex + N - 1;

    frame = y(firstIndex:lastIndex);
    frame = double(frame);
   
    windowedFrame = frame .* window;

    
    frameSpectrum = fft(windowedFrame, N);
     Spectro(:, frameNumber) = fftshift(frameSpectrum,1);
end

% Calculating frequency and time vectors 
tv = (N/2:hopSize:N/2+(numFrames-1)*hopSize)/fs;     % Time axis (s)
fv = (-N/2:1:(N/2-1))*fs/N;                  % Frequency axis (Hz)