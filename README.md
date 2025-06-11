# Minecraft Terraform Configuration

### Background:

This project relies on Terraform combined with AWS to implement the following items:

- Create a VPC, routing table, internet gateway, and valid subnets for the Minecraft server
- Define a load balancer, necessary targets, listeners, and security groups.
- Implement an ECS cluster and run one task that is the Minecraft server
- Relies on Fargate to run and restart the Minecraft server

### Requirements:

The following software packages are needed to execute the Terraform script:

1. In order to run the script, Terraform must be installed on the system. Terraform can be installed by following [this](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) link.

2. In order to interact with the AWS infrastructure, the AWS CLI must be installed on the system. AWS CLI can be installed by following [this](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) link.

3. The final component needed are credentials for the AWS account. These credentials follow the cleartext format as described below:

```
[default]
aws_access_key_id={Insert value here}
aws_secret_access_key={Insert value here}
aws_session_token={Insert value here}
```

This file can be contained in any location, but the default location the Terraform script will look for the file is "./.aws/credentials".

Once all of these aspects of the system have been configured, the script can be run.


### Pipeline Explanation

The pipeline is simple. It requires just one Terraform script to be run to deploy all of the necessary architecture to run Minecraft. Additionally, in terms of infrastructure, this script will create an ECS cluster running with Fargate that launches a single task which runs the Minecraft Docker container. This task is accessible through the use of a load balancer that targets the task.

### Commands 

1. Execute the command ```terraform init```. This command will ensure all of the Terraform packages needed to interact with AWS are installed on the local system. It will also allow Terraform to properly manage the state of the AWS deployment with Terraform.

2. Execute the command ```terraform apply```. This command will create a list of changes that will be applied. Tying "yes" in response to the output will apply the Terraform architecture to the AWS infrastructure. Keep in mind that the following variables can be set when deploying the Terraform instance:

- **region:** This variable will determine which region the infrastructure will be deployed. The default value is "us-west-2".
- **credentials_path:** This variable will determine where the Terraform script should look for the AWS CLI credentials. This path will default to "./.aws/credentials".
- **minecraft_port:** This variable will determine which port the Minecraft server is accessible on. This will also be updated in the output URL. The default value is "25565".

These variables can be set by running commands with the ```-var``` flag. For example, the port Minecraft is accessible on can be changed by running the following command:

```
terraform apply -var "minecraft_port=32777"
```

3. Once the command is complete, you will view the output of ```server_url = {Minecraft URL}```. This is the URL that can be used to connect to Minecraft server.

### Connection 

The output URL can be used by the Minecraft client to connect to the Minecraft server. Navigate to the "Multiplayer" section, and add the server with the "Server Address" field set to the URL. Now you can connect to the server and play. 

**Note:** If you attempt to connect to the server immeadiately after running the script, the initial connections may fail. You may have to wait about 1 to 2 minutes after running the script to allow Fargate to initialize the container before connecting to the instance. 