function stiminfo = dm_stiminfo()
% dm_stiminfo() extracts stimulus information from wavefiles in the stimulus
% directory. It also creates a downsampled .mat audiofile to be used in
% dm_audiodelay() and dm_broadbandenvelope();
%
%
%   USE AS:
%   [info, fnames] = dm_stiminfo();
%
%   OUTPUTS
%   info           = struct, fields giving information extracted by 
%                    audioinfo.m
%   fnames         = cell array of strings, individual wave filenames
%



d            = dm_dir;
dirfiles     = dir(d.stim);
stiminfoname = fullfile(d.stim, 'stiminfo.mat'); 

if exist(stiminfoname, 'file')
    load(stiminfoname)
else % Create it
    fprintf('Creating stiminfo .mat file.../n');
    
    iswavefile = cellfun(@(x) regexp(x, '\d\d_\d.wav'), {dirfiles.name}', 'UniformOutput', 0);
    iswavefile = ~cellfun('isempty', iswavefile);

    wavefiles   = dirfiles(iswavefile);
    fnames      = {wavefiles.name}';

    stiminfo.names      = {wavefiles.name}';
    stiminfo.audiofiles = fullfile({wavefiles.folder}', {wavefiles.name}');

    stiminfo.ses          = cell(numel(wavefiles), 1);
    stiminfo.duration     = zeros(numel(wavefiles), 1);
    stiminfo.fs           = zeros(numel(wavefiles), 1);
    stiminfo.totalSamples = zeros(numel(wavefiles), 1);

        for k = 1:numel(stiminfo.names)

            tmp                  = audioinfo(stiminfo.audiofiles{k});

            stiminfo.storynr(k)      = str2double(stiminfo.names{k}(1:2));
            stiminfo.seslabel{k}     = sprintf('ses-%03d', stiminfo.storynr(k));
            stiminfo.section(k)      = str2double(stiminfo.names{k}(4));
            stiminfo.duration(k)     = tmp.Duration;
            stiminfo.fs(k)           = tmp.SampleRate;
            stiminfo.totalSamples(k) = tmp.TotalSamples;

            audiofile = strsplit(stiminfo.audiofiles{k}, 'wav');
            matfile   = [audiofile{1} 'mat'];
            if ~exist(matfile, 'file')
                fprintf('Creating .mat from %s.../n', wavefiles(k).name);
                audio = dm_wav2mat(stiminfo.audiofiles{k});
                save(matfile, 'audio');
            else
                load(matfile)
            end

        end
     
     % Save it
     save(stiminfoname, 'stiminfo');
    
end