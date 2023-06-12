function [Xv_train, vff_max, vff_mean, vft_max, vft_mean, I] = features_vetting_fit(X_train, Y_train, plot_heatmap)
    if nargin ~= 3            % Set default flag (In case the function did not recieved flag as input).
        plot_heatmap = 1;
    end

    %% Normalize features matrix
    X_train = normalize(X_train,'scale');
 
    %% feature-feature correlation
    rff_Spearman = corr(X_train,'type','Spearman');

    % Find max correlation of features beetween other features
    max_feature_corr_vec = zeros(size(rff_Spearman,1),1);
    for i=1:size(rff_Spearman,1)-1
        vec = rff_Spearman(i+1:end,i);
        max_feature_corr_vec(i) = max(vec);
    end
    max_feature_corr_vec(end+1) = max(rff_Spearman(1:end-1,end));
    
    %% feature-label correlation
    len = size(X_train,2);
    W   = zeros(len,1);
    for j = 1:len
        [~,W(j)] = relieff(X_train(:,j),Y_train,10);
    end

    %% Features vetting
    num_features = 20;
    % Select only 20 best wighted features
    W(max_feature_corr_vec>=0.8) = -inf;
    [B_w, I] = maxk(W,num_features);
    I = I(B_w>0); % Remove features that are with negative weights

    if size(I,1) < num_features % compensate if I size is lower than num_features
        max_feature_corr_vec(max_feature_corr_vec>=0.8) = inf;
        max_feature_corr_vec(I) = inf;
        [B_rest, I_rest] = mink(max_feature_corr_vec, num_features-size(I,1)); 
        
        assert(max(B_rest) < 0.8,'one of the features with higher than 0.8 correlation. please check features matrix')
        I = [I; I_rest];
    end
    I = sort(I);
    disp('The 20 Chosen features are: ')
    disp(I')

    % Create new feature matrix & correlate
    Xv_train = X_train(:,I);

    % Plot spearman
    rff_Spearman = corr(Xv_train,'type','Spearman');
    if plot_heatmap
        figure; heatmap(abs(rff_Spearman));title({'Spearman correlation - Heatmap','train dataset after feature vetting'})
    end
    
    % Plot weights
    len = size(Xv_train,2);
    W   = zeros(len,1);
    for j = 1:len
        [~,W(j)] = relieff(Xv_train(:,j),Y_train,10);
    end
    vft_max  = max(W);
    vft_mean = mean(W);
    vff_max  = max(rff_Spearman(rff_Spearman<1));
    vff_mean = mean(rff_Spearman(rff_Spearman<1));


end