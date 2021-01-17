# Introduction
This is an exercise trying out ansible.

## Prerequisite
### Install ansible on MacOS
```bash
# option1 - homebrew
brew install ansible

# option2 - pip
python -m pip install --user ansible
python -m pip list show # check installed modules

# option3 - pip3 install
pip3 uninstall ansible # if there was an older version
pip3 install ansible

```

### Prepare Hosts (e.g., EC2 instances)
These can be pre-setup hosts or built on the fly. `inventory` can be used as the file to tell ansible the IP addresses of the target hosts.
```bash
# create an initial inventory file:
echo "[all]" > inventory

# query EC2 for instances and append output to the inventory file
aws ec2 describe-instances \
    --query 'Reservations[*].Instances[*].PublicIpAddress' \
    --filters "Name=tag:project,Values=udacity" \
    --output text >> inventory
```

## Use Guide
### Try out localhost
`ansible-playbook main.yml`

### Use EC2 to deploy a WebServer
1. Query EC2 and write into inventory
   ```bash
   # prepare inventory file (create old one)
   bash helper-scripts/prepare-inventory-file.sh inventory-ec2 --delete

   # resolve EC2 IP
   aws ec2 describe-instances \
     --query 'Reservations[*].Instances[*].PublicIpAddress' \
     --filters "Name=tag:project,Values=udacity" \
     --output text >> inventory
   ```

2. Specify inventory file and SSH private key:
`ansible-playbook main-ec2.yml -i inventory-ec2 --private-key my-key-pair-priv.pem`

## Trouble-shooting
### Test if your host is accessible via SSH
Take EC2 as example:
`ssh -i my-key-pair-priv.pem ec2-user@ec2-host-name.amazonaws.com`