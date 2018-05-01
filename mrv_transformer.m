function mrv_transformer( nifti_file )
%transformer: performs the canonical nifti transformation on a list of
%nifti files. If no input files are specified, it will run the
%transformation on all niftis in pwd
% EXAMPLE INPUT:
%   (1) mrv_transformer('BOLD_mux3.nii.gz')
%   (2) mrv_transformer
%   written by JG
%   modified for VPNLtools by MR Apr 2018

% are nifti files specified?
e = exist('nifti_file');

% if no nifti files are given as input, take all from the current folder
if e ~= 1
    niftis = dir('*nii.gz*');
    nifti_file = {niftis.name};
end

for i = 1:length(nifti_file)
niftiWrite(niftiApplyCannonicalXform(niftiRead(nifti_file{i})),nifti_file{i});
fprintf('\nApplied cannonical transform to %s\n\n',nifti_file{i})
end

end

