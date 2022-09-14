function onsets = dm_wordonsets(data, sess)

% data should be an internally consistent 'audio' data structure. It is
% assumed that the trialinfo is a single column/row, indexing the blocks

pfadir = '/project/3011085.05/lab/stim/alignment_v2';
onsets = data;
for k = 1:numel(data.trial)
  fname = fullfile(pfadir, sprintf('%02d_%d_pfa.txt', sess, data.trialinfo(k)));
  [ftab, orig, fstruct] = dm_pfa2ctf(fname, onsets.time{k}, 'word');
  onsets.trial{k}(end+1,:) = double(fstruct.trial(1,:));
end
onsets.label(end+1) = {'wordonset'};
