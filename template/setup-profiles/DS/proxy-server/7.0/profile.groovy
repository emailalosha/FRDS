/*
 * Copyright 2018-2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

// Compute dsconfig arguments from parameter values then create the replication service discovery mechanism
def arguments = [ "create-service-discovery-mechanism",
                  "--mechanism-name", "Replication Service Discovery Mechanism",
                  "--type", "replication",
                  "--set", "key-manager-provider:" + keyManagerProvider,
                  "--set", "trust-manager-provider:" + trustManagerProvider,
                  "--set", "use-ssl:" + ("ssl" == rsConnectionSecurity),
                  "--set", "use-start-tls:" + ("start-tls" == rsConnectionSecurity),
                  "--set", "use-sasl-external:true" ]

if (!primaryGroupId.isEmpty()) {
    arguments.add "--set"
    arguments.add "primary-group-id:" + primaryGroupId
}

for (rsHostPort in bootstrapReplicationServer) { // 'bootstrapReplicationServer' is a multivalued parameter
    arguments.add "--set"
    arguments.add "bootstrap-replication-server:" + rsHostPort
}

for (sslCertNickName in certNickname) { // 'certNickname' is a multivalued parameter
    arguments.add "--set"
    arguments.add "ssl-cert-nickname:" + sslCertNickName
}

ds.config arguments

baseDns = baseDn // 'baseDn' is a multivalued parameter
// Compute dsconfig arguments from parameter values then create the proxy backend
arguments = [ "create-backend",
              "--type", "proxy",
              "--backend-name", backendName,
              "--set", "enabled:true",
              "--set", "key-manager-provider:" + keyManagerProvider,
              "--set", "use-sasl-external:true",
              "--set", "route-all:" + baseDns.isEmpty(),
              "--set", "shard:Replication Service Discovery Mechanism" ]

for (dn in baseDns) {
    arguments.add("--set")
    arguments.add("base-dn:" + dn)
}

for (sslCertNickName in certNickname) { // 'certNickname' is a multivalued parameter
    arguments.add "--set"
    arguments.add "ssl-cert-nickname:" + sslCertNickName
}

ds.config arguments

ds.config "delete-access-control-handler"
ds.config "create-access-control-handler",
          "--type", "policy-based",
          "--set", "enabled:true"
