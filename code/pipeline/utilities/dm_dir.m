function dirs = dm_dir(home)

if ~exist('home', 'var')
    dirs.home = '/project/3011085.05/';
else
    dirs.home = home;
end

dirs.data         = fullfile(dirs.home, 'data');
dirs.src          = fullfile(dirs.home, 'src');

% data paths
dirs.raw       = fullfile(dirs.data, 'raw');
dirs.derived   = fullfile(dirs.data, 'derived');
dirs.results   = fullfile(dirs.data, 'interim');
dirs.converted = fullfile(dirs.data, 'converted');

dirs.atlas = {'/project/3011085.05/data/atlas/atlas_subparc374_8k.mat';
             '/project/3011085.05/data/atlas/atlas_MSMAll_8k_subparc.mat';
             '/project/3011085.05/data/atlas/cortex_inflated_shifted.mat';
             '/project/3011085.05/data/atlas/cortex_inflated.mat'};

% stimuli & logfiles
dirs.lab          = fullfile(dirs.home, 'lab');
dirs.stim         = fullfile(dirs.lab, 'stim');
dirs.logs         = fullfile(dirs.lab, 'log');


end
