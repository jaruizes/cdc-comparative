CREATE TABLESPACE LOGMINER_TBS;
CREATE USER dbzuser IDENTIFIED BY dbz DEFAULT TABLESPACE LOGMINER_TBS QUOTA UNLIMITED ON LOGMINER_TBS;

GRANT CREATE SESSION TO dbzuser;
GRANT FLASHBACK ANY TABLE TO dbzuser;
GRANT SELECT ANY TABLE TO dbzuser;
GRANT SELECT_CATALOG_ROLE TO dbzuser;
GRANT EXECUTE_CATALOG_ROLE TO dbzuser;
GRANT SELECT ANY TRANSACTION TO dbzuser;
GRANT SELECT ANY DICTIONARY TO dbzuser;
GRANT LOGMINING TO dbzuser;

GRANT CREATE TABLE TO dbzuser;
GRANT ALTER ANY TABLE TO dbzuser;
GRANT LOCK ANY TABLE TO dbzuser;
GRANT CREATE SEQUENCE TO dbzuser;

begin
    rdsadmin.rdsadmin_util.set_configuration('archivelog retention hours',24);
    rdsadmin.rdsadmin_util.alter_supplemental_logging('ADD');
    rdsadmin.rdsadmin_util.alter_supplemental_logging('ADD','PRIMARY KEY');
end;
/
