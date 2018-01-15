addpath('/data/server_share/matlab_applications_dev/spm12');
addpath('/data/server_share/matlab_applications_dev/scripts/convert_REC_PAR_ASL/');

P = cellstr(spm_select('FPListRec', '/data/qa_queue', '^*.PAR'));

diary('/data/qa_queue/tmp.log');
diary on
for i = 1:length(P)

  [path base ext] = fileparts(P{i});
  nii3_file = [path filesep base '_3D_1_1.nii'];
  nii4_file = [path filesep base '_4D_1_1.nii'];

  if (exist(nii3_file, 'file' )  || exist(nii4_file, 'file'))
    P{i} = [];
  end
end

try
  ind = find(~cellfun(@isempty, P));
  if ~isempty(ind)
    convert_ASL_v07(P(ind));
  end

catch     
end

quit;
