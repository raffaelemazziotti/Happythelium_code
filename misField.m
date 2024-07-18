function res = misField(dove,campo)

try
    dove.(campo);
    res = true;
    %res = isfield(dove,campo);
catch
    res = false;

end