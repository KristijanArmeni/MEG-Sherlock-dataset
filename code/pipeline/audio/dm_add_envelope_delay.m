function dataout = dm_add_envelope_delay(audio, wavfile)
  
  if ischar(wavfile)
    audiotmp = dm_wav2mat(wavfile);
  else
    audiotmp = wavfile;
  end
  
  % now find bed/end indices in the UADC003 (adjusted) audio time axis 
  % corresponding to the adjusted .WAV time axis
  i1 = nearest(audio.time{1}, audiotmp.time{1}(1));
  i2 = nearest(audio.time{1}, audiotmp.time{1}(end));
  
  % here find the beg/end sample points in the adjusted .WAV time axis
  % that mapp onto correspoding sample in the UADC003 axis
  i3 = nearest(audiotmp.time{1}, audio.time{1}(1));
  i4 = nearest(audiotmp.time{1}, audio.time{1}(end));
  
  % add the correctly aligned average envelope channels to the 'audio' data structure
  audio.trial{1}(2,:) = 0;
  audio.trial{1}(3,:) = 0;
  
  avg_ind = find(all(ismember(audiotmp.label, 'audio_avg'), 2)); % find index of 'audio_avg' in audio_wav.label
  aud_ind = find(all(ismember(audiotmp.label, 'audio'), 2));     % find index of 'audio' channel in audio_wav.label
  
  % map the data in .WAV (envelope) to the correct indices in the UADC003
  % axes
  audio.trial{1}(2, i1:i2) = audiotmp.trial{1}(avg_ind, i3:i4); % assign audio_avg channel
  audio.trial{1}(3, i1:i2) = audiotmp.trial{1}(aud_ind, i3:i4); % assign audio channel
  audio.label(2, 1)        = audiotmp.label(avg_ind);           % add label as well
  audio.label(3, 1)        = audiotmp.label(aud_ind);
  
  % map the .WAV envelope time axes onto the UADC003 time axes 
  audio.time{1}(i1:i2) = audiotmp.time{1}(i3:i4);
  
  dataout = audio;
  
end