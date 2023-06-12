function [Events_start,Events_end, ROIs_loc] = Find_ROI(Sig, thresh, window_size, Sample_rate_g, filt, Intensity)
%% Filtering
    if filt == 1                     % Filter flag is on
        if max(isnan(Sig(:,:))) ~= 0 % if signal is broken (NaN values) it will not go through the filter
            Sig_filtered = Sig;
        else
            % Filter signal - Frequency spectrum analysis shows that the
            % dominant frequencies of labels 1-5 are generally up to 1 [Hz]
            Sig_filtered = lowpass(Sig, 1, Sample_rate_g);
        end
    
    else                            % Filter flag is off
        Sig_filtered = Sig;         % Run without filter
    end
    
%% Signal manipulation
    if Intensity == 1               % Intensity flag is on - Calculate intensity over x,y,z axises
        I_sig = (Sig_filtered(:,2).^2+Sig_filtered(:,3).^2+Sig_filtered(:,4).^2).^0.5;
    
    else                            % Intensity flag is off
        I_sig = Sig_filtered(:,2:end);
    end
    
    % Moving average of the signal
    moving_avg = movmean(I_sig, window_size);        

%% Find ROIs
    if max(moving_avg)< 0
        ROIs_loc = find(moving_avg > max(moving_avg)/thresh);
    else
        ROIs_loc = find(moving_avg > max(moving_avg)*thresh);
    end
    
    % find starting and ending positions of events
    if length(ROIs_loc) == 1
        Events_start = ROIs_loc;
        Events_end   = ROIs_loc;
    else
        find_confines = diff([0, diff(ROIs_loc')==1 , 0]);
        if max(find_confines ~= 0) < 1
            Events_start = ROIs_loc(1);
            Events_end   = ROIs_loc(1);
        else
            Events_start  = ROIs_loc(find_confines > 0);    
            Events_end    = ROIs_loc(find_confines < 0);
        end
    end
end
