function [accuracy_vs_n_trees, sensitivity_arr, precision_arr, f1_score_arr, train_auc_arr, test_auc_arr] = RF_classification(Xs_test, Y_test, Xs_train, Y_train)
%% Set variables
    rng('default') % For reproducibility
    
    % Preallocations and variables
    num_trees_range     = linspace(10,100,10);
    accuracy_vs_n_trees = zeros(1, numel(num_trees_range));
    models_list{1,10}   = [];
    tab                 = tabulate(Y_train);
    
    disp('<strong>RF_Classification function plots:</strong>');

%% Loop through each number of trees in the range
    h = waitbar(0,'Searching for optimal number of trees: ');
    
    for i = 1:numel(num_trees_range)
        % Choose number of trees
        num_trees = num_trees_range(i);
        waitbar(i/numel(num_trees_range) , h, sprintf('Searching for optimal number of trees:\n Currently testing %d trees', num_trees))

        % Create model
        t     = templateTree('MaxNumSplits', 70 ,'NumVariablesToSample','all');% NumVariablesToSample - setup for random forest.
        model = fitcensemble(Xs_train,Y_train               ,...
                            'NumBins'           , 10        ,...
                            'Method'            , 'bag'     ,...
                            'NumLearningCycles' , num_trees ,...
                            'Learners'          , t         );
        
        % Cross validate model on Train data & Predictions
        CVMdl                    = crossval(model);
        y_pred                   = kfoldPredict(CVMdl);
        accuracy_vs_n_trees(1,i) = 100 .* sum(Y_train == y_pred)/numel(Y_train);
        models_list{i}           = model;
    end
    close(h)

%% Choose number of trees    
    % Plot Accuracy vs. Number of Trees on Train Set
    figure; plot(num_trees_range, accuracy_vs_n_trees,'-o')
    xlabel('Number of trees'); ylabel('Accuracy [%]'); title('Accuracy vs. Number of Trees on Train Set')

    % Choose optimal Model based on elbow method
    idx               = 7; % According to accuracy plot 
    optimal_num_trees = num_trees_range(idx);
    optimal_model     = models_list{idx}; 
    fprintf('Optimal Number of trees: %.0f\n',optimal_num_trees);

    % Predict Optimal model on Train Set
    [y_pred_train, score_train] = predict(optimal_model, Xs_train);
    train_accuracy              = 100 .* sum(Y_train == y_pred_train)/numel(Y_train);
    fprintf('Train Accuracy with optimal model: %.2f\n',train_accuracy);

    % Predict Optimal model on Test Set
    [y_pred_test, score_test] = predict(optimal_model, Xs_test);
    test_accuracy             = 100 .* sum(Y_test == y_pred_test)/numel(Y_test);
    fprintf('Test Accuracy with optimal model: %.2f\n',test_accuracy); 

%% Calculate Sensitivity, Precision, F1 Score
    Conf_mat = confusionmat(Y_test, y_pred_test);
    
    % Initialize variables to store scores
    sensitivity_arr = zeros(1, size(tab,1)-2);
    precision_arr   = zeros(1, size(tab,1)-2);
    f1_score_arr    = zeros(1, size(tab,1)-2);
    
    % Loop through each class
    for i = 2:size(tab,1)-1
        % Calculate true positive rate (sensitivity)
        sensitivity_arr(1, i-1) = Conf_mat(i,i) / sum(Conf_mat(i,:));
        
        % Calculate positive predictive value (precision)
        precision_arr(1, i-1)   = Conf_mat(i,i) / sum(Conf_mat(:,i));
        
        % Calculate F1 score
        f1_score_arr(1, i-1)    = 2 * (precision_arr(i-1) * sensitivity_arr(i-1))...
                                    / (precision_arr(i-1) + sensitivity_arr(i-1));
    end

%% ROC & AUC
    % Calculate ROC & AUC on Train and Test Set for each class
    train_auc_arr = zeros(1, size(tab,1)-2);
    test_auc_arr  = zeros(1, size(tab,1)-2);
    for i=1:size(tab,1)-2
        % Train AUC & ROC
        [FPR_train, TPR_train, threshold_train, train_auc_arr(1, i)]  = perfcurve(Y_train, score_train(:,i+1), tab(i+1));

        % Plot Train ROC
        figure; plot3(FPR_train, TPR_train, threshold_train); set(gca,'CameraPosition',[0.5,0.5,10])
        line([0 1 0], [0 1 0], 'color', 'r'); 
        xlabel('FPR'); ylabel('TPR'); zlabel('Threshold'); xlim([0 1]); ylim([0 1])
        title(['Train ROC curve - Class No. ',num2str(tab(i+1,1)),' vs. rest'])
        
        ind_max_sensitivity = find(TPR_train == 1);
        fprintf('Threshold for operating point with maximum sensitivity - Class %d :\t',tab(i+1,1))
        fprintf('  %1.3f',threshold_train(ind_max_sensitivity(1)))

        % Test AUC & ROC
        [x_ROC_test, y_ROC_test, threshold_test, test_auc_arr(1, i)] = perfcurve(Y_test, score_test(:,i+1), tab(i+1));

        % Plot Test ROC
        figure; plot3(x_ROC_test,y_ROC_test,threshold_test); set(gca,'CameraPosition',[0.5,0.5,10])
        line([0 1 0], [0 1 0], 'color', 'r'); 
        xlabel('FPR'); ylabel('TPR'); zlabel('Threshold'); xlim([0 1]); ylim([0 1])
        title(['Test ROC curve - Class No. ',num2str(tab(i+1,1)),' vs. rest'])

        disp(' ')
    end
    disp(' ')
end
