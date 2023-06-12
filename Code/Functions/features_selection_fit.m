function [Xs_train, n_combinations, nft_max, nft_mean, nft_std, best_comb] = features_selection_fit(Xv_train, Y_train)
    tic
    %% Set number of combinations
    k              = 10;                        % Number of final features
    len            = size(Xv_train,2);          % Number of current features
    combinations   = 1:len;                     
    combinations   = nchoosek(combinations,k);  % Number of k current features combinations
    n_combinations = size(combinations,1);      % Number of combinations

    nft            = zeros(n_combinations,1);
    
    %% Run combinations
    h = waitbar(0,'Run Exhustive Search - Please wait');
    for i=1:n_combinations
        d_Xv_train = zeros(size(Xv_train,1),k);
        for r = 1:k
            [d_Xv_train(:,r),~] = discretize(Xv_train(:,combinations(i,r)),3);
        end
        
        MI = mutual_information(d_Xv_train,Y_train);
        nft(i) = MI;

    waitbar(i / n_combinations, h, sprintf('Run Exhustive Search - Progress: %d %%', floor(i/n_combinations*100)))

    end
    
    [nft_max, max_comb_num] = max(nft);
    nft_mean                = mean(nft);
    nft_std                 = std(nft);
    best_comb               = combinations(max_comb_num,:);
    Xs_train                = Xv_train(:,best_comb);

    close(h)
    toc
    disp(' ')
end