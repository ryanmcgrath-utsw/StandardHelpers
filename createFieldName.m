function type = createFieldName(type)
%CREATEFIELDNAME takes a string/char and ensures a valid field name is
% produced such that it can be used in a structure

type = strrep(type,'.','');
type = strrep(type,'(','_');
type = strrep(type,')','');

end