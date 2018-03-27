ALTER SESSION SET CONTAINER="PDB1";

create user alpha identified by oracle;
grant connect,dba to alpha;
exit;