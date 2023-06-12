function [Xs_test, MI] = features_selection_transform(Xv_test, Y_test, best_comb)
    if nargin ~= 3           % Set default flag (In case the function did not recieved flag as input).
        best_comb = [ 1     4     6     7     8     9    10    15    16    20];
    end

    k = size(best_comb,2);
    
    d_Xv_test = zeros(size(Xv_test,1),k);
    for r = 1:k
        [d_Xv_test(:,r),~] = discretize(Xv_test(:,best_comb(r)),3);
    end
    
    MI      = mutual_information(d_Xv_test,Y_test);
    Xs_test = Xv_test(:,best_comb);
end