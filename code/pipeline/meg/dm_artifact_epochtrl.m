function trlout = dm_artifact_epochtrl(trlin)

% Convert trl into slightly ovelapping 4 second epochs for browsing
trlout = zeros(0,3);

for k = 1:size(trlin, 1)
  tmp      = [];
  tmp(:,1) = ((trlin(k, 1) - 2400):4700:(trlin(k, 2) + 2400))';
  tmp(:,2) = tmp(:, 1) + 4799;
  tmp(:,3) = 0;
  trlout   = [trlout; tmp];
end

end

