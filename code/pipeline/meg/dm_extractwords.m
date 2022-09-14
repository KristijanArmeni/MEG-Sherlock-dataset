function tlck = dm_extractwords(sub, sess)

d = dm_dir;
datadir  = fullfile(d.derived,sub,sprintf('ses-%03d', sess),'meg');
filename = fullfile(datadir, sprintf('%s-%d_lcmv-data_1-40', sub(end), sess));
if sess>1
  filename = [filename '_align'];
end
load(filename);

% also get the subject specific information, for the delays
subj  = dm_subjinfo(sub);
delay = subj(sess).audiodelay./1000; % audio presentation delay in s, 
% this needs to be subtracted from the time axis to align the time axis of the data
% with the timing as defined in the pfa timing files

for k = 1:numel(data.time)
  data.time{k} = data.time{k} - delay(k);
end

if ~isfield(data, 'trialinfo')
  %error('trialinfo field is required');
  data.trialinfo = subj(sess).trl(:,4);%1:numel(data.trial);
end
data = dm_wordonsets(data, sess);


bsldat = zeros(numel(data.label)-1,0);
for k = 1:numel(data.trial)
  sel = find(data.trial{k}(end,:));
  begsmp = sel - 10;
  endsmp = sel + 120;
  
  ok = begsmp>=1 & endsmp<=numel(data.time{k});

  begsmp = begsmp(ok);
  endsmp = endsmp(ok);

  sumdat  = zeros(numel(data.label)-1, 131);
  finvals = sumdat;
  for m = 1:numel(begsmp)
    tmp = data.trial{k}(1:end-1, begsmp(m):endsmp(m));
    finvals = finvals + isfinite(tmp);
    tmp(~isfinite(tmp)) = 0;
    sumdat = sumdat + tmp;
  end
  
  dof(:,:,k) = finvals;
  X(:,:,k)   = sumdat; % actually this is still the sum

  delta = diff(begsmp);
  thr   = 90;
  sel   = (delta>thr);
  
  begsmp = begsmp(sel);
  for m = 1:numel(begsmp)
    tmp = data.trial{k}(1:end-1, begsmp(m)-20 + (1:20));
    tmp(~isfinite(tmp)) = 0;
    tmp = tmp-mean(tmp,2);
    bsldat = cat(2,bsldat,tmp);
  end

end
avg = sum(X,3)./sum(dof,3);
avg = avg - mean(avg(:,1:10),2);

tlck.avg    = avg;
tlck.label  = data.label(1:end-1);
tlck.time   = (-10:120)./data.fsample;
tlck.avg_n  = avg./(std(bsldat,[],2)./sqrt(size(bsldat,2)));
tlck.dimord = 'chan_time';

filename = fullfile(datadir, sprintf('%s-%d_lcmv-tlck_1-40', sub(end), sess));
save(filename, 'tlck');
