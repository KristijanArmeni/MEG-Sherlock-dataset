function datout = dm_resample(data, timeorig, fsample)
% dm_resample() performs resampling of the data where artifact periods were
% populated removed (via cfg.method = 'partial' in ft_rejectartifact)
%
% USE AS
% data_resampled = dm_resample(data, timeorig, fsample)
% 
% INPUTS
% data     = struct, FT-style struct with artifact periods removed
% timeorig = struct, the .time field of the data struct whose trial structure
%                    is to be recovered by inserting nans to artifact periods
% sfample  = integer, desired sampling rate of datout (used as cfg.resamplefs input to ft_resampledata)
% 
% OUTPUTS
% datout  = struct, FT-style output struct

% subtract the first time point, making all axes start with zero, for 
% faster computation in ft_resampledata

% subtract first time point for memory purposes
if fsample < data.fsample
    firsttimepoint = zeros(numel(data.trial), 1);
    for kk = 1:numel(data.trial)
        firsttimepoint(kk, 1) = data.time{kk}(1);
        data.time{kk}         = data.time{kk}-data.time{kk}(1);
    end

    % downsample to 300 Hz
    cfg            = [];
    cfg.demean     = 'no';
    cfg.detrend    = 'no';
    cfg.resamplefs = fsample;
    data           = ft_resampledata(cfg, data);   

    % Reconstruct the time axis
    for kk = 1:numel(data.trial)
        data.time{kk}  = data.time{kk} + firsttimepoint(kk);
    end
end
% recreate the data original structure with nans

starttime = timeorig{1}(1);
endtime = timeorig{end}(end);
datout = rmfield(data, {'trial', 'time', 'trialinfo'}); % chan-by-time matrix

datout.trial = {};
datout.time = {};
datout.trialinfo = [];

% loop through trials
trlids = unique(data.trialinfo(:, 1));
for j = 1:numel(trlids)

    %trlids = unique(data.trialinfo(:, 1));
    selind = find(data.trialinfo(:, 1) == trlids(j));
    
    starttime = timeorig{trlids(j)}(1);  % start time of this trial
    endtime = timeorig{trlids(j)}(end);  % end time of this trial
    
    % create the time axis at the resamplefs
    datout.time{j} = starttime:(1/data.fsample):endtime;
    datout.trial{j} = nan(numel(data.label), numel(datout.time{j}));
    
    % loop through the chunks that come from this trial
    for i = 1:numel(selind)
        
        startspl = nearest(datout.time{j}, data.time{selind(i)}(1));  % find start sample
        endspl = min(nearest(datout.time{j}, data.time{selind(i)}(end)), size(datout.trial{j},2));   % find end sample
        
        selspl = startspl:endspl;
        delta = size(selspl, 2) - size(data.trial{selind(i)}, 2);
        if delta == 1          % resampled data is too short to fit selection
            datout.trial{j}(:, endspl) = [];  % drop the extra column
            datout.time{j}(:, endspl) = [];
            endspl = endspl-1;                % make sample selection 1 spl shorter
        end
        
        datout.trial{j}(:, startspl:endspl) = data.trial{selind(i)}(:,1:(endspl-startspl+1));
        datout.trialinfo(j) = trlids(j); 
        
    end
    
end
    

end