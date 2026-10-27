
%% Processing recordings

clear all;
close all;
                

wavFile_CW_All = {'ThreeMF2.wav';
                        'Demo2mS.wav';
                        'DemoThrow1mFast.wav';
                   'untitled3.wav'}; %{'HumanWalking.wav'; 
                     %'HumanRunning.wav';
                     %'GwibaWalking1.wav';
                     %'GwibaWalking2.wav';
                      %'YAGThrow.wav';
                        %'Fiddling.wav';
                        %'DemoThrow1mSlow.wav';
                          %'DemoThrow1mFast.wav';
                            %'DemoThrow3mSlow.wav';
                               %'DemoThrow3mFast.wav';
                                %'DemoThrow5mFast.wav';
                                %'DemoThrow5mSlow.wav';
                            %'HouseDemo2.wav';
                               %'Hand.wav';
                                %'Bedroom.wav';
                                    %'WalkBed.wav';
                                        %'TryNew2.wav';
                                           %'Back2Old.wav'};
              
RecordingNo2Process = 1 ;              

wavFile_CW = wavFile_CW_All{RecordingNo2Process};
cantenna_dop_v3_CA_CFAR(wavFile_CW);
%cantenna_dop_v3(wavFile_CW);
 




