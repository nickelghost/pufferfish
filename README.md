# Pufferfish

> **Warning**
> Running the following project will result in your aws account being charged for the resources that will be created. Run at your own risk.

This is a learning project, it does not reflect all best practices. It was created mainly for the learning of:

- Packer
- ASGs
- CloudWatch

But also training my skills in:

- Ansible
- Go (especially concurrency)
- Terraform
- aws
- GitHub Actions

## Setup

### Prerequisites

This project assumes you've already got an active Route53 zone and an SSH key in your aws account.

### Configuration

This project bases its configuration in aws parameter store. You will need to manually create those parameters:

- `/pufferfish/infra/domain` for the Route53-managed domain that Pufferfish will be available at
- `/pufferfish/infra/key_name` for the SSH key name that will be able to connect to EC2 instances
- `/pufferfish/infra/manager_cidr` for the CIDR that will be able to SSH into EC2 instances
- `/pufferfish/infra/notification_email` for the email that's to receive alert notifications
- `/pufferfish/infra/log_retention_in_days` for setting log retention time

Furthermore, the following can be optionally added:

- `/pufferfish/app/APP_BACKGROUND_COLOR` for specifying the website's background colour (white by default)

Above `/pufferfish/infra` parameters require a terraform apply of the app module and `/pufferfish/app` parameters require a rebuild of the AMI.

### Installing Ansible dependencies

Some of the following steps require installing collections that the playbooks and roles depend on:

```bash
ansible-galaxy install -r ansible/requirements.yml
```

### Creating Terraform state backend

S3 bucket and DynamoDB table for Terraform state are created with an Ansible playbook. The playbook automatically generates a unique name for the S3 bucket.

```bash
cd ansible/
ansible-playbook tfbackend.yml
```

### Initialising Terraform projects

You will be able to check the S3 bucket and DynamoDB table names in the parameter store, under `/pufferfish/infra/tfbackend_s3_name`. You can then initialise the Terraform projects - `cd` into the module directories in `terraform/` directory and run:

```bash
terraform init -backend-config="region=eu-west-1" -backend-config="bucket=pufferfish-tfstate-<YOUR_ID>" -backend-config="dynamodb_table=pufferfish-tfstate-<YOUR_ID>-locks"
```

### Provisioning build dependencies

You'll have to provision some aws infrastructure before you can build the AMI - `cd` into `terraform/app_build/` directory and run `terraform apply`.

### Building the AMI

You can build the AMI by running `packer` and pointing it to the root directory or the `.pkr.hcl` file. The app file requires a `name` variable to be provided. This is an example with a unique time-based AMI name generated:

```bash
packer build --var name=pufferfish-web-$(date +%s) .
```

### Provisioning the app infrastructure

Once you've got the AMI built, you can provision the rest of the infrastructure. This should just work if you've followed the previous steps correctly. Just `cd` into `terraform/app/` and run `terraform apply`
