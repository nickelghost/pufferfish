# Pufferfish

> [!WARNING]
> Deploying this project will create AWS resources that incur costs. Proceed at your own risk.

A learning project — a small Go web app about pufferfish, deployed on AWS using a fully automated infrastructure pipeline. It does not reflect all best practices.

**Built to learn:**

- Packer (custom AMI builds)
- Auto Scaling Groups
- CloudWatch metrics & alarms

**Also covers:**

- Ansible (provisioning & configuration)
- Go (HTTP server, concurrency)
- Terraform (infrastructure as code)
- AWS (EC2, ALB, ACM, Route53, SSM, S3, DynamoDB, SNS)
- GitHub Actions (CI/CD)

## Architecture overview

```
Route53 → ALB → ASG (EC2 instances running the Go app)
                       ↓
                  CloudWatch (metrics pushed every minute)
                       ↓
                  SNS (email alerts)
```

Terraform state is stored in S3 with DynamoDB locking. AMIs are built with Packer and configured with Ansible.

## Setup

### Prerequisites

- An active Route53 hosted zone in your AWS account
- An EC2 SSH key pair

### 1. Install Ansible dependencies

```bash
ansible-galaxy install -r ansible/requirements.yml
```

### 2. Create the Terraform state backend

Run the provided script to create an S3 bucket (with versioning and KMS encryption) and a DynamoDB locks table:

```bash
./scripts/tfbackend.sh
```

The generated S3 bucket name is stored in SSM Parameter Store under `/pufferfish/infra/tfbackend_s3_name`.

### 3. Set SSM parameters

Create the following parameters in AWS SSM Parameter Store before running `terraform apply`:

| Parameter                                 | Description                         |
| ----------------------------------------- | ----------------------------------- |
| `/pufferfish/infra/domain`                | Route53-managed domain for the app  |
| `/pufferfish/infra/key_name`              | EC2 SSH key pair name               |
| `/pufferfish/infra/manager_cidr`          | CIDR allowed to SSH into instances  |
| `/pufferfish/infra/notification_email`    | Email address for CloudWatch alerts |
| `/pufferfish/infra/log_retention_in_days` | CloudWatch log retention period     |

The following parameter is optional and requires an AMI rebuild to take effect:

| Parameter                              | Description                                  |
| -------------------------------------- | -------------------------------------------- |
| `/pufferfish/app/APP_BACKGROUND_COLOR` | Website background colour (default: `white`) |

### 4. Initialise Terraform

Run the following from within each of the two module directories (`terraform/app_building/` and `terraform/app/`):

```bash
terraform init \
  -backend-config="region=eu-west-1" \
  -backend-config="bucket=<YOUR_BUCKET_NAME>" \
  -backend-config="dynamodb_table=<YOUR_BUCKET_NAME>-locks"
```

Replace `<YOUR_BUCKET_NAME>` with the value from `/pufferfish/infra/tfbackend_s3_name`.

### 5. Provision build dependencies

```bash
cd terraform/app_building/
terraform apply
```

### 6. Build the AMI

From the repo root:

```bash
packer build --var name=pufferfish-web-$(date +%s) .
```

### 7. Provision the app infrastructure

```bash
cd terraform/app/
terraform apply
```
