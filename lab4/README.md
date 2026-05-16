# Laboratory Work 4: IaC with Terraform and Ansible

This directory contains the IaC implementation for deploying the existing
`mywebapp` Spring Boot notes service on two Linux virtual machines.

## Variant

Initial value:

- `N = 21`

Application parameters reused from the previous labs:

- application: `Notes Service`
- database: `PostgreSQL`
- application port: `5200`
- application config: `/etc/mywebapp/config.yaml`
- gradebook: `/home/student/gradebook`, containing only `21`

## Target Architecture

```text
client
  |
  v
VM1 worker
  nginx 0.0.0.0:80
  -> mywebapp 127.0.0.1:5200
       |
       v
VM2 db
  PostgreSQL <db-vm-ip>:5432
```

PostgreSQL is configured to accept connections only from the worker VM address
and the database VM itself. The application health check `/health/ready` uses
the remote PostgreSQL connection, so it verifies the link between `worker` and
`db`.

## Directory Layout

- `terraform/` provisions two Ubuntu cloud-image VMs with libvirt/KVM.
- `ansible/` configures users, PostgreSQL, nginx, and the application.
- `ansible/roles/common` creates common users and the gradebook file.
- `ansible/roles/db` configures PostgreSQL and database access restrictions.
- `ansible/roles/app` installs and runs the Spring Boot application.
- `ansible/roles/nginx` configures the reverse proxy.

## Prerequisites

On the control machine:

- Terraform
- Ansible
- KVM/QEMU with libvirt
- an Ubuntu 24.04 cloud image, for example `noble-server-cloudimg-amd64.img`
- an SSH key pair for the `ansible` user
- Java 21 in this repository to build the application JAR

Install required Ansible collections:

```bash
cd lab4/ansible
ansible-galaxy collection install -r requirements.yml
```

Build the application artifact from the repository root:

```bash
./gradlew bootJar
```

## Provisioning with Terraform

Create a Terraform variable file:

```bash
cd lab4/terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set at least:

- `ubuntu_cloud_image_path`
- `ssh_public_key_path`
- `ssh_private_key_path`

Provision both VMs:

```bash
terraform init
terraform apply
```

Terraform writes the Ansible inventory to:

```text
lab4/ansible/inventory/hosts.ini
```

## Configuration with Ansible

Run the playbook from `lab4/ansible`:

```bash
ansible-playbook -i inventory/hosts.ini site.yml
```

A repeated run should be idempotent when the deployed state already matches the
playbook.

## Verification

From the control machine, open the worker VM address printed by Terraform:

```bash
curl -i http://<worker-ip>/
curl -i -H 'Accept: application/json' http://<worker-ip>/notes
```

From the worker VM:

```bash
curl -i http://127.0.0.1:5200/health/alive
curl -i http://127.0.0.1:5200/health/ready
```

Check that health endpoints are not exposed through nginx:

```bash
curl -i http://<worker-ip>/health/alive
```

Expected result: nginx returns `404`.

Check the gradebook:

```bash
ssh ansible@<worker-ip> cat /home/student/gradebook
ssh ansible@<db-ip> cat /home/student/gradebook
```

Expected result:

```text
21
```

Check operator sudo permissions on the worker VM:

```bash
ssh operator@<worker-ip> sudo -l
```

The `operator` user may only execute:

- `/usr/local/bin/mywebappctl start`
- `/usr/local/bin/mywebappctl stop`
- `/usr/local/bin/mywebappctl restart`
- `/usr/local/bin/mywebappctl status`
- `/usr/bin/systemctl reload nginx`

## Destroying the VMs

```bash
cd lab4/terraform
terraform destroy
```
