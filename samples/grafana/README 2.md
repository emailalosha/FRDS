<!--
  Copyright 2018-2020 ForgeRock AS. All Rights Reserved

  Use of this code requires a commercial software license with ForgeRock AS.
  or with one of its affiliates. All use shall be exclusively subject
  to such license between the licensee and ForgeRock AS.
-->
# Setting Up the Directory Services Sample Dashboard

The ForgeRock Directory Services sample dashboard is a
[Grafana](https://grafana.com/) dashboard that graphs data
stored in [Prometheus](https://prometheus.io/):

* By default, DS servers publish Prometheus-format metrics at `/metrics/prometheus`.
* Prometheus regularly pulls metrics from each DS server.
* Grafana graphs metrics queried from Prometheus.

_**Disclaimer:**
This sample is provided on an "as is" basis, without warranty of any kind, to 
the fullest extent permitted by law. ForgeRock does not warrant or guarantee 
the individual success developers may have in implementing the code on their 
development platforms or in production configurations. ForgeRock does not 
warrant, guarantee or make any representations regarding the use, results 
of use, accuracy, timeliness or completeness of any data or information 
relating to this sample. ForgeRock disclaims all warranties, expressed or 
implied, and in particular, disclaims all warranties of merchantability, and 
warranties related to the code, or any service or software related thereto. 
ForgeRock shall not be liable for any direct, indirect or consequential 
damages or costs of any type arising out of any action taken by you or others 
related to the sample._

To prepare to use the dashboard, set up and configure the following:

* DS servers, assigning a password to the default monitor user, `uid=Monitor`.
  Prometheus will access the metrics with username `monitor` and password `password`.
* Prometheus, configured to access metrics from the DS servers.
* Grafana, configured to access Prometheus as the data source.

After completing these steps, you import the sample dashboard into Grafana.

The rest of this README demonstrates the steps.

## Directory Services Setup

This section demonstrates how to set up a pair of DS replicas to monitor.

This section assumes you already know how to set up and use DS servers.
For background information and additional details see the
[DS documentation](${doc.base.url}/).

### Set Up a Pair of DS Replicas to Monitor

Prepare a couple of DS/RS server replicas to monitor,
as shown in the following example script.

The script assumes you have downloaded the DS server distribution,
and that you can set up servers in the `/path/to` directory:

```
#!/usr/bin/env bash

# Set up two DS/RS servers and start replication.

ZIP=~/Downloads/DS-${project.version}.zip
CURRENT_DIR=$(pwd)
BASE_DIR=/path/to
INSTANCE_PREFIX=ds-rs-
HOSTNAME=opendj.example.com

cd ${BASE_DIR}

# Create a deployment key
createKey() {
    DEPLOYMENT_KEY=`${BASE_DIR}/${INSTANCE_PREFIX}1/bin/dskeymgr \
        create-deployment-key --deploymentKeyPassword password`
}

# Set up a single DS/RS.
# $1: instance number
setup() {
    ${BASE_DIR}/${INSTANCE_PREFIX}${1}/setup \
     --deploymentKey ${DEPLOYMENT_KEY} \
     --deploymentKeyPassword password \
     --rootUserDN "uid=admin" \
     --rootUserPassword password \
     --monitorUserDn "uid=monitor" \
     --monitorUserPassword password \
     --hostname ${HOSTNAME} \
     --ldapPort ${1}389 \
     --ldapsPort ${1}636 \
     --httpPort ${1}8080 \
     --httpsPort ${1}8443 \
     --adminConnectorPort ${1}4444 \
     --replicationPort ${1}8989 \
     --serverId DS${1} \
     --bootstrapReplicationServer ${HOSTNAME}:18989 \
     --bootstrapReplicationServer ${HOSTNAME}:28989 \
     --profile ds-evaluation \
     --set generatedUsers:10000 \
     --acceptLicense
    
    # For simplicity, disable requirement to authenticate over a secure connection
    # Otherwise all tests will need to run with TLS.
    ${BASE_DIR}/${INSTANCE_PREFIX}${1}/bin/dsconfig --offline --no-prompt --batch <<EOC
        set-password-policy-prop --policy-name Default\ Password\ Policy \
        --set require-secure-authentication:false 
        set-password-policy-prop --policy-name Root\ Password\ Policy \
        --set require-secure-authentication:false
EOC

    ${BASE_DIR}/${INSTANCE_PREFIX}${1}/bin/start-ds
}

unzip ${ZIP}
mv opendj ${INSTANCE_PREFIX}1
cp -r ${INSTANCE_PREFIX}1 ${INSTANCE_PREFIX}2

createKey
setup 1
setup 2

cd ${CURRENT_DIR}
```

### Run Load Against DS Replicas

In order to have some data to view, use the `*rate` tools to generate load,
as shown in the following example script.

The script assumes you set up replicas as described in the previous section:

```
#!/usr/bin/env bash

# Run some load against two DS/RS servers.

BASE_DIR=/path/to
INSTANCE_PREFIX=ds-rs-

# $1: instance number
search() {
	${BASE_DIR}/${INSTANCE_PREFIX}${1}/bin/searchrate -p 1389 -D 'uid=admin' -w password \
        -d 30 -F -c 4 -t 4 -b 'dc=example,dc=com' -g 'rand(0,10000)' '(uid=user.{})'
}

# $1: instance number
modify() {
	${BASE_DIR}/${INSTANCE_PREFIX}${1}/bin/modrate -p 2389 -D 'uid=admin' -w password -d 30 \
        -F -c 4 -t 4 -b 'uid=user.{1},ou=people,dc=example,dc=com' -g 'rand(0,10000)' \
        -g 'randstr(16)' 'description:{2}'
}

for i in 1 2
do
	search ${i} &
	modify ${i} &
done
```

## Prometheus Setup

Download and install Prometheus as described in
[First steps with Prometheus](https://prometheus.io/docs/introduction/first_steps/).

When configuring Prometheus, make sure that it pulls metrics from your DS servers.

If you set up a pair of DS replicas as described in the previous section,
you could use the following `scrape_configs` settings
in your Prometheus configuration file, `prometheus.yml`:

```
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'ForgeRock DS'

    scrape_interval: 15s
    scrape_timeout: 5s
    metrics_path: '/metrics/prometheus'

    basic_auth:
      username: 'monitor'
      password: 'password'

    static_configs:
      - targets: ['opendj.example.com:18080', 'opendj.example.com:28080']
        labels:
            group: 'Demo'

```

Start Prometheus.

Once Prometheus starts, check that Prometheus does retrieve data.

To troubleshoot any problems, try these steps:

* Check the Prometheus URL on a DS server to make sure the metrics are published.
  For example, browse <http://opendj.example.com:18080/metrics/prometheus>,
  authenticating with username `monitor` and password `password`.
* Check that the DS targets are up using the Prometheus targets page.
  The default URL to browse is <http://localhost:9090/targets>.
* Check that the metrics are found using the Prometheus graph page.
  The default URL to browse is <http://localhost:9090/graph>.
  You should find a long list of `ds_*` metrics in the drop-down list.

## Grafana Setup

* Download and install Grafana as described in
  _[Installing Grafana](http://docs.grafana.org/installation/)_.
* Add a default data source that scrapes data from Prometheus.
  If you used the default settings, then use these data source settings:

```
Name:     ForgeRockDS
Type:     Prometheus
Default:  (checked)

URL:      http://localhost:9090
Access:   Direct
```

* Import the sample DS dashboard into Grafana,
  selecting ForgeRockDS as the data source.
* (Optional) Generate more load on the DS replicas as described above.
  The dashboard updates the graphs as the data changes.

## Next Steps

The sample dashboard is suitable for demonstration purposes only.

To adapt the dashboard to your needs, start learning about Grafana with their
_[Getting Started](http://docs.grafana.org/guides/getting_started/)_ guide.

For reference information about DS server metrics,
see the DS _[Reference](${doc.base.url}/reference/#chap-monitoring)_.
