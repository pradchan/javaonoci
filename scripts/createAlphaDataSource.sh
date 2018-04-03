#!/bin/sh
##
if [ $# -lt 6 ]
then
    echo "Usage: createAlphaDataSource.sh <OPC Identity Domain> <OPC Username> <OPC Password> <ServiceName> <proxy> <Region> <JCS_IP (Optional)>"
    exit 1
fi
OPC_DOMAIN=$1
OPC_USERNAME=$2
OPC_PASSWORD=$3
ServiceName=$4
PXY=$5
region=$6
PUBLIC_IP=$7
rest_server_url="jaas.oraclecloud.com"
if echo "${region}" | grep -q "em"; then
  rest_server_url="jcs.emea.oraclecloud.com";
fi
#

#export HTTP_PROXY="http://${PXY}"
#export HTTPS_PROXY="https://${PXY}"

response=$(curl --request GET \
                --user "${OPC_USERNAME}:${OPC_PASSWORD}" \
                --header "X-ID-TENANT-NAME: ${OPC_DOMAIN}" \
                --url https://${rest_server_url}/paas/service/jcs/api/v1.1/instances/${OPC_DOMAIN}/${ServiceName}/ | sed 's/ /_/g')
				
echo "Response = $response"

# find position of EM URL in string
num=$(echo $response|grep -b -o "wls_admin_ur"|awk -F":" '{print $1}')

INPUT=${response:$num+27}
echo "Input = $INPUT"
PUBLIC_IP=${INPUT%%:*}
echo "PublicIP = $PUBLIC_IP"


#
scp -o "StrictHostKeyChecking no" -i ./../keys/labkey ./../keys/labkey.pub opc@${PUBLIC_IP}:/home/opc/.
scp -o "StrictHostKeyChecking no" -i ./../keys/labkey ./setupJCS.sh opc@${PUBLIC_IP}:/home/opc/.
ssh -t -t -o "StrictHostKeyChecking no" -i ./../keys/labkey opc@${PUBLIC_IP} "sudo /home/opc/setupJCS.sh"
#
scp -o "StrictHostKeyChecking no" -i ./../keys/labkey runAlphaDS.sh oracle@${PUBLIC_IP}:~oracle/.
scp -o "StrictHostKeyChecking no" -i ./../keys/labkey ./../data/create_data_source.py oracle@${PUBLIC_IP}:~oracle/.
scp -o "StrictHostKeyChecking no" -i ./../keys/labkey Alpha-ds.properties oracle@${PUBLIC_IP}:~oracle/.
ssh -o "StrictHostKeyChecking no" -i ./../keys/labkey oracle@${PUBLIC_IP} "/u01/app/oracle/tools/home/oracle/runAlphaDS.sh"
