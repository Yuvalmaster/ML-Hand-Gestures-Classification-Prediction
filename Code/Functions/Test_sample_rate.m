function [Sample_rate_a, Sample_rate_g, a_factor, drop_flag] = Test_sample_rate(ACC, Gyro, Sample_rate, data_files_name)
   % IN CASE THE SAMPLE RATE IS SEVERELY NOT SYNCRONIZED BETWEEN BOTH THE
   % ACCELEROMENTER ANND THE GYROSCOPE SIGNALS THE ALGORITHM WILL FAIL,
   % THEREFORE THE FOLLOWING FUNCTION TESTS THE SAMPLE RATE FOR BOTH SENSORS
   % AND ADJUST.
    Fs_acc    = 1./mean(diff(ACC(:,1)));   % Avg sample rate of the recording
    Fs_gyro   = 1./mean(diff(Gyro(:,1)));  % Avg sample rate of the recording
    a_factor  = 1;                         % Factor to compensate if sample rates do not match
    drop_flag = 0;                         % Flag to drop a bad recording 
    
    if abs(diff([Sample_rate Fs_acc])) > 1 || abs(diff([Sample_rate Fs_gyro])) > 1
        Sample_rate_a = Fs_acc;
        Sample_rate_g = Fs_gyro;
        
        if abs(diff([diff([Sample_rate Fs_gyro]) diff([Sample_rate Fs_acc])])) > 2
            a_factor = Sample_rate_g/Sample_rate_a; % This factor is crucial to have consistent timing between both sensors
            disp(['Data sample rate is not equal between gyroscope and accelerometer in recording No. ', ...
                  erase(data_files_name,'.Gyro.csv')])
        end
        
        if Fs_gyro/Fs_acc > 100 || Fs_acc/Fs_gyro < 1/100
            disp(['The Recording No. ',erase(data_files_name,'.Gyro.csv'), ' is broken: Sample rates difference between Gyroscope and Accelerometer is bigger than 100 times - Droping this recording from data set'])
            drop_flag = 1;
        end

    
    else % If the delta from the global sample rate is less than 1, then the sample rate remains as the global (25[Hz])
        Sample_rate_a = Sample_rate;
        Sample_rate_g = Sample_rate;
    end
end

