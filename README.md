#  Real-time monitoring and remediation of IoT Devices using Confluent, AWS IoT Core and AWS Lambda

This repository accompanies the [Real-time monitoring and remediation of IoT Devices using Confluent, AWS IoT Core and AWS Lambda](https://aws.amazon.com/blogs) blog post. It contains the necessary Terraform scripts to deploy the solution. 

The sample solutiion demonstrated how to [Confluent Cloud](https://www.confluent.io/confluent-cloud/) and [AWS IoT Core](https://aws.amazon.com/iot-core/)  to monitor emissions and automate responses using Confluent's [AWS Lambda](https://aws.amazon.com/lambda/) Integration. In this fictional scenario, you are working at a plant that wants to lower its emissions levels. To do this, you will deploy the following:
1. Air emissions monitoring system - This will gather concentration levels for Carbon Dioxide (CO2) and Nitrogen Oxide (NOx)
2. Real-time processing pipeline - This will route data to the appropriate destinations and perform transformations to the data needed for downstream systems
3. Automated Response - This will be triggered when NOx levels trend beyond a set bound. When triggered, ammonia will be injected into the plant's boiler system which will lower the level of NOx.

With all three of these things, you will be able to detect and lower NOx levels in under 10ms.

<br>

![Architecture Diagram](assets/architecture.png)


```bash
├── Artifacts                             <-- Directory that will hold Terrafom Scripts and Solution Artifacts
│   ├── chaos_lambda.py                   <-- Lambda function code to simulate out of bounds NOx readings
│   ├──fix_lambda.py                      <-- Lambda function code to automate NOx level adjustments
│   ├──aws.tf                             <-- Terraform script to deploy AWS resources
│   ├──main.tf                            <-- Terraform script to deploy Confluent resources
│   ├──outputs.tf                         <-- Terraform file for solution outputs
│   ├──providors.tf                       <-- Terraform providors file
│   ├──terraform.tfvars                   <-- Variables file
│   ├──variables.tf                       <-- Variables definition                       
└── README.md
```


## General Requirements
1. AWS Account
2. AWS Access keys (create these before starting the setup)
3. AWS Permissions to AWS IoT, AWS Lambda, AWS Secrets Manager, and IAM
4. Confluent Cloud account with [Cloud API Keys](https://docs.confluent.io/cloud/current/access-management/authenticate/api-keys/api-keys.html#cloud-cloud-api-keys)
6. AWS CLI installed
7. Have the following python libraries installed: `awsiotsdk` and `awscrt`
8. Workshop Time: ~ 45 min


## Deploy solution

1. Clone the repo onto your local development machine using `git clone <repo url>`.
2. Change directory to solution repository.

```
cd Confluent-AWS-IoT-Core-Emissions-Solution/terraform

```

3. Edit the variables in terraform.tfvars files
    * region = "us-west-2"
    * vpc_cidr = "10.0.0.0/16"
    * confluent_topic_name="air-quality-sensor-1"
    * confluent_cloud_api_key - Confluent Cloud API Key created in [General Requirements](#general-requirements)
    * confluent_cloud_api_secret -
5.
6. Run ```terraform init```
7. 



