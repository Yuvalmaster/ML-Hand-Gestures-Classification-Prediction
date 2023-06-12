function  Plot_data(Gyro, ACC, Label, Events_start, Events_end, i, data_files_name, a_factor)
    %% Plot Gyroscope Data
    figure; sgtitle(append('Recording No. ', ...
                  erase(data_files_name.Gyro_files{i},'.Gyro.csv')))
    
    subplot(2,1,1); hold on
    plot(Gyro(:,1),Gyro(:,2)); % X-Axis
    plot(Gyro(:,1),Gyro(:,3)); % Y-Axis
    plot(Gyro(:,1),Gyro(:,4)); % Z-Axis
    scatter(Label((Label(:,2) == 6),1),0,100,'x','red','linewidth',2); % Abnormal labels
    scatter(Label((Label(:,2) ~= 6),1),0,    'o',      'linewidth',2); % Regular labels
    xline(Gyro(Events_start,1)); xline(Gyro(Events_end,1));

    title(append('Gyroscope data: Recording No. ', ...
                  erase(data_files_name.Gyro_files{i},'.Gyro.csv')))
    
    xlabel('Time [Sec]'); ylabel('Speed [Deg/Sec]'); 
    legend('X axis','Y axis','Z axis');  grid('on');
    hold off

    %% Plot Accelerometer Data
    subplot(2,1,2); hold on 
    plot(ACC(:,1),ACC(:,2));   % X-Axis
    plot(ACC(:,1),ACC(:,3));   % Y-Axis
    plot(ACC(:,1),ACC(:,4));   % Z-Axis
    scatter(Label((Label(:,2) == 6),1),0,100,'x','red','linewidth',2); % Abnormal labels
    scatter(Label((Label(:,2) ~= 6),1),0,    'o',      'LineWidth',2); % Regular labels
    
    Event_start_a = floor(Events_start./a_factor);
    Event_end_a   = floor(Events_end./a_factor);

    if Event_end_a(end) > size(ACC,1)
        Event_end_a(end) = size(ACC,1);
    end
    if Event_start_a(end) > size(ACC,1)
        Event_start_a(end) = size(ACC,1);
    end

    xline(ACC(Event_start_a,1)); xline(ACC(Event_end_a,1));

    title(append('Accelerometer data: Recording No. ', ...
                  erase(data_files_name.Acc_files{i},'.Acc.csv')))
    
    xlabel('Time [Sec]'); ylabel('Acceleration [g]'); 
    legend('X axis','Y axis','Z axis');   grid('on');
    hold off
end

