#!/bin/bash
ASSEMBLY_LINE_NUM=$1
ASSEMBLY_LINE="assembly-line-${ASSEMBLY_LINE_NUM}"
THING=$2
SENSOR="${THING}-${ASSEMBLY_LINE_NUM}"
CERT_DIR="${ASSEMBLY_LINE}/${THING}/certs"


#CREATE THING IN IOT CORE
echo "Creating Thing..."
aws iot create-thing --thing-name $SENSOR --attribute-payload {\"attributes\":{\"purpose\":\"workshop\"}}


#CREATE KEYS AND CERTS
echo "Creating Keys and Certs..."
#CERT_ARN=$(aws iot create-keys-and-certificate --set-as-active --certificate-pem-outfile "${CERT_DIR}/device.pem.crt" --public-key-outfile "${CERT_DIR}/public.pem.key" --private-key-outfile "${CERT_DIR}/private.pem.key" --output text --query 'certificateArn')
CERT_ARN=$(aws iot create-keys-and-certificate --set-as-active --certificate-pem-outfile "${CERT_DIR}/device.pem.crt" --public-key-outfile "${CERT_DIR}/public.pem.key" --private-key-outfile "${CERT_DIR}/private.pem.key" --output text --query 'certificateArn')

aws iot attach-thing-principal \
    --thing-name "${SENSOR}" \
    --principal "${CERT_ARN}"

#ATTACH POLICY TO CERT
echo "Attaching Policy to Cert..."
aws iot attach-policy \
    --policy-name "ManufacturingWorkshop" \
    --target "${CERT_ARN}"

#CREATE THING SUB-PUB 
#aws iot create-thing --thing-name "Drill-Vibration-Sensor-${ASSEMBLY_LINE}"
#aws iot create-thing --thing-name "Cycle-Counter-${ASSEMBLY_LINE}"
#aws iot create-thing --thing-name "Power-Meter-${ASSEMBLY_LINE}"
#aws iot create-thing --thing-name "Fluid-Meter-${ASSEMBLY_LINE}"
#aws iot create-thing --thing-name "Air-Quality-Sensor-${ASSEMBLY_LINE}"
#aws iot create-thing --thing-name "Thermometer-${ASSEMBLY_LINE}"
#aws iot create-thing --thing-name "Pressure-Sensor-${ASSEMBLY_LINE}"
#aws iot create-thing --thing-name "Drill-${ASSEMBLY_LINE}"
#aws iot create-thing --thing-name "Proximity-Sensor-${ASSEMBLY_LINE}"
#aws iot describe-endpoint --endpoint-type iot:Data-ATS