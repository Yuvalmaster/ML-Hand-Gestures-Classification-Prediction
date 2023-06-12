function [vff_max, vff_mean, vft_max, vft_mean] = before_features_vetting_fit(X_train, Y_train, plot_heatmap)
    if nargin ~= 3            % Set default flag (In case the function did not recieved flag as input).
        plot_heatmap = 1;
    end

    %% Normalize features matrix
    X_train = normalize(X_train,'scale');
 
    %% feature-feature correlation
    rff_Spearman = corr(X_train,'type','Spearman');
    if plot_heatmap
        figure; heatmap(abs(rff_Spearman));title({'Spearman correlation - Heatmap','train dataset before feature vetting'})
    end

    
    vff_max  = max(rff_Spearman(rff_Spearman<1));
    vff_mean = mean(mean(rff_Spearman));
    
    %% feature-label correlation
    len = size(X_train,2);
    W   = zeros(len,1);
    for j = 1:len
        [~,W(j)] = relieff(X_train(:,j),Y_train,10);
    end
    vft_max  = max(W);
    vft_mean = mean(W);



end