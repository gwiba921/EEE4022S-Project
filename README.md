# EEE4022S Project: Baseball Speed Estimation Using a Low-Cost CW Doppler Radar

MATLAB code and radar recordings for the EEE4022S final-year project by
Gwiba Siseko Nonkenge (NNKGWI001), University of Cape Town.

The code converts a recording from a 24 GHz IPM-365 continuous-wave (CW)
Doppler radar into a baseball radial-speed estimate. It builds a
Hann-windowed short-time Fourier transform (STFT) spectrogram, converts
Doppler frequency to radial speed, applies column-wise cell-averaging CFAR
(CA-CFAR) detection, keeps the highest-speed detection in each time column,
and reports the average speed over the longest continuous detection run.
The peak detected speed is reported as a supplementary output.

## Repository contents

| File | Purpose |
|---|---|
| `cantenna_dop_v3_CA_CFAR.m` | Main function: loads one WAV file, builds the spectrogram, runs column-wise CA-CFAR, extracts the speed track and prints the average and peak radial speed. Also plots the results. |
| `STFT_GwibaSpectro.m` | STFT function (symmetric Hann window, overlapping frames) used by the main function. |
| `Processing_recordings.m` | Script that selects a recording from a list and passes it to `cantenna_dop_v3_CA_CFAR`. |
| `data/` | Radar recordings (WAV) used in the report. |

## Requirements

- MATLAB (developed with R2025a). Only core MATLAB functions are used
  (`audioread`, `fft`, `movmean`, `trapz`); no toolboxes are required.

## Data

Each WAV file is the real-valued baseband output of the IPM-365 recorded
through a laptop sound card in Audacity at 44.1 kHz. File names give the
throw distance, the instructed speed group and the repetition number:

| Prefix | Distance | Speed group |
|---|---|---|
| `TwoMS` | 2 m | Slow |
| `TwoMM` | 2 m | Medium |
| `TwoMF` | 2 m | Fast |

For example, `TwoMF3.wav` is the third fast throw from 2 m. The repository
contains `TwoMS1`-`TwoMS10`, `TwoMM1`-`TwoMM10` (no `TwoMM8`) and
`TwoMF1`-`TwoMF10`.

## How to run

1. Clone or download this repository and open MATLAB in the repository
   folder.
2. Add the data folder to the MATLAB path:

   ```matlab
   addpath('data')
   ```

3. Process a single recording:

   ```matlab
   cantenna_dop_v3_CA_CFAR('TwoMF1.wav')
   ```

   Alternatively, edit the `wavFile_CW_All` list and `RecordingNo2Process`
   in `Processing_recordings.m`, then run that script.

### Output

The function prints to the Command Window:

- the sampling frequency, STFT frame length and spectrogram size;
- the number of CA-CFAR detections;
- the peak detected radial speed and the time at which it occurred;
- the active detection interval, elapsed time, estimated radial distance and
  the **average detected radial speed** (the primary output).

It also opens figures showing the spectrogram with the CA-CFAR detections
and the speed-time track used for the average.

## Processing parameters

The parameters are set at the top of `cantenna_dop_v3_CA_CFAR.m`.

| Parameter | Value |
|---|---|
| Carrier frequency | 24 GHz |
| Requested CPI | 0.05 s (rounded up to a 4096-sample frame at 44.1 kHz, about 0.0929 s) |
| Frame overlap | 95% |
| Window | Symmetric Hann |
| Lowest speed searched | 2 m/s |
| Highest speed searched (`maxSpeed_m_s`) | Set per speed group as listed in the report's speed-search-region table |
| Moving average | 10 time columns |
| Probability of false alarm | 10^-3 |
| Reference cells | 32 in total (16 per side) |
| Guard cells | 4 per side |
| Minimum relative detection level | -25 dB |

## Licence and use

This code and data were produced for academic assessment of the EEE4022S
final-year project at the University of Cape Town.
