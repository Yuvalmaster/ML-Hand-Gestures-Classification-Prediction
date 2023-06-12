function [X, Y ,tp , fn, fp, tn, Tot_labels, Tot_labels_no_ab, ab_label_detected, ab_label_undetected, ab_label_in_segment, features_table] = event_triggered_feature_extraction(mainpath, Plot_flag,Notify_FP_flag, Notify_FN_flag )
%% Data Loading
if strcmp(mainpath, pwd)
    [~, data_dir] = find_folders(mainpath);
    [data_files_name, Data_lib] = Extract_data(data_dir);
else
    [data_files_name, Data_lib] = Extract_data(mainpath);
end
    
%% Global constants & variables & preallocations
    if nargin ~= 4            % Set default flags (In case the function did not recieved flags as input).
        Plot_flag      = 0;   % Rise flag to visualize segmentation on graphs (Raise flag - 1, Drop flag - 0)
        Notify_FP_flag = 0;   % Rise flag to notify where FP occured          (Raise flag - 1, Drop flag - 0)
        Notify_FN_flag = 1;   % Rise flag to notify where FN occured          (Raise flag - 1, Drop flag - 0)
    end
    
    %{ 
    The bias adds (in [sec]) to the length of the event range time to 
    compensate for the manual label positioning deviation (prevents 
    incorrect false negative when the event was correctly detected due to
    manual labeling and rounding timing). Rather than increasing the 
    window size, which will result in less accurate features extraction
    for each event (due to including too much silence between events), 
    the bias will allow for better TP TN detection while keeping the 
    window size smaller. 
    %}
    
    bias        = 10; 
    thresh      = 0.10;      % Threshold for event detection (0 < thresh < 1)
    Sample_rate = 25;        % [Hz]
    
    tp=0; fn=0; fp=0; tn=0; 
    
    ab_label_detected   = 0; % Labels 6 detected
    ab_label_undetected = 0; % Labels 6 undetected
    ab_label_in_segment = 0; % Labels 6 that are within a vaild segment for label 1-5
    Tot_labels          = 0; % Count total labels in dataset
    Tot_labels_no_ab    = 0; % Count total labels WITHOUT LABEL 6 in dataset 
    
    X = [];                  % Feature matrix
    Y = [];                  % labels matrix
    features_table = [];     % Feature table (/w headers)

%% Event Triggered Segmentation & Features extraction 
    h = waitbar(0,'Segmenting Data & Extracting Features - Please wait');
    
    for indx = 1:size(Data_lib,1)
        %%% ------------ Sensors & Labels data ------------- %%%
        ACC    = Data_lib.Acc_data{indx};   % Accelerometer data of recording i
        Gyro   = Data_lib.Gyro_data{indx};  % Gyroscope data of recording i
        Labels = Data_lib.Label_data{indx}; % Labels of recording i

        Tot_labels       = Tot_labels + size(Labels,1);
        Tot_labels_no_ab = Tot_labels_no_ab + sum((Labels(:,2)~=6)==1);
        
        %%% ------- Test differences in sample rate ------- %%%
        [Sample_rate_a, Sample_rate_g, a_factor, drop_flag] = Test_sample_rate(ACC, Gyro, Sample_rate, data_files_name.Gyro_files{indx});
        % Detect broken recordings with inaccurate timing or sampling frequencies that can affect the model.
        if drop_flag 
            continue
        end
        
        %%% ----------- Event-based segmentation ---------- %%%
        window_size = Sample_rate_g*(Sample_rate_g/3);              % window size segmentation detection (currently set to 8.33 [sec])
        
        [Events_start, Events_end, ROIs_loc] = ...                  % ROIs_loc for internal testing
        Find_ROI(Gyro, thresh, window_size, Sample_rate_g, 1, 1);
            
        num_of_events    = size(Events_start,1);                    % Count the number of detected events in recording i
   
        %%% ------------- Events range & time ------------- %%%    
        features = []; features_headers = table(); labels_vec = [];
        for event = 1:num_of_events
            % Found Event range & time
            Event_range_g      = Events_start(event):Events_end(event);
            Event_range_time_g = floor(Gyro(Events_start(event),1)-bias):round(Gyro(Events_end(event),1));
            
            event_start_a      = floor(Events_start(event)./a_factor);
            event_end_a        = floor(Events_end(event)./a_factor);
            
            if size(ACC,1) < event_end_a % In case the event found in gyroscope ends after the accelerometer, this will adjust the timing accordingly
                event_end_a    = size(ACC,1);
            end
            
            Event_range_a      = event_start_a:event_end_a;

            % between events range & time
            if event == num_of_events
                between_events_g_time = round(Gyro(Events_end(event),1)):round(Gyro(end,1));
                between_events_a_time = round(ACC(event_end_a,1)):round(ACC(end,1));
            
            else
                between_events_g_time = round(Gyro(Events_end(event),1)):floor(Gyro(Events_start(event+1),1)-bias);
                between_events_a_time = round(ACC(event_end_a,1)):floor(ACC(floor(Events_start(event+1)./a_factor),1)-bias);
            end
            
            %%% ------- Features extraction within events ----- %%%           
            [features(event,:), features_headers(event,:)] = Features_extraction(Gyro, ACC, Sample_rate_a, Sample_rate_g , Event_range_g, Event_range_a, a_factor);
     
            %%% --------- TP, TN, FP, FN within events -------- %%%       
            tp_check = ismember(round(Labels(:,1)),Event_range_time_g); % Checks whether the segment has labels within it - In addition, I rounded the time column in case the time data is not with rounded numbers (seconds)
            
            % If ONLY one label is within the segment
            if sum(tp_check==1) == 1                              
                tp                = tp + 1;
                label             = Labels(tp_check==1,2);
                ab_label_detected = ab_label_detected  + sum(Labels(tp_check==1,2) == 6);  % In case it's label 6
                       
            % No label detected
            elseif sum(tp_check==1) == 0  
                fp    = fp + 1;
                label = 0;
                if Notify_FP_flag
                    disp(['False Segment (Segment ',num2str(event) ,...
                        ') in recording No. ', erase(data_files_name.Gyro_files{indx},'.Gyro.csv')])
                end
            
            % More than one label in segment    
            else
                label               = Labels(tp_check==1,2);
                label               = label(1);                                            % The first label that was detected
                ab_label_in_segment = ab_label_in_segment + sum(Labels(tp_check==1,2)==6); % Count how many label 6 in the segment
                if sum(Labels(tp_check==1,2)~=6) < 2                                       % Found several label 6 only (no 1-5) or found one label 1-5 and the rest are label 6s
                    tp = tp + 1;
                
                elseif sum(Labels(tp_check==1,2)~=6) > 1    
                    fn = fn + sum(Labels(tp_check==1,2)~=6)-1;                             % Count the number of non label 6 in segment as FN
                    if Notify_FN_flag
                        disp(['missed label 1-5 (in segment ',num2str(event) ,...
                            ') in recording No. ', erase(data_files_name.Gyro_files{indx},'.Gyro.csv')])
                    end
                end
            end
            
            labels_vec(event,1) = label;

            %%% ----- TN, FN, TP, FP between events ----- %%%
            if event == 1 % Add search for missing labels before the first segment
                if (Gyro(Events_start(event),1)-bias) <= 0 || (ACC(event_start_a,1)-bias) <= 0
                    continue
                else
                    between_events_a_time = [ACC(1,1):(ACC(event_start_a,1)-bias),         between_events_a_time];
                    between_events_g_time = [Gyro(1,1):(Gyro(Events_start(event),1)-bias), between_events_g_time];
                end

            end

            if length(between_events_g_time) <= length(between_events_a_time)
                tn_check = ismember(round(Labels(:,1)),between_events_a_time); % Checks if between segments there are labels has labels within it - In addition, I rounded the time column in case the time data is not with rounded numbers (seconds)
            else
                tn_check = ismember(round(Labels(:,1)),between_events_g_time); % Checks if between segments there are labels has labels within it - In addition, I rounded the time column in case the time data is not with rounded numbers (seconds)
            end
            
            % No label detected
            if sum(tn_check==1) == 0
                continue
            
            % If there is a label in between segments
            elseif sum(tn_check==1) ~= 0
                ab_label_undetected = ab_label_undetected + sum(Labels(tn_check==1,2)==6);
                if sum(Labels(tn_check==1,2)~=6) ~=0
                    fn = fn + sum(Labels(tn_check==1,2)~=6);
                    if Notify_FN_flag
                        disp(['missed label/s ',num2str((Labels(tn_check==1,2))'),...
                            ' (after segment ',num2str(event) ,') in recording No. ', erase(data_files_name.Gyro_files{indx},'.Gyro.csv')])
                    end
                end
            end

        end
        
        % Update Label and features matrices 
        X              = [X; features];
        Y              = [Y; labels_vec];
        features_table = [features_table; features_headers];
        
        % Plot data - ONLY WHEN Plot_flag == 1
        if Plot_flag % Rise flag to visualize segmentation on graphs
            Plot_data(Gyro,     ACC,     Labels, ...
                      Events_start, Events_end, ...
                      indx,    data_files_name, a_factor)
        end
        waitbar(indx / size(Data_lib,1))
    
    end
    features_table = [table(Y,'VariableNames',{'Label'}) features_table];
    close(h)
end    


