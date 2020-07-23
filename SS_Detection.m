function [Yhat_Results,EMG_Yhat_Results,EMG_est_Yhat_Results,EMG_Auto_Yhat_Results,EMG_Auto_est_Yhat_Results,All_Confusion] = SS_Detection(Sleep_table_Pre,Sleep_Struct,rbd_group,indices,folds,SS_Features,EMG_est_feats,EMG_feats,ECG_feats,n_trees,view_results,print_figures,print_folder,save_data,outfilename,display_flag,prior_mat)
% Copyright (c) 2018, Navin Cooray (University of Oxford)
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are
% met:
%
% 1. Redistributions of source code must retain the above copyright
%    notice, this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright
%    notice, this list of conditions and the following disclaimer in the
%    documentation and/or other materials provided with the distribution.
%
% 3. Neither the name of the University of Oxford nor the names of its
%    contributors may be used to endorse or promote products derived
%    from this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
% "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
% LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
% A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
% HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
% LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
% DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
% THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%	Contact: navsnav@gmail.com
%	Originally written by Navin Cooray 19-Sept-2018
% Input:
%       Sleep_table_Pre:    Sleep table with all features and subjects (preprocessed to have no nans/infs).
%       Sleep_Struct: 	Structure containing all features and feature names
%       rbd_group:      Participant condition/diagnosis (0: Healthy control, 1: RBD participant). 
%       indices:        Indicised for cross-fold validation for sleep staging and RBD detection.
%       folds:          Number of folds for cross-fold validation
%       SS_Features:    Features indicies to be used for automated sleep staging
%       EMG_est_feats:  Indicies of Established EMG features in RBD detection 
%       EMG_feats:      Indicies of features to compare for RBD detection
%       n_trees:        Number of trees for Random Forest training
%       view_results:   Flag for displaying results (0: no, 1: yes).
%       print_figures:  Flag for saving figures (0: no, 1: yes).
%       save_data:      Save data and results in mat format
%       outfilename:    Filename for saved data  
% Output:
%       Yhat_Results:           Automated sleep staging results. 
%       EMG_Yhat_Results:       RBD Detection results using new features.  
%       EMG_Yhat_Results:       RBD Detection results using new
%                               features and manually annoated sleep
%                               stages.
%       EMG_est_Yhat_Results:   RBD Detection results using established
%                               features and manually annoated sleep
%                               stages.
%       EMG_Auto_Yhat_Results:  RBD Detection results using new
%                               features and automated sleep staging.
%       EMG_Auto_est_Yhat_Results:   RBD Detection results using established
%                               features and automated sleep staging.
%       All_Confusion:          Confusion matrices of automated sleep staging.  

Sleep_table = Sleep_table_Pre;
Save_Data_Name = outfilename;
numStates = size(unique(Sleep_table_Pre.AnnotatedSleepStage),1);
if print_figures, mkdir(print_folder), end


Sleep = table2array(Sleep_table);
[patients,ia,ic] = unique(Sleep_table.SubjectIndex);

%%

%% Initialise

Yhat_Results =[];
Yhat_REM_Results = [];
votes_Results = [];
votes_REM_Results = [];
importance_Results = [];
EMG_importance_Results = [];
EMG_est_importance_Results = [];
importance_Results_REM = [];
RBD_Yhat = table;
Yhat_Results = zeros(size(Sleep,1),1);
votes_Results = zeros(size(Sleep,1),numStates);
% EMG_Metric = zeros(size(rbd_group,1),length(ECG_feats));
EMG_Metric = table;
ECG_Yhat_Results = ones(size(rbd_group,1),1)*-1;
ECG_votes_Results = zeros(size(rbd_group,1),2);
EMG_Yhat_Results = ones(size(rbd_group,1),1)*-1;
EMG_votes_Results = zeros(size(rbd_group,1),2);
EMG_est_Yhat_Results = ones(size(rbd_group,1),1)*-1;
EMG_est_votes_Results = zeros(size(rbd_group,1),2);
% EMG_Auto_Metric = zeros(size(rbd_group,1),length(ECG_feats));
EMG_Auto_Metric = table;
ECG_Auto_Yhat_Results = ones(size(rbd_group,1),1)*-1;
ECG_Auto_votes_Results = zeros(size(rbd_group,1),2);
EMG_Auto_Yhat_Results = ones(size(rbd_group,1),1)*-1;
EMG_Auto_votes_Results = zeros(size(rbd_group,1),2);
EMG_Auto_est_Yhat_Results = ones(size(rbd_group,1),1)*-1;
EMG_Auto_est_votes_Results = zeros(size(rbd_group,1),2);
RBD_Auto_Yhat = table;
results_f_est = zeros(folds,6);
results_f_new = zeros(folds,6);   
results_f_est_auto = zeros(folds,6);
results_f_new_auto= zeros(folds,6);

for out=1:folds
    disp(['Fold: ',num2str(out)]);
    PatientTest = (indices==out); %patient id for testing
    PatientTrain = (indices~=out);%patient id for training
    
    PatientTest_idx = ismember(Sleep(:,1),patients(PatientTest)); %patient index for testing
    PatientTrain_idx = ismember(Sleep(:,1),patients(PatientTrain)); %patient index for training
    
    %% Train set (Sleep Staging % RBD Detection)    
    Xtrn = Sleep_table_Pre(PatientTrain_idx,:);
    Ytrn = table2array(Sleep_table_Pre(PatientTrain_idx,7));
    
    %% Testing set (Sleep Staging & RBD Detection)    
    Xtst = Sleep(PatientTest_idx,SS_Features);
    Ytst = Sleep(PatientTest_idx,7);
    tst_condition = Sleep(PatientTest_idx,6);       

    %% Train Sleep Stage RF

% Configure  parameters
%     predict_all=true;
%     extra_options.predict_all = predict_all;
%     extra_options.importance = 1; %(0 = (Default) Don't, 1=calculate)    
%     mtry = floor(sqrt(length(SS_Features))); %number of features used to creates trees
%     rf = classRF_train(Xtrn, Ytrn,n_trees,mtry,extra_options);  

    %Matlab Trees
    
    [rf,rf_importance] = Train_SleepStaging_RF(n_trees,Xtrn,SS_Features,Ytrn,prior_mat);    


   
 %% Test Sleep Staging 
    
    %[Yhat votes predict_val] = classRF_predict(Xtst,rf,extra_options);  

    % Matlab Trees
    [Yhat,votes] = Predict_SleepStaging_RF(rf,Xtst);
    
 %% Test RBD Detection using Annotated Sleep Staging
    
    % Generate Test values based on annoated Sleep Staging
    EMG_Annotated_Test_Table = Calculate_RBD_Values_table(Sleep_table_Pre(PatientTest_idx,:));       
    
    
 %% Test RBD Detection using Automatic Sleep Staging
    
    Sleep_table_automatic = Sleep_table_Pre(PatientTest_idx,:);
    Sleep_table_automatic.AnnotatedSleepStage = Yhat; %Automatic sleep staging
    
    % Generate Test values based on automatic classified Sleep Staging
    EMG_Auto_Test_Table = Calculate_RBD_Values_table(Sleep_table_automatic);
    
    

    %% Store Results  
    % Automated Sleep Staging
    Yhat_Results(PatientTest_idx) =  Yhat;
    votes_Results(PatientTest_idx,:) = votes;
    importance_Results(:,:,out) = [rf_importance];            
    % RBD Detection using Annoated Sleep Staging 
%     EMG_Metric(PatientTest,:) = ECG_Xtst; 
    EMG_Metric = [EMG_Metric;EMG_Annotated_Test_Table];
      
    % RBD Detection using Automatic Sleep Staging
         
%     EMG_Auto_Metric(PatientTest,:) = ECG_Auto_Xtst;
    EMG_Auto_Metric = [EMG_Auto_Metric;EMG_Auto_Test_Table];
    
  
    
end

%% Save Data
Sleep_names = Sleep_table.Properties.VariableNames;



%% Print Sleep Stage Results
states = unique(Sleep_table_Pre.AnnotatedSleepStage);
if (view_results)
   %Print Sleep Staging Results 
    print_results(Sleep,Yhat_Results,states,print_figures,print_folder,display_flag);
end



%% Print Feature Importance Results
if (view_results)
   %RBD Importance (Gini)
    titlename = 'Feature Importance - Mean Decrease in Gini Index';
    xname = 'Mean Decrease in Gini Index (Importance)';
    order_idx = size(importance_Results,2); %Mean Decrease in Gini 
    print_feature_importance(importance_Results,order_idx,Sleep_table_Pre.Properties.VariableNames,SS_Features,titlename,xname,print_figures,print_folder);       
    
end

%% Print Annotated Vs Automatic RBD Metrics
% if (view_results)
%     print_annotated_vs_auto(EMG_Table_Names,ECG_feats,EMG_Metric,EMG_Auto_Metric,print_figures,print_folder);
%     print_annotated_vs_auto(EMG_Table_Names,EMG_feats,EMG_Metric,EMG_Auto_Metric,print_figures,print_folder);
% 
% end

%% Print Confusion Matrices/Hypnograms
if (view_results)
    All_Confusion = print_confusion_mats(Sleep,Sleep_Struct,Yhat_Results,print_figures,print_folder);
end

%%
if (save_data),save(strcat(print_folder,'\',Save_Data_Name,'.mat'),'Sleep','Sleep_table','Sleep_Struct',...
        'Sleep_names','Yhat_Results',...
        'votes_Results',...
        'importance_Results','SS_Features',...
        'EMG_importance_Results','EMG_Yhat_Results','EMG_votes_Results',...
        'EMG_est_Yhat_Results','EMG_Auto_Yhat_Results','EMG_Auto_est_Yhat_Results',...
        'EMG_est_feats','EMG_feats','ECG_feats','EMG_Auto_Metric','EMG_Metric',...
        'ECG_Yhat_Results','ECG_Auto_Yhat_Results','ECG_votes_Results','ECG_Auto_votes_Results','RBD_Yhat','RBD_Auto_Yhat',...
        'All_Confusion');
end


end