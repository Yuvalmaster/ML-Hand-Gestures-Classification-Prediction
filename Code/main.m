
clc; close all; clear all;
%% Load data, event triggered segmentation, and feature extraction
% X — Feature matrix
% Y — labels
% tp - true positive. segment/event that contains 1-6 labels. 
% fp - false positive. segment/event that doesn't contains 1-6 labels.
% fn - false negetive. 1-5 events that were missed. must be zero on train dataset.
% tp, fp, fn in values and not precentages.

% ################## LOADING SAVED DATA ################## %
files_names = {'Train features extraction', 'Test features extraction',...
               'Train features vetting'   , 'Test features vetting'   ,...
               'Train features selection' , 'Test features selection'};

files       = {'Train_feature_extraction_data.mat', 'Test_feature_extraction_data.mat',...
               'Train_feature_vetting_data.mat'   , 'Test_feature_vetting_data.mat'   ,...
               'Train_feature_selection_data.mat' , 'Test_feature_selection_data.mat'};

for file=1:numel(files_names)
    try
        load(files{file})
    catch
        disp(append(files_names{file},' file do not exist: Generating ',append(files_names{file}, ' data')))
    end
end
% ################## ################## ################## %

tmp = split(pwd,'\');
tmp = join(tmp(1:end-1,1),'\');
mainpath = tmp{1,1};

addpath(strcat(pwd,'/Functions'))

train_folder_path = strcat(mainpath,'\train');
test_folder_path  = strcat(mainpath,'\test' );

% TRAIN FEATURES EXTRACTION %
if not(exist('X_train'))
    [X_train, Y_train, tp_train , fn_train, fp_train] = event_triggered_feature_extraction(train_folder_path); 
    disp(' ')

    save('Train_feature_extraction_data.mat', 'X_train', 'Y_train', 'tp_train' , 'fn_train', 'fp_train')
end

precision   = tp_train/(tp_train+fp_train);
sensitivity = tp_train/(tp_train+fn_train);
f1_score    = 2/(1/sensitivity+1/precision);

disp('<strong>Train data Event triggered results</strong>')
disp(['train feature matrix dim: ', num2str(size(X_train))])
disp(['train labels dim: '        , num2str(size(Y_train))])
disp(['train false negative: '    , num2str(fn_train)     ])
disp(['train false positive: '    , num2str(fp_train)     ])
disp(['train precision: '         , num2str(precision)    ])
disp(['train sensitivity: '       , num2str(sensitivity)  ])
disp(['train f1_score: '          , num2str(f1_score)     ])
disp(' ')

% TEST FEATURES EXTRACTION %
if not(exist('X_test'))
    [X_test, Y_test, tp_test , fn_test, fp_test] = event_triggered_feature_extraction(test_folder_path); 
    
    save('Test_feature_extraction_data.mat', 'X_test', 'Y_test', 'tp_test' , 'fn_test', 'fp_test')
end

precision   = tp_test/(tp_test+fp_test);
sensitivity = tp_test/(tp_test+fn_test);
f1_score    = 2/(1/sensitivity+1/precision);

disp('<strong>Test data Event triggered results</strong>')
disp(['test feature matrix dim: ', num2str(size(X_test))])
disp(['test labels dim: '        , num2str(size(Y_test))])
disp(['test false negative: '    , num2str(fn_test)     ]) 
disp(['test false positive: '    , num2str(fp_test)     ])
disp(['test precision: '         , num2str(precision)   ])
disp(['test sensitivity: '       , num2str(sensitivity) ])
disp(['test f1_score: '          , num2str(f1_score)    ])
disp(' ')

%% Features vetting
% vff_max  - feature-feature maximum correlation value
% vff_mean - feature-feature average correlation value
% vft_max  - feature-target maximum Relieff value
% vft_mean - feature-target average Relieff value
plot_heatmap = 1;

% ### BEFORE FEATURES VETTING ### %
[vff_max, vff_mean, vft_max, vft_mean] = before_features_vetting_fit(X_train, Y_train, plot_heatmap); 
% return stats of scores (for monitoring) before you apply features vetting
% procedure on more then 40 features.

disp('<strong>Train Prior to feature vetting</strong>')
disp(['train prior to features vetting feature-feature max: '    , num2str(vff_max) ])
disp(['train prior to features vetting feature-feature average: ', num2str(vff_mean)])
disp(['train prior to features vetting feature-target max: '     , num2str(vft_max) ])
disp(['train prior to features vetting feature-target average: ' , num2str(vft_mean)])
disp(' ')

% ### AFTER FEATURES VETTING TRAIN ### %
if not(exist('Xv_train'))
    % perform features vetting
    [Xv_train, vff_max_train, vff_mean_train, vft_max_train, vft_mean_train, I] = features_vetting_fit(X_train, Y_train, plot_heatmap);
    
    save('Train_feature_vetting_data.mat', 'Xv_train', 'vff_max_train', 'vff_mean_train', 'vft_max_train', 'vft_mean_train', 'I')
end

disp('<strong>Train After feature vetting</strong>')
disp(['train features vetting feature-feature max: '    , num2str(vff_max_train) ])
disp(['train features vetting feature-feature average: ', num2str(vff_mean_train)])
disp(['train features vetting feature-target max: '     , num2str(vft_max_train) ])
disp(['train features vetting feature-target average: ' , num2str(vft_mean_train)])
disp(' ')

% ### AFTER FEATURES VETTING TEST ### %
if not(exist('Xv_test'))
    % apply features vetting manualy on test dataset
    [Xv_test, vff_max_test, vff_mean_test, vft_max_test, vft_mean_test] = features_vetting_transform(X_test, Y_test, I, plot_heatmap); 

    save('Test_feature_vetting_data.mat', 'Xv_test', 'vff_max_test', 'vff_mean_test', 'vft_max_test', 'vft_mean_test')
end

disp('<strong>Test After feature vetting</strong>')
disp(['test features vetting feature-feature max: '    , num2str(vff_max_test) ])
disp(['test features vetting feature-feature average: ', num2str(vff_mean_test)])
disp(['test features vetting feature-target max: '     , num2str(vft_max_test) ])
disp(['test features vetting feature-target average: ' , num2str(vft_mean_test)])
disp(' ')

%% Features selection
% Return the following:
% n_combinations - number of combinations
% nft_max        - combinations maximum value
% mft_mean       - combinations average value
% mft_std        - combinations std value
% best_comb      - best combination in any format 

if not(exist('Xs_train'))
    [Xs_train, n_combinations, nft_max, nft_mean, nft_std, best_comb] = features_selection_fit(Xv_train, Y_train);

    save('Train_feature_selection_data.mat', 'Xs_train', 'n_combinations', 'nft_max', 'nft_mean', 'nft_std', 'best_comb')
end

disp('<strong>Train Features selection After feature vetting</strong>')
disp(['train features selection combinations: '          , num2str(n_combinations)])
disp(['train features selection feature-target max: '    , num2str(nft_max)       ])
disp(['train features selection feature-target average: ', num2str(nft_mean)      ])
disp(['train features selection feature-target std: '    , num2str(nft_std)       ])
disp(['best combination: '                               , num2str(best_comb)     ])
disp(['best combination (global): '                      , num2str(I(best_comb')')])
disp(' ');

if not(exist('Xs_test'))
    [Xs_test, MI] = features_selection_transform(Xv_test, Y_test, best_comb); 
    
    save('Test_feature_selection_data.mat', 'Xs_test', 'MI')
end

disp('<strong>Test Features selection After feature vetting</strong>'  )
disp(['test features selection feature-target MI: '      , num2str(MI)])
disp(' ')

%% Random Forest Classification 
% accuracy_vs_n_trees - accuracy vector of accuracy vs. number of trees 
% sensitivity_arr     - sensitivity per class 
% example             - sensitivity_arr = [0.66 for class 1 , ... , 0.59 for class 5]
% precision_arr       - precision per class 
% f1_score_arr        - f1_score per class 
% auc_arr_arr         - auc_arr per class

[accuracy_vs_n_trees, sensitivity_arr, precision_arr, f1_score_arr, train_auc_arr, test_auc_arr] = ...
    RF_classification(Xs_test, Y_test, Xs_train, Y_train); 

disp('<strong>Random Forest Classification</strong>'  )
disp(['accuracy vs. number of trees - accuracy vector: ', num2str(accuracy_vs_n_trees)  ])
disp(['sensitivity per class: '                         , num2str(sensitivity_arr)      ])
disp(['average sensitivity : '                          , num2str(mean(sensitivity_arr))])
disp(['precision per class: '                           , num2str(precision_arr)        ])
disp(['average precision : '                            , num2str(mean(precision_arr))  ])
disp(['f1 per class: '                                  , num2str(f1_score_arr)         ])
disp(['average f1 : '                                   , num2str(mean(f1_score_arr))   ])
disp(['train auc per class: '                           , num2str(train_auc_arr)        ])
disp(['average train auc : '                            , num2str(mean(train_auc_arr))  ])
disp(['test auc per class: '                            , num2str(test_auc_arr)         ])
disp(['average test auc : '                             , num2str(mean(test_auc_arr))   ])




