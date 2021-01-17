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

## Use
`ansible-playbook main.yml`

## Trouble-shooting
