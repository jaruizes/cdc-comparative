# Prepare schemas & data
cat /tmp/create_tables.sql | sqlplus admin/oracledb@//$1/cdc
