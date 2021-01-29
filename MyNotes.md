## Connect CircleCI to Slack
Get instructions at: CircleCI Project Settings -> Slack Integration.
1. Setup Authentication: https://github.com/CircleCI-Public/slack-orb/wiki/Setup
   - SLACK_ACCESS_TOKEN: The OAuth token acquired through the previous steps.
   - SLACK_DEFAULT_CHANNEL: If no channel ID is specified, the Slack orb will attempt to post here.
2. Integrate Slack orb: https://circleci.com/developer/orbs/orb/circleci/slack

## Create AWS User for AWS CLI usage

IAM ➜ Add User ➜ AWS access type(Programmatic access) ➜ Attach existing policies directly (AdministratorAccess)

## Add to aws access key to circleci

This allows CircleCI host able to use AWS CLI:

- `AWS_ACCESS_KEY_ID`:aws_access_key_id
- `AWS_SECRET_ACCESS_KEY`:aws_secret_access_key
- `AWS_DEFAULT_REGION`: us-west-2

## Make CircleCI able to access EC2 (add fingerprint)

This allows you to use ansible (to ssh login ec2) in circleci host.

- (repository's Setting ➜  "SSH keys" ➜ Additional SSH Keys ➜ copy the content in PEM file ➜ copy the Fingerprint to the CircleCI config.yml so that CircleCI knows which key to use when running the job, it basically copies the PEM file content to the host that is going to run the job) 

	- > in order to make a host able to access EC2, the host needs to have the ssh private key. After creating a pair on AWS Console, with the right access right attached to the key, the private key (pem file) needs to be stored locally to the host.

## Initiate circle.ci for project

Goto CircleCI and attach with GitHub project ➜ choose template ➜ after configured, 

- pipeline will be running and 
- the repo has a new branch: "circleci-project-setup"

## CircleCI example

- callback-scheduler repo: https://github.com/Xiaosha61/callback-scheduler/blob/circleci-project-setup/.circleci/config.yml
- ansible-playground repo: https://github.com/Xiaosha61/ansible-playground/blob/circleci-project-setup/.circleci/config.yml

## Make a host able to access EC2

- in order to make a host able to access EC2, the host needs to have the ssh private key. After creating a pair on AWS Console, with the right access right attached to the key, the private key (pem file) needs to be stored locally to the host.
- in order to make the CircleCI job able to access to the EC2, you need to add it to the repo, (repository's Setting ➜  "SSH keys" ➜ Additional SSH Keys ➜ copy the content in PEM file ➜ copy the Fingerprint to the CircleCI config.yml so that CircleCI knows which key to use when running the job, it basically copies the PEM file content to the host that is going to run the job) 
	- https://circleci.com/docs/2.0/add-ssh-key/

## Prometheus Client + Server Setup

| Machine                                | Public DNS | Port | Private IP   |
| -------------------------------------- | ---------- | ---- | ------------ |
| prometheus-server                      | yjl-host   | 9090 | 192.168.0.17 |
| prometheus-node-exporter<br>(data source) | my MacBook | 9100 | 192.168.0.11 |

>  instructions: https://codewizardly.com/prometheus-on-aws-ec2-part2/

### Client Setup (node_exporter)
- **Install and run node_exporter on MacBook:**

```bash
brew install node_exporter && node_exporter # using 9100 by default
```

​	node_exporter collects data and provide it on port 9100. can be viewed in

`http://192.168.0.11:9100/metrics`

### Server Setup

- ### Setting Up Prometheus server on yjl-host

	1. Download, extract and run the Prometheus server.

		```bash
		wget https://github.com/prometheus/prometheus/releases/download/v2.24.1/prometheus-2.24.1.linux-amd64.tar.gz
		tar xvfz prometheus-2.24.1.linux-amd64.tar.gz
		cd prometheus-2.24.1.linux-amd64/
		./prometheus --version
		./prometheus --config.file=./prometheus.yml # Start Prometheus
		```

	2. Open the instance's hostname or IP address in your browser with port `9090`: http://192.168.0.17:9090/

	3. modify ./prometheus.yml and add targets

		```bash
		global:
		  scrape_interval: 15s
		  external_labels:
		    monitor: 'prometheus'
		
		scrape_configs:
		  - job_name: 'node_exporter'
		    static_configs:
		      - targets: ['192.168.0.11:9100']
		```

		Then macbook's exporter can be discovered by yjl-host and can be viewed:  

		- http://192.168.0.17:9090/targets
		- http://192.168.0.17:9090/service-discovery#node_exporter

	4. to make it more automatable, the targets can be found using better config instead of `static_configs`:

		```bash
		global:
		  scrape_interval: 15s
		  external_labels:
		    monitor: 'prometheus'
		
		scrape_configs:
		  - job_name: 'node_exporter'
		    ec2_sd_configs:
		      - region: us-west-2
		      	access_key: <AWS_IAM_KEY>
		      	secret_key: <AWS_IAM_secret>
		      	port: 9100
		      	
		```

	5. Try out Graph to show the memory bytes that are used: (expression: `node_memory_total_bytes - node_memory_free_bytes`)

		http://192.168.0.17:9090/graph?g0.expr=node_memory_total_bytes%20-%20node_memory_free_bytes&g0.tab=0&g0.stacked=0&g0.range_input=1h

	6. add alert

		- install and run alertmanager

		```bash
		wget https://github.com/prometheus/alertmanager/releases/download/v0.21.0/alertmanager-0.21.0.linux-amd64.tar.gz
		tar xvfz alertmanager-0.21.0.linux-amd64.tar.gz
		cd alertmanager-0.21.0.linux-amd64/
		./alertmanager --config.file=alertmanager.yml
		```

		>  TIL: you can add anything as a systemctl process. See `#Configure Alertmanager as a service` in [here ](https://codewizardly.com/prometheus-on-aws-ec2-part4/) as an example of how to do it.

		- change alertmanager.yml to configure the alert channel

		You can use email as receiver, for that you need to allow your gmail account to be used by prometheus. see here for instructions of [Generate an App Password](https://codewizardly.com/prometheus-on-aws-ec2-part4/#generate-an-app-password)

		```yaml
		route:
		  group_by: [Alertname]
		  receiver: email-me
		
		receivers:
		- name: email-me
		  email_configs:
		  - to: EMAIL_YO_WANT_TO_SEND_EMAILS_TO
		    from: YOUR_EMAIL_ADDRESS
		    smarthost: smtp.gmail.com:587
		    auth_username: YOUR_EMAIL_ADDRESS
		    auth_identity: YOUR_EMAIL_ADDRESS
		    auth_password: YOUR_EMAIL_PASSWORD
		```

		or if you want to notify slack

		```yaml
		global:
		  resolve_timeout: 1m
		  slack_api_url: 'https://hooks.slack.com/services/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'
		route:
		  receiver: 'slack-notifications'
		receivers:
		  - name: 'slack-notifications'
		    slack_configs:
		    - channel: '#slack-notify-playground'
		      send_resolved: true
		```
  - See here if you want to have better slack messages https://medium.com/quiq-blog/better-slack-alerts-from-prometheus-49125c8c672b
    - checkout example for [prometheus-configs](prometheus-configs/)
  - create a rule for alerting: add a rules.yml file next to prometheus.yml file with: 




		```yaml
		groups:
		- name: Down
		  rules:
		  - alert: InstanceDown
		    expr: up == 0
		    for: 3m
		    labels:
		      severity: 'critical'
		    annotations:
		      summary: "Instance  is down"
		      description: " of job  has been down for more than 3 minutes."
		
		- name: AllInstances
		  rules:
		  - alert: UsingTooMuchMemory
		    expr: node_memory_free_bytes < 40000000000 # the condition that triggers alert
		    for: 1m # the duration that the condition holds
		    labels:
		      severity: 'critical'
		    annotations:
		      summary: "Instance {{ $labels.instance }} is almost out of memory"
		      description: "{{ $labels.instance }}  of job  has been down for more than 1 minutes."
		```

		- apply the rule in prometheus config file: prometheus.yml 

		```yaml
		global:
		  scrape_interval: 1s
		  evaluation_interval: 1s
		
		rule_files:
		 - /etc/prometheus/rules.yml # point to the rules config file
		
		alerting:
		  alertmanagers:
		  - static_configs:
		    - targets:
		      - localhost:9093 # depending on where you run your alertmanager
		
		scrape_configs:
		  - job_name: 'node'
		    ec2_sd_configs:
		      - region: us-east-1
		        access_key: PUT_THE_ACCESS_KEY_HERE
		        secret_key: PUT_THE_SECRET_KEY_HERE
		        port: 9100
		```

		- restart prometheus server

			```bash
			./prometheus --config.file=./prometheus.yml 
			```

		I got alerts in my slack 🙂

		![image-20210124142828669](notes4.assets/L5-slack-alert.png)

		can also check http://192.168.0.17:9093/#/alerts?receiver=slack-notifications