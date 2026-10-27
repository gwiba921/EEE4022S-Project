
%% Processing recordings

clear all;
close all;

% The recordings are stored in the data folder of this repository.
addpath('data');

% Recordings used in the report: 2 m throws, slow (S), medium (M) and fast (F)
wavFile_CW_All = {'TwoMS1.wav';  'TwoMS2.wav';  'TwoMS3.wav';  'TwoMS4.wav';
                  'TwoMS5.wav';  'TwoMS6.wav';  'TwoMS7.wav';  'TwoMS8.wav';
                  'TwoMS9.wav';  'TwoMS10.wav';
                  'TwoMM1.wav';  'TwoMM2.wav';  'TwoMM3.wav';  'TwoMM4.wav';
                  'TwoMM5.wav';  'TwoMM6.wav';  'TwoMM7.wav';  'TwoMM9.wav';
                  'TwoMM10.wav';
                  'TwoMF1.wav';  'TwoMF2.wav';  'TwoMF3.wav';  'TwoMF4.wav';
                  'TwoMF5.wav';  'TwoMF6.wav';  'TwoMF7.wav';  'TwoMF8.wav';
                  'TwoMF9.wav';  'TwoMF10.wav'};

% Select the recording to process (1 to 29, in the order listed above)
RecordingNo2Process = 1 ;

wavFile_CW = wavFile_CW_All{RecordingNo2Process};
cantenna_dop_v3_CA_CFAR(wavFile_CW);
%cantenna_dop_v3(wavFile_CW);
 




