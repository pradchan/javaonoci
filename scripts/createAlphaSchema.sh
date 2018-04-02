#!/bin/sh
##
if [ $# -lt 6 ]
then
    echo "Usage: createAlphaSchema.sh <OPC Identity Domain> <OPC Username> <OPC Password> <DBCS_ServiceName> <proxy> <Region> <DBCS IP (optional)>"
    exit 1
fi
OPC_DOMAIN=$1
OPC_USERNAME=$2
OPC_PASSWORD=$3
ServiceName=$4
PXY=$5
region=$6
PUBLIC_IP=$7

rest_server_url="dbaas.oraclecloud.com"
if echo "${region}" | grep -q "em"; then
  rest_server_url="dbcs.emea.oraclecloud.com";
fi

#export HTTP_PROXY="http://${PXY}"
#export HTTPS_PROXY="https://${PXY}"

#
response=$(curl --request GET \
                --user "${OPC_USERNAME}:${OPC_PASSWORD}" \
                --header "X-ID-TENANT-NAME: ${OPC_DOMAIN}" \
                --url https://${rest_server_url}/paas/service/dbcs/api/v1.1/instances/${OPC_DOMAIN}/${ServiceName} | sed 's/ /_/g')

# find position of EM URL in string
num=$(echo $response|grep -b -o "em_url"|awk -F":" '{print $1}')

INPUT=${response:$num+19}
PUBLIC_IP=${INPUT%%:*}


echo "Public IP of DBCS service instance ${ServiceName} is ${PUBLIC_IP}"
#
scp -o "StrictHostKeyChecking no" -i ./../keys/labkey ./../data/*.sql oracle@${PUBLIC_IP}:/home/oracle/.
#
ssh -o "StrictHostKeyChecking no" -i ./../keys/labkey oracle@${PUBLIC_IP} "cat /home/oracle/createAlphaUser.sql | sqlplus system/JavaOnOCI1#@PDB1"
#
ssh -o "StrictHostKeyChecking no" -i ./../keys/labkey oracle@${PUBLIC_IP} "cat /home/oracle/createProducts.sql | sqlplus alpha/oracle@PDB1"
