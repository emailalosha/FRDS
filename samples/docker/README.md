# Creating Custom Images

There are two workflows for developing custom Docker images:

1. **GitOps**: this approach is a well-known workflow which will be 
 described in the next section. A "prototype" or "template" DS instance
 is developed and maintained under Git version control. Developers record
 upgrades and configuration changes as separate commits, taking care to
 document what was done and why in the commit messages. Note that the upgrade
 tool will not attempt to enable new features or adopt new best-practices
 that would normally be available by default for a new DS instance. Instead,
 developers must review the releases notes for new DS versions and decide
 which changes they wish to adopt.
 
2. **Hybrid**: similar to the GitOps approach described above, except that
 all the setup and customization steps are recorded in a script which is
 checked in to the Git repository. The sample `setup.sh` script may be used
 as the basis for such a script. To upgrade first build a new DS instance
 outside of the Git workspace using the script (a separate Dockerfile can
 be used for this step). The new DS instance will include any new features,
 defaults and best-practices provided with the new version. Next, compare 
 the new instance with the version maintained in Git and copy any desired
 changes. Finally, use a simple Dockerfile, such as the one provided with
 this sample, to build the final image from the files stored in the Git
 workspace.
 <br/><br/>
 This approach is more complicated than the GitOps approach, but it
 increases the likelihood that developers will discover new features and
 best-practices included with new versions of DS. In addition, the script
 clearly documents the customizations that have been performed over time
 rather than relying on Git commit messages.

**Note**: custom Docker images should take special care when pre-populating
encrypted backends with data at build time, because the "master-key"
used at build time must be available at run time in order to decrypt the data.
However, most deployments will not want to use the same master-key in different
environments. For example, a test environment should not encrypt sensitive
customer data using the same master-key as a production environment. Given
that the initial populated data is not usually sensitive, one solution is to
use a bootstrap master-key when building the custom image which is then
included in each environment's keystore. Each environment's keystore then
includes a second "active" master-key which is then used for protecting new
data as it is added to the backends.

## GitOps

### Prepare your workspace

First create your Git workspace and populate it with the DS binaries:

    unzip path/to/opendj.zip 
    git init opendj
    cd opendj
    git add .
    git commit -m "Initial commit of DS binaries"

Then perform the initial setup of the server. The `setup.sh` script included 
in the `samples` directory is a good starting point and will create an empty
server suitable for use with Docker and Kubernetes:

    ./samples/docker/setup.sh 
    git add .
    git commit -m "./samples/docker/setup.sh"

### Test the initial Docker image

Build the DS image:

    docker build -t ds:latest .

Run the DS image, **TEST ENVIRONMENTS ONLY**:

    docker run --rm -it --env USE_DEMO_KEYSTORE_AND_PASSWORDS=true ds:latest start-ds

The container will use a TLS certificate for "localhost" and the admin and monitor password will be automatically 
set to "password".

### Customize your Docker image

Perform additional customizations as needed taking care to ensure that commit
messages accurately document the changes:

    ./bin/setup-profile --profile ds-evaluation --set ds-evaluation/generatedUsers:2000
    git add .
    git commit -m "./bin/setup-profile --profile ds-evaluation --set ds-evaluation/generatedUsers:2000"

Rebuild and test the Docker image after each customization:

    docker build -t ds:latest .
    docker run --rm -it --env USE_DEMO_KEYSTORE_AND_PASSWORDS=true ds:latest start-ds

### Create a production keystore

By default, the DS image is configured to use these 3 keys from a keystore:
- "ca-cert"
- "ssl-key-pair"
- "master-key"

In the previous sections, you have started the container with a demo keystore, before going to production, you must 
create your own keystore.

1. **Using dskeymgr**

If you don't already have a deployment key, create a new one:

    ./bin/dskeymgr create-deployment-key
Do not reuse a deployment key that was employed in a test environment.

Create a keystore pin file:

    echo "password" > path/to/secrets/keystore.pin

Create a keystore with all the DS keys:

    ./bin/dskeymgr export-master-key-pair \
    --keyStoreFile path/to/secrets/keystore \
    --keyStorePassword:file path/to/secrets/keystore.pin \
    --deploymentKey AI5vCdye8l9F1dA29jIPVASdAwwJ2w5CBVN1bkVDLrGAY_18AIvr7cw

    ./bin/dskeymgr export-ca-cert \
    --keyStoreFile path/to/secrets/keystore \
    --keyStorePassword:file path/to/secrets/keystore.pin \
    --deploymentKey AI5vCdye8l9F1dA29jIPVASdAwwJ2w5CBVN1bkVDLrGAY_18AIvr7cw

    ./bin/dskeymgr create-tls-key-pair \
    --keyStoreFile path/to/secrets/keystore \
    --keyStorePassword:file path/to/secrets/keystore.pin \
    --subjectDn CN=DS,O=ForgeRock.com \
    --hostname localhost \
    --deploymentKey AI5vCdye8l9F1dA29jIPVASdAwwJ2w5CBVN1bkVDLrGAY_18AIvr7cw

Be sure to replace `localhost` with the hostname of the docker container.

If the production container contains initial data that was encrypted in a test environment, also add the test 
master-key to the keystore. Only the alias "master-key" will be used to encrypt new data.

    ./bin/dskeymgr export-master-key-pair \
    --keyStoreFile path/to/secrets/keystore \
    --keyStorePassword:file path/to/secrets/keystore.pin \
    --deploymentKey <test-deployment-key> \
    --alias initial-data-master-key

2. **Using the method of your choice**

Create a PKCS12 keystore `path/to/secrets/keystore` and its keystore password file `path/to/secrets/keystore.pin`.
   
Add the following to the keystore:
- The CA certificate with the alias "ca-cert". Must be the same in all the DS servers of the deployment.
- An SSL key pair with the alias "ssl-key-pair" and signed by the CA.
- The RSA master key pair, with the alias "master-key". Must be the same in all the DS servers of the deployment.

If the production container contains encrypted but non-confidential base entries from setup profiles created when 
using the test keystore, export the master-key pair from the test keystore, and import it into your production 
keystore using another alias, such as master-key-for-non-confidential-data.

Only the key with the master-key alias is used to encrypt new data.

### Run your Docker image in production

Pick strong passwords for the admin and monitor users and run the container with your own keystore:

    docker run --rm -it \
    --env DS_SET_UID_ADMIN_AND_MONITOR_PASSWORDS=true \
    --env DS_UID_ADMIN_PASSWORD=password \
    --env DS_UID_MONITOR_PASSWORD=password \
    --mount type=bind,src=/path/to/secrets,dst=/opt/opendj/secrets \
    ds:latest start-ds

### Upgrade

To upgrade the server, unzip the new binaries over the top of the existing 
workspace and then run `upgrade` to upgrade the configuration. The upgrade
tool will not automatically enable new features or best-practices. Instead,
read the release notes in order to decide which changes to adopt. 

    cd ..
    unzip -o path/to/new-opendj.zip
    cd opendj 
    ./upgrade
    # review changes, commit and rebuild...

## GitOps with Kubernetes

If you would like to develop your custom Docker image using Kubernetes
tooling (Minikube, Skaffold, etc) then use the image's "dev" command
when deploying the DS pod using a Kustomize patch like this:

    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: ds
    spec:
      replicas: 1
      template:
        spec:
          containers:
          - name: ds
            args:
            - dev

The "dev" command will instruct the pod to start without actually starting
the server itself. You can then attach to the running DS container and make
offline configuration changes using kubectl instead of docker:

    kubectl exec -it ds-0 -- dsconfig --offline

When you are happy with your changes, copy the updated configuration out as
follows and then commit the changes to Git. Take care use a commit message
which accurately describes the changes:

    kubectl cp ds-0:/opt/opendj/config path/to/git/workspace
    git add .
    git commit -m "Enabled features X, Y and Z for project Blah"
