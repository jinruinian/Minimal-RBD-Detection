function [All_Sleep, Sleep_Struct, All_Sleep_T] = ExtractFeatures_mat_5minC(dbpath,signals_for_processing,std_flag)
% Main function to extract features from multichannel PSG recordings
%
% Input:
%       dbpath:     Path to directory containing recordings. Recordings are
%       individual .mat files for each subject containing the following variables:
%       - data:     matrix of epoched signals with dimensions (#EPOCH, EPOCH_LENGTH, CHANNELS)
%       - labels:  annotation for each epoch containing sleep stages in format (#EPOCH, 5) with
%       sleep stages coded as [W,R,N1,N2,N3]
%       - patinfo: information on patient data such as sampling frequency, age and gender.
%       signals_for_processing: Cell string array, with signal names for
%                               feature extraction eg {'EEG','EOG',EMG'}
% Output:
%       All_Sleep:      matrix with all features for all recordings for each
%                       specified epoch
%       Sleep_Struct:   Structure for each subject and feature extracted for each signal and epoch
%       All_Sleep_T:    Table with all features for all recordings for each specified epoch
%
% --
% RBD Sleep Detection Toolbox, version 1.0, November 2018
% Released under the GNU General Public License
%
% Copyright (C) 2018  Navin Cooray
% Institute of Biomedical Engineering
% Department of Engineering Science
% University of Oxford
% navin.cooray@eng.ox.ac.uk
%
%
% Referencing this work
% Navin Cooray, Fernando Andreotti, Christine Lo, Mkael Symmonds, Michele T.M. Hu, & Maarten De % Vos (in review). Detection of REM Sleep Behaviour Disorder by Automated Polysomnography Analysis. Clinical Neurophysiology.
%
% Last updated : 15-10-2018
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.



%% Input check
% Dealing with different OS
slashchar = char('/'*isunix + '\'*(~isunix));
if ~strcmp(dbpath(end),slashchar)
    dbpath = [dbpath slashchar];
end
mainpath = (strrep(which(mfilename),['preparation' slashchar mfilename '.m'],''));
addpath(genpath([mainpath(1:end-length(mfilename)-2) 'subfunctions' slashchar])) % add subfunctions folder to path

% default values for input arguments

fs=200;
EEG_CHAN = 1;
EOG_CHAN = 2;
EMG_CHAN = 3;
ECG_CHAN = 4;
EMG_L_CHAN = 5;
EMG_R_CHAN = 6;
MIC_CHAN = 7;
CHEST_CHAN = 8;
FLOW_CHAN = 9;

epoch_time = 30*10;
All_Sleep = [];
All_Sleep_T = table;

%% Main loop
fls = dir([dbpath '*.mat']);
fls = arrayfun(@(x) x.name,fls,'UniformOutput',false);

for f=1:length(fls)
    eeg_feats = [];
    eog_feats = [];
    emg_feats = [];
    emg_l_feats = [];
    emg_r_feats = [];
    eeg_eog_feats = [];
    ecg_feats = [];
    mic_feats = [];
    chest_feats =[];
    flow_feats =[];
    emg_mic_feats = [];
    emg_ecg_feats =[];    
    % Loading recording
    load([dbpath fls{f}]);
    disp(['Extracting Features From: ',fls{f}]);
    %%
    
    hyp_cap = labels;
    hyp = zeros(size(hyp_cap,1),1);
    
    W_col = find(ismember(patinfo.classes,'W'));
    N1_col = find(ismember(patinfo.classes,'S1'));
    N2_col = find(ismember(patinfo.classes,'S2'));
    N3_col = find(ismember(patinfo.classes,'S3'));
    R_col = find(ismember(patinfo.classes,'R'));
    
    W_idx = find(labels(:,W_col));
    N1_idx =  find(labels(:,N1_col));
    N2_idx =  find(labels(:,N2_col));
    N3_idx =  find(labels(:,N3_col));
    R_idx = find(labels(:,R_col));
    
    hyp(W_idx) = 0;
    hyp(N1_idx) = 1;
    hyp(N2_idx) = 2;
    hyp(N3_idx) = 3;
    hyp(R_idx) = 5;
    
%     hyp(:,2) = linspace(0,(size(hyp,1)-1)*30,size(hyp,1));
%     hyp(:,2) = epoch;
    asd = load([dbpath fls{f}], 'epoch');
    epoch = asd.epoch;
    hyp(:,2) = epoch;
    %%
    %% 
    time_after_prev = hyp(2:end,2) - hyp(1:end-1,2);
    if mean(time_after_prev) > 6000
       hyp_diff = 6000;
    else
        hyp_diff = 30;
    end
    non_consecutives = time_after_prev~=hyp_diff;
    non_consecutives_idx = [find(non_consecutives)+1];    
    
    delta_hyp = [0;hyp(2:end,1)-hyp(1:end-1,1)];
    delta_hyp(non_consecutives_idx) = -1;
    non_consecutives_hyp = delta_hyp~=0;

    non_consecutives_hyp_idx = [find(non_consecutives_hyp);length(hyp)];

    num_consecutive_epoch = [non_consecutives_hyp_idx(1)-1;non_consecutives_hyp_idx(2:end)-non_consecutives_hyp_idx(1:end-1)];
    
    %find idx with 5min consecutive epochs
    Con_5min_idx = find(num_consecutive_epoch>10);
%     non_consecutives_hyp_idx(Con_5min_idx)-1; %last epoch of 5min consecutive epochs
    Con_5min_start_idx =[];
    for c=1:length(Con_5min_idx)
        start_idx = (non_consecutives_hyp_idx(Con_5min_idx(c))-num_consecutive_epoch(Con_5min_idx(c)));
        Con_5min_start_idx = [Con_5min_start_idx;[start_idx:1:start_idx-1+10*floor(num_consecutive_epoch(Con_5min_idx(c))/10)]'];
    end
    new_hyp = hyp(Con_5min_start_idx(1:10:end),:);
    
    %    
%     floor(num_consecutive_epoch(Con_5min_idx)/10);
%     
%     Con_5min_epochs(:,1) = Con_5min_start_idx;
%     Con_5min_epochs(:,2) = Con_5min_start_idx+1;
%     Con_5min_epochs(:,3) = Con_5min_start_idx+2;
%     Con_5min_epochs(:,4) = Con_5min_start_idx+3;
%     Con_5min_epochs(:,5) = Con_5min_start_idx+4;
% 
%     Con_5min_epochs = reshape(Con_5min_epochs',numel(Con_5min_epochs),1);
    
    Con_5min_epochs = Con_5min_start_idx;
    
    hyp = hyp(Con_5min_epochs,:);
    K = length(hyp)/10;

    
    %%
    Sleep = ones(K,1)*f; % subject_index
    try
        Sleep(:,2) = patinfo.age; % age
    catch
         Sleep(:,2) = 0; % age       
    end
    Sleep(:,3) = strcmpi('M',patinfo.gender); % gender
    Sleep(:,7) = new_hyp(:,1); % main response variable
    try 
    Sleep(:,8) = ones(K,1)*(new_hyp(end,2) - new_hyp(1,2))/3600; % sleep duration
    Sleep(:,9) = new_hyp(:,2); % sleep duration
    catch
    Sleep(:,8) = zeros(K,1); % sleep duration
    Sleep(:,9) = zeros(K,1); % sleep duration        
    end
    Sleep(:,10) = 0; % time hypnogram starts
    
    % ==============
    aaa = char(fls{f});
    s1 = regexp(aaa, '[1-9]');
    name_category{f} = aaa(1:s1(1)-1);
    subject = aaa(1:end-4);
    subject = strrep(subject,'-','_');
    % depending on the subject category, populate the 6th column
    switch (name_category{f})
        case 'n' % normal
            Sleep(:,6) = 0; % normal
            
        case 'nfle' % nocturnal frontal lobe epilepsy
            Sleep(:,6) = 1;
            
        case 'brux' % Bruxism
            Sleep(:,6) = 2; % normal
            
        case 'ins' % insomnia
            Sleep(:,6) = 3; % normal
            
        case 'narco' % narcolepsy
            Sleep(:,6) = 4; % normal
            
        case 'rbd' % RBD
            Sleep(:,6) = 5; % normal
            
        case 'SS' % HC
            Sleep(:,6) = 0; % normal
            
        case 'Patient_N' % RBD
            Sleep(:,6) = 5; % normal
            
        otherwise % problem!
            Sleep(:,6) = -1; % check out if we get that
    end
    %%
    Sleep_names = {};
    Sleep_names = { ...
        'SubjectIndex',...
        'Age',...
        'Sex',...
        'Spare',...
        'filenname',...
        'SubjectCondition',...
        'AnnotatedSleepStage',...
        'SleepDuration',...
        'AbsoluteTiming_s',...
        'TimePersonWentToBed'};
    
    for j = 1:length(signals_for_processing)
        
        % Remove NaNs
        data(any(any(isnan(data),3),2),:,:) = [];
        
        switch char(signals_for_processing(j))
            case {'EEG'}
                feature_time = 10;
                EEG_CHAN = find(strcmp(cellstr(patinfo.chlabels), char(signals_for_processing(j))));
                data_signal = squeeze(data(:,:,EEG_CHAN))';
                data_signal = reshape(data_signal,numel(data_signal),1);
                disp("Extracting EEG features")
                [eeg_feats, features_struct_30s,eeg_data_signal,~] = FeatExtract_EEG_mini(data_signal, fs,epoch_time,feature_time,std_flag);
                Sleep_Struct.(subject).EEG = features_struct_30s;
                EEGSnamesSubjects = fieldnames(features_struct_30s)';
                Sleep_names(length(Sleep_names)+1:length(Sleep_names)+length(EEGSnamesSubjects)) = EEGSnamesSubjects;
                
            case {'EOG'}
                EOG_CHAN = find(strcmp(cellstr(patinfo.chlabels), char(signals_for_processing(j))));
                disp("Extracting EOG features")
                feature_time = 10;
                data_signal = squeeze(data(:,:,EOG_CHAN))';
                data_signal = reshape(data_signal,numel(data_signal),1);
                [eog_feats, features_struct_30s,eog_data_signal,~] = FeatExtract_EOG_mini(data_signal, fs,epoch_time,feature_time,std_flag);
                Sleep_Struct.(subject).EOG = features_struct_30s;
                EOGSnamesSubjects = fieldnames(features_struct_30s)';
                Sleep_names(length(Sleep_names)+1:length(Sleep_names)+length(EOGSnamesSubjects)) = EOGSnamesSubjects;
                
            case {'EMG'}
                EMG_CHAN = find(strcmp(cellstr(patinfo.chlabels), char(signals_for_processing(j))));
                disp("Extracting EMG features")
                data_signal = squeeze(data(:,:,EMG_CHAN))';
                data_signal = reshape(data_signal,numel(data_signal),1);
                [emg_feats, features_struct_30s, emg_data_signal,~] = FeatExtract_EMG_mini(data_signal, fs,epoch_time, hyp,std_flag);
                Sleep_Struct.(subject).EMG = features_struct_30s;
                EMGSnamesSubjects = fieldnames(features_struct_30s)';
                Sleep_names(length(Sleep_names)+1:length(Sleep_names)+length(EMGSnamesSubjects)) = EMGSnamesSubjects;
            case {'EMG_L'}
                EMG_CHAN = find(strcmp(cellstr(patinfo.chlabels), char(signals_for_processing(j))));
                disp("Extracting EMG features")
                data_signal = squeeze(data(:,:,EMG_L_CHAN))';
                data_signal = reshape(data_signal,numel(data_signal),1);
                [emg_l_feats, features_struct_30s, emg_data_signal,~] = FeatExtract_EMG_mini(data_signal, fs,epoch_time, hyp,std_flag);
                Sleep_Struct.(subject).EMG_L = features_struct_30s;
                EMGSnamesSubjects = fieldnames(features_struct_30s)';
                Sleep_names(length(Sleep_names)+1:length(Sleep_names)+length(EMGSnamesSubjects)) = strcat('L_',EMGSnamesSubjects);
            case {'EMG_R'}
                EMG_CHAN = find(strcmp(cellstr(patinfo.chlabels), char(signals_for_processing(j))));
                disp("Extracting EMG features")
                data_signal = squeeze(data(:,:,EMG_R_CHAN))';
                data_signal = reshape(data_signal,numel(data_signal),1);
                [emg_r_feats, features_struct_30s, emg_data_signal,~] = FeatExtract_EMG_mini(data_signal, fs,epoch_time, hyp,std_flag);
                Sleep_Struct.(subject).EMG_R = features_struct_30s;
                EMGSnamesSubjects = fieldnames(features_struct_30s)';
                Sleep_names(length(Sleep_names)+1:length(Sleep_names)+length(EMGSnamesSubjects)) = strcat('R_',EMGSnamesSubjects);
                    
                
            case {'EEG-EOG'}
                disp("Extracting EEG/EOG features")
                feature_time = 10;
                [eeg_eog_feats, features_struct_30s,~] = FeatExtract_EEGEOG_mini(eeg_data_signal,eog_data_signal,fs,epoch_time,feature_time);
                Sleep_Struct.(subject).EEGEOG = features_struct_30s;
                EEGEOGSnamesSubjects = fieldnames(features_struct_30s)';
                Sleep_names(length(Sleep_names)+1:length(Sleep_names)+length(EEGEOGSnamesSubjects)) = EEGEOGSnamesSubjects;

           
                
            case {'ECG'}
                feature_time = 30*10;
                ECG_CHAN = find(strcmp(cellstr(patinfo.chlabels), char(signals_for_processing(j))));
                data_signal = squeeze(data(:,:,ECG_CHAN))';
                data_signal = data_signal(:,Con_5min_start_idx);
                
                data_signal = reshape(data_signal,numel(data_signal),1);
                disp("Extracting ECG features")
                [ecg_feats, features_struct_30s,ecg_data_signal] = FeatExtract_HR_mat(data_signal, fs,epoch_time,std_flag);
                Sleep_Struct.(subject).ECG = features_struct_30s;
                ECGSnamesSubjects = fieldnames(features_struct_30s)';
                Sleep_names(length(Sleep_names)+1:length(Sleep_names)+length(ECGSnamesSubjects)) = ECGSnamesSubjects;

            case {'MIC'}
                EMG_CHAN = find(strcmp(cellstr(patinfo.chlabels), char(signals_for_processing(j))));
                disp("Extracting MIC features")
                data_signal = squeeze(data(:,:,MIC_CHAN))';
                data_signal = reshape(data_signal,numel(data_signal),1);
                [mic_feats, features_struct_30s, mic_data_signal,~] = FeatExtract_EMG_mini(data_signal, fs,epoch_time, hyp);
                Sleep_Struct.(subject).MIC = features_struct_30s;
                MICSnamesSubjects = fieldnames(features_struct_30s)';
                Sleep_names(length(Sleep_names)+1:length(Sleep_names)+length(MICSnamesSubjects)) = strrep(MICSnamesSubjects,'EMG','MIC');                        
            case {'CHEST'}
                CHEST_CHAN = find(strcmp(cellstr(patinfo.chlabels), char(signals_for_processing(j))));
                disp("Extracting CHEST features")
                data_signal = squeeze(data(:,:,CHEST_CHAN))';
                data_signal = reshape(data_signal,numel(data_signal),1);
                [chest_feats, features_struct_30s, chest_data_signal,~] = FeatExtract_EMG_mini(data_signal, fs,epoch_time, hyp);
                Sleep_Struct.(subject).CHEST = features_struct_30s;
                CHESTnamesSubjects = fieldnames(features_struct_30s)';
                Sleep_names(length(Sleep_names)+1:length(Sleep_names)+length(CHESTnamesSubjects)) = strrep(CHESTnamesSubjects,'EMG','CHEST');                                   
            case {'FLOW'}
                FLOW_CHAN = find(strcmp(cellstr(patinfo.chlabels), char(signals_for_processing(j))));
                disp("Extracting FLOW features")
                data_signal = squeeze(data(:,:,FLOW_CHAN))';
                data_signal = reshape(data_signal,numel(data_signal),1);
                [flow_feats, features_struct_30s, flow_data_signal,~] = FeatExtract_EMG_mini(data_signal, fs,epoch_time, hyp);
                Sleep_Struct.(subject).FLOW = features_struct_30s;
                FLOWnamesSubjects = fieldnames(features_struct_30s)';
                Sleep_names(length(Sleep_names)+1:length(Sleep_names)+length(FLOWnamesSubjects)) = strrep(FLOWnamesSubjects,'EMG','FLOW');   
            case {'EMG-MIC'}
                disp("Extracting EMG/MIC features")
                feature_time = 10;
                [emg_mic_feats, features_struct_30s,~] = FeatExtract_EEGEOG_mini(emg_data_signal,mic_data_signal,fs,epoch_time,feature_time);
                Sleep_Struct.(subject).EMGMIC = features_struct_30s;
                EMGMICSnamesSubjects = strrep(fieldnames(features_struct_30s)','EEG_','EMGMIC');
                Sleep_names(length(Sleep_names)+1:length(Sleep_names)+length(EMGMICSnamesSubjects)) = strrep(EMGMICSnamesSubjects,'EEGEOG','EMGMIC');
            case {'EMG-ECG'}
                disp("Extracting EMG/ECG features")
                feature_time = 10;
                [emg_ecg_feats, features_struct_30s,~] = FeatExtract_EEGEOG_mini(emg_data_signal,ecg_data_signal,fs,epoch_time,feature_time);
                Sleep_Struct.(subject).EMGECG = features_struct_30s;
                EMGECGSnamesSubjects = strrep(fieldnames(features_struct_30s)','EEG_','EMGECG');
                Sleep_names(length(Sleep_names)+1:length(Sleep_names)+length(EMGECGSnamesSubjects)) = strrep(EMGECGSnamesSubjects,'EEGEOG','EMGECG');
                  
            otherwise
                warning(['Signal ' char(signals_for_processing(j)) ' not found!']);
        end
        
        %% labels
        
        %     save(['features_' fls{f}],'Sleep')
    end
    % Add hours from start [c = hyp(:,2) c(1) = hyp(1,2)]
    time_from_start = (new_hyp(:,2)-new_hyp(1,2))./3600;
    time_from_end = flipud((new_hyp(:,2)-new_hyp(1,2))./3600);
    Sleep_Struct.(subject).HoursRec = time_from_start;
    Sleep_Struct.(subject).HoursFromEnd = time_from_end;
    
    
    Sleep_Struct.(subject).Hypnogram = new_hyp;
    
    Sleep_names(length(Sleep_names)+1) = {'HoursRec'};
    Sleep_names(length(Sleep_names)+1) = {'HoursFromEnd'};
    
    % Combining features into one patient table
    Ttmp = [eeg_feats,eog_feats];
    Ttmp2 = [emg_feats,eeg_eog_feats,ecg_feats,emg_l_feats,emg_r_feats,mic_feats,chest_feats,flow_feats,emg_mic_feats,emg_ecg_feats];
    Sleep = [Sleep,Ttmp,Ttmp2,time_from_start,time_from_end];
    
    Sleep_T = array2table(Sleep, 'VariableNames',Sleep_names);
    
    All_Sleep_T = [All_Sleep_T;Sleep_T];
    All_Sleep = [All_Sleep;Sleep];
    
    clear data epoch labels patinfo Ttmp Ttmp2 emg_feats eeg_feats eog_feats eeg_eog_feats feattab
    
    
    
end

end