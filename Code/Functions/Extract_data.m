function [data_files_name, Data_lib] = Extract_data(data_dir)
%% FILE NAMES EXTRACTION
    d_files = dir(data_dir);
    files   = {d_files.name};
    
    % Extract Files names
    h = waitbar(0,'Loading Data - Please wait');
    Acc_files = {}; Gyro_files = {}; Label_files = {};
    for i=1:length(files)

       if contains(files(i),'Gyro')
           Gyro_files  = [Gyro_files   ; files{i}];

       elseif contains(files(i),'Acc')
           Acc_files   = [Acc_files    ; files{i}];

       elseif contains(files(i),'Label')
           Label_files = [Label_files  ; files{i}];

       end
       waitbar(i / size(length(files),1))
    end
    close(h)

    % Data Table of Files names
    data_files_name = table(Acc_files,Gyro_files,Label_files);
    
%% DATA EXTRACTION
    % Extract data from each file
    h = waitbar(0,'Extracting Data - Please wait');
    Acc_data = {}; Gyro_data = {}; Label_data = {};
    for i=1:size(data_files_name,1)

        Data_A = importdata([data_dir  '\'  data_files_name.Acc_files{i,:}]);
        Data_G = importdata([data_dir  '\'  data_files_name.Gyro_files{i,:}]);
        Data_L = xlsread(   [data_dir  '\'  data_files_name.Label_files{i,:}]);

        % The following condition determine whether the Labels CSV file is
        % Right-To-Left instead of Left-To-Right as in the instructions.
        % Then, fixes the columns accordingly
        if mean(Data_L(:,1)-Data_L(:,2)) < 0
            Data_L = [Data_L(:,2), Data_L(:,1)];
            disp([data_files_name.Label_files{i,:}, ' is Right-To-Left!!!'])
            
        end

        Acc_data   = [Acc_data   ; Data_A.data];
        Gyro_data  = [Gyro_data  ; Data_G.data];
        Label_data = [Label_data ; Data_L];
        
        waitbar(i / size(data_files_name,1))
    end
    
    % Data Table for all sensors and recordings
    Data_lib = table(Acc_data,Gyro_data,Label_data);
    close(h)
end

