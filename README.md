[![license](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](./LICENSE)

## Minimal Sleep Staging and RBD Detection

#### Code used in paper: Screening for REM Sleep Behaviour Disorder with Minimal Sensors ([arXiv link](https://arxiv.org/abs/1910.11702))

When using this code, please cite [1]: 

> Navin Cooray, Fernando Andreotti, Christine Lo, Mkael Symmonds, Michele T.M. Hu, & Maarten De Vos (in review). Code used in paper: Screening for REM Sleep Behaviour Disorder with Minimal Sensors.

This repository contains the tools to extract xxx features from a single EOG, EMG, and ECG signal over 30s epochs. 

A random forest classifier is provided to achieve automatic sleep staging, which was trained using 50 age-matched healthy control and RBD participants (but only with 50 trees, wheras the paper used 500). A classifier can also be trained using this repository. Classifier should output one of the following sleep stages:

| Class  | Description |
| ----- | -------------------:|
| 0 | Wake |
| 2 | NREM |
| 5 | REM |

An additional feature extraction tool is provided to analyse an EMG and/or ECG channel for RBD detection. Features are derived for each participant and include established RBD metrics as well as additional metrics. These features can be derived using manually annotated or automatically classified sleep stages. 

An additional random forest classifier is provided to achieve RBD detection using RBD metrics, which was trained using 50 age-matched healthy control and RBD participants. A classifier can also be trained using this repository. Classifier should output one of the following states:

| Class  | Description |
| ----- | -------------------:|
| 0 | Healthy Control |
| 1 | Potential RBD Individual |

* Matlab Random Forest Model - Sleep Staging (`data` folder)
* Matlab Random Forest Model - RBD Detection  (`data` folder)

## Getting Started

Min_RBD_Detection_Demo.m:
Use this file to run a quick demonstration of automatic sleep staging and RBD detection using PSG recordings that will download automatically from the physionet CAP sleep database. Automatic sleep staging and results will be processed and displayed using a random forst model previously trained, as described in [1]. This will be followed by RBD detection using annoated and automatic sleep staging, using a previosuly trained random forest model as descrubed in [1]. Simply run this file to view results taht will be displayed on the command window. To view figures and graphs, change flags: print_figures 0->1.

Min_RBD_Detection_main.m
Use this file to emulate the cross-fold evaluation described in [1] to assess the random forest automatic sleep stage classifier. Additionally the RBD detection method will also be evaluated using annotated and automated sleep staging using established and new metrics. This file can be used in 4 ways:

| Scenario  | Description |
| ----- | -------------------:|
| A | A folder containing all edf files and annotations |
| B | Download demo files eg using CAP sleep database |
| C | A folder containing all 'prepared' mat files of all PSG signals (previously generated) |
| D | Load Features matrix saved from ExtractFeatures (previously generated) |

The file is configured to run in scenario B and will download 10 files (5 healthy controls and 5 RBD participants) from  physionet [The CAPS Sleep Database](https://physionet.org/pn6/capslpdb/). Simply run this file and PSG will be downloaded, PSG signals will be prepared and features extracted. To evaluate the sleep staging and rbd detection, cross-fold evlauation is then computed and results displayed and saved. Default flags are configured to print and save all graphs and figures. 

To initate other scenarios simply comment and uncomment sections ascociated with desired scenarios. 

## Downloading data

Example PSG data can be downloaded from physionet [The CAPS Sleep Database](https://physionet.org/pn6/capslpdb/). Alternatively the main files include code to download sample files from physionet (5 healthy controls and 5 RBD participants). Lastly, code can be modified to point to a folder containing necessary raw files or mat files. 

## Acknowledgment
All authors are affiliated at the Institute of Biomedical Engineering, Department of Engineering Science, University of Oxford.

## License

Released under the GNU General Public License v3

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program. If not, see http://www.gnu.org/licenses/.

## References

When using this code, please cite [1].

[1]: Navin Cooray, Fernando Andreotti, Christine Lo, Mkael Symmonds, Michele T.M. Hu, & Maarten De Vos (In Review). Screening for REM Sleep Behaviour Disorder with Minimal Sensors. Clinical Neurophysiology.
