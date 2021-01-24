# Introduction
This is an exercise trying out Ansible and CircleCI, also involving some IAC(AWS CloudFormation) usage.

CircleCI helps to:
  - define a CI pipeline which will be running one every code push
  - a pipeline is composed of a workflow which contains jobs
  - .circleci/config.yml will be referred by CircleCI
  - CircleCI will take care of assigning hosts in specific docker image named in the config file to run the workflow
  - focus on what to run.
 
Ansible is to:
  - define a bunch of roles
  - a role contains tasks
  - playbook.yml can be used by `ansible-playbook` to orchestrate a workflow
  - ansible user needs to point ansible to the right hosts that are supposed to run the ansible workflow (using inventory file)
  - an ansible task flow can be triggered inside a job of CircleCI.
  - focus on what the host should be able to do, it contains a lot of steps to configure the host. That's why it is a configuration tool.

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
     --output text >> inventory-ec2
   ```

2. Specify inventory file and SSH private key:
`ansible-playbook main-ec2.yml -i inventory-ec2 --private-key my-key-pair-priv.pem`


### P4_L4_E28_workflow
1. create a s3 bucket manually, named "xing-circlec"
2. deploy a cloudformation stack manually using cloudfront.yml file.
```bash
S3_BUCKET_NAME="xing-circlec"
aws cloudformation deploy \
  --template-file cloudformation/cloudfront.yml \
  --stack-name production-distro \
  --parameter-overrides PipelineID="${S3_BUCKET_NAME}" \
  --tags project=udapeople # &
```
Till now, I have my first version of production deployment.

Then I can trigger a new deployment by pushing new code and running CircleCI workflow `P4_L4_E28_workflow`. Inside the work flow it does the follows:
1. create_and_deploy_front_end: create a new S3 bucket with new version of files. The pipeline's Id will be used as the new bucket's name.
2. get_last_deployment_id: store the deploymentId of the old production version (the one I manually deployed) in the workspace (can also use cache), by using `aws cloudformation list-export`. 
   - This is possible because I have `Outputs` in my cloudfront.yml file. :) 
   - This needs to be before the promote_to_production because after that the PipelineID of the stack will be changed to the new version's.
3. promote_to_production: update the stack `production-distro`, so that the CloudFront server will notice it needs to change the origin to the new S3 bucket.
4. clean_up_old_front_end: delete the old s3 bucket which I created manually. (And also delete the stack entirely in the end.)

There is an obvious problem of deleting the stack inside the pipeline:
- after the stack is deleted, the s3 bucket and cloudfront resources will also be deleted,
- next time when I push my code, there's no longer such stack, which means in get_last_deployment_id I will not be able to get anything.
For the exercise it's all fine, I just create a stack named `production-distro` beforehand. But in real product cycle, it should be just loopable. Maybe the stack just needs to be kept there, and only the s3 bucket should be deleted.

## Trouble-shooting
### Test if your host is accessible via SSH
Take EC2 as example:
`ssh -i my-key-pair-priv.pem ec2-user@ec2-host-name.amazonaws.com`