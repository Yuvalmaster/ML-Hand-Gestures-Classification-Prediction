function [features, features_headers] = Features_extraction(Gyro, ACC, Sample_rate_a, Sample_rate_g , Event_range_g, Event_range_a, a_factor)
%% Data interpolation
    % Set Signal within the event
    Gyro_ROI = Gyro(Event_range_g,:);
    ACC_ROI  = ACC(floor(Event_range_a./a_factor),:);
    
    % Derivative of signals
    der_Gyro = diff(Gyro_ROI(:,2:end)) ./ (1./Sample_rate_g);
    der_Acc  = diff(ACC_ROI(:,2:end))  ./ (1./Sample_rate_a);
    
    % Frequency spectrum signals
    if or(size(Gyro_ROI,1) <= 8,size(ACC_ROI,1) <= 8)     % In case the segment length is less than 8 pwelch requires smaller window
        if or(size(Gyro_ROI,1) == 1,size(ACC_ROI,1) == 1) % If the segment length is only one than it cannot calculate most of the features, thus will be NaN
            features         = NaN(1,84);
            features_headers = repmat({NaN(1,3)},1,25);
            return;
            
        else                                              % If the segment length is between 2 and 8 than window size shrink to 2
            [pxx_g, f_g] = pwelch(Gyro_ROI(:,2:end),2,[],[],Sample_rate_g);
            [pxx_a, f_a] = pwelch(ACC_ROI(:,2:end), 2,[],[],Sample_rate_a);
        end
    else                                                  % If the segment length is 8 and above, than the window size is defult==8
        [pxx_g, f_g] = pwelch(Gyro_ROI(:,2:end),[],[],[],Sample_rate_g);
        [pxx_a, f_a] = pwelch(ACC_ROI(:,2:end), [],[],[],Sample_rate_a);

    end

    % EMD
    [imf_Gyro,~] = emd(mean(Gyro(:,2:end)'),'MaxNumIMF',5);
    [imf_ACC, ~] = emd(mean(ACC(:,2:end)'),'MaxNumIMF',5);

%% Features
    % STDEV 3-axis
    STDEV_Gyro      = std(Gyro_ROI(:,2:end));
    STDEV_Acc       = std(ACC_ROI( :,2:end));
    STDEV_EMD_Gyro  = std(imf_Gyro);
    STDEV_EMD_ACC   = std(imf_ACC);

    % Signal energy
    Sig_Energy_Gyro = sum((Gyro_ROI(:,2:end)).^2);
    Sig_Energy_Acc  = sum((ACC_ROI( :,2:end)).^2);
    EMD_Energy_Gyro = sum(imf_Gyro.^2);
    EMD_Energy_ACC  = sum(imf_ACC.^2);


    % Signal avg
    Sig_avg_Gyro = mean(Gyro_ROI(:,2:end));
    Sig_avg_Acc  = mean(ACC_ROI( :,2:end));
    EMD_avg_Gyro = mean(imf_Gyro);
    EMD_avg_ACC  = mean(imf_ACC);

    % Derivative min & max
    Derivative_min_Gyro = min(der_Gyro,[],1);
    Derivative_max_Gyro = max(der_Gyro,[],1);
    Derivative_min_Acc  = min(der_Acc, [],1);
    Derivative_max_Acc  = max(der_Acc, [],1);

    % Frequency max
    Freq_max_Gyro = [min(f_g(pow2db(pxx_g(:,1))==max(pow2db(pxx_g(:,1)))))
                     min(f_g(pow2db(pxx_g(:,2))==max(pow2db(pxx_g(:,2)))))
                     min(f_g(pow2db(pxx_g(:,3))==max(pow2db(pxx_g(:,3)))))]';
    Freq_max_Acc =  [min(f_a(pow2db(pxx_a(:,1))==max(pow2db(pxx_a(:,1)))))
                     min(f_a(pow2db(pxx_a(:,2))==max(pow2db(pxx_a(:,2)))))
                     min(f_a(pow2db(pxx_a(:,3))==max(pow2db(pxx_a(:,3)))))]';

    % frequency domain max energy [dB]
    dB_max_Gyro = max(pow2db(pxx_g));
    dB_max_Acc  = max(pow2db(pxx_a));
    dB_min_Gyro = min(pow2db(pxx_g));
    dB_min_Acc  = min(pow2db(pxx_a));
    if max(max(isinf(dB_min_Acc)))
        dB_min_Acc  = -70;
    end
    if max(max(isinf(dB_min_Gyro)))
        dB_min_Gyro = -70;
    end

    dB_range_g = dB_max_Gyro - dB_min_Gyro;
    dB_range_a = dB_max_Acc  - dB_min_Acc;
    kf_Gyro    = dB_range_g - 3;  % Knee frequency for each axis
    kf_Acc     = dB_range_a - 3;  % Knee frequency for each axis
    
    dominant_freq_range_start_Gyro  = zeros(1,3);
    dominant_freq_range_end_Gyro    = zeros(1,3);
    dominant_freq_range_start_Acc   = zeros(1,3);
    dominant_freq_range_end_Acc     = zeros(1,3);
    Freq_ROI_Length_Normalized_Gyro = zeros(1,3);
    Freq_ROI_Length_Normalized_ACC  = zeros(1,3);
    
    for i = 1:3 % For x,y,z axis
        [event_start, event_end, ~]        = Find_ROI([f_g, pow2db(pxx_g(:,i))],abs(kf_Gyro(i)/dB_range_g(i)),2,[],0,0);
        dominant_freq_range_start_Gyro(i)  = f_g(event_start(1));
        dominant_freq_range_end_Gyro(i)    = f_a(event_end(1));
        Freq_ROI_Length_Normalized_Gyro(i) = length(f_g(event_start(1):event_end(1)))/length(f_g);

        
        [event_start, event_end, ~]       = Find_ROI([f_a, pow2db(pxx_a(:,i))],abs(kf_Acc(i)/dB_range_a(i)),2,[],0,0);
        dominant_freq_range_start_Acc(i)  = f_g(event_start(1));
        dominant_freq_range_end_Acc(i)    = f_a(event_end(1));
        Freq_ROI_Length_Normalized_ACC(i) = length(f_a(event_start(1):event_end(1)))/length(f_g);
    end
    

%% Extracted features
    features        = [STDEV_Gyro,            STDEV_Acc         ...
                      Sig_Energy_Gyro,       Sig_Energy_Acc    ...
                      Sig_avg_Gyro,          Sig_avg_Acc       ...
                      Derivative_min_Gyro,   Derivative_min_Acc...
                      Derivative_max_Gyro,   Derivative_max_Acc...
                      Freq_max_Gyro,         Freq_max_Acc      ...
                      dB_max_Gyro,           dB_max_Acc,       ...
                      dominant_freq_range_start_Gyro, dominant_freq_range_start_Acc,...
                      dominant_freq_range_end_Gyro, dominant_freq_range_end_Acc,...
                      Freq_ROI_Length_Normalized_Gyro, Freq_ROI_Length_Normalized_ACC,...
                      STDEV_EMD_Gyro,        STDEV_EMD_ACC,...
                      EMD_Energy_Gyro,       EMD_Energy_ACC,...
                      EMD_avg_Gyro,          EMD_avg_ACC];
    
    features_headers = table(...
                      STDEV_Gyro,            STDEV_Acc,         ...
                      Sig_Energy_Gyro,       Sig_Energy_Acc,    ...
                      Sig_avg_Gyro,          Sig_avg_Acc,       ...
                      Derivative_min_Gyro,   Derivative_min_Acc,...
                      Derivative_max_Gyro,   Derivative_max_Acc,...
                      Freq_max_Gyro,         Freq_max_Acc,      ...
                      dB_max_Gyro,           dB_max_Acc,       ...
                      dominant_freq_range_start_Gyro, dominant_freq_range_start_Acc,...
                      dominant_freq_range_end_Gyro, dominant_freq_range_end_Acc, ...
                      Freq_ROI_Length_Normalized_Gyro, Freq_ROI_Length_Normalized_ACC,...
                      STDEV_EMD_Gyro,        STDEV_EMD_ACC,...
                      EMD_Energy_Gyro,       EMD_Energy_ACC,...
                      EMD_avg_Gyro,          EMD_avg_ACC);
end

