function [code_dir, data_dir] = find_folders(mainpath)
    if nargin ~= 1
        code_dir = pwd;                     % Code's current location
    else
        code_dir = mainpath;
    end

    idcs       = strfind(code_dir, '\');
    parent_dir = code_dir(1:idcs(end)-1);  % Parent folder
    data_dir   = [parent_dir '\data'];     % Data folder

end

