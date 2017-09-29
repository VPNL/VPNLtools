function pth = RAID
% Returns the path for the RAID partition on local computer.
%
% 9/17 AS

pth = which('RAID');
for ii = 1:5
    pth = fileparts(pth);
end

end

