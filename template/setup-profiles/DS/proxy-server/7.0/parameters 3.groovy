/*
 * Copyright 2018-2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

define.stringParameter "backendName" \
       usage "Name" \
       help "Name of the proxy backend for storing proxy configuration" \
       defaultValue "proxyRoot" \
       advanced()

define.hostPortParameter "bootstrapReplicationServer" \
       expressionAllowed() \
       multivalued "Add another bootstrap replication server" \
       help "Bootstrap replication server(s) to contact periodically in order to discover remote servers" \
       description "Bootstrap replication server" \
       hostPrompt "Bootstrap replication server hostname" \
       portPrompt "Bootstrap replication server administration port"

define.enumStringParameter "rsConnectionSecurity", [
        "ssl":               "Use SSL",
        "start-tls":         "Use Start TLS" ] \
       help "Connection security type to use to secure communication with remote servers" \
       description "Securing connections to remote servers" \
       prompt "How should the proxy secure connections to remote servers?" \
       defaultValue "ssl"

define.stringParameter "keyManagerProvider" \
       expressionAllowed() \
       usage "Name" \
       help "Name of the key manager provider used for authenticating the proxy " \
          + "in mutual-TLS communications with backend server(s)" \
       defaultValueFromSetupTool "keyManagerProviderName" \
       defaultValue "PKCS12" \
       advanced()

define.stringParameter "trustManagerProvider" \
       expressionAllowed() \
       usage "Name" \
       help "Name of the trust manager provider used for trusting backend server(s) certificate(s)" \
       defaultValueFromSetupTool "trustManagerProviderName" \
       advanced()

define.stringParameter "certNickname" \
       expressionAllowed() \
       multivalued "Add another certificate nickname" \
       usage "Name" \
       help "Nickname(s) of the certificate(s) that should be sent to the server for SSL client authentication." \
       defaultValue "ssl-key-pair" \
       advanced()

define.stringParameter "primaryGroupId" \
       expressionAllowed() \
       help "Replication domain group ID of directory server replicas to contact when available before contacting " \
          + "other replicas. If this option is not specified then all replicas will be treated the same " \
          + "(i.e all remote servers are primary)" \
       description "Replication domain group ID (empty implies all servers are primary)" \
       prompt "To forward requests first to a primary group of directory server replicas, such as directory servers " \
              + "in the same data center as the proxy server, you must specify the replication domain group ID " \
              + "of those replicas. ",
              "If a valid group ID is set, the proxy only forwards requests to other server replicas when all " \
              + "primary server replicas in the specified group become unavailable.",
              "",
              "Leave the replication group ID empty to treat all server replicas the same.",
              "",
              "Replication group ID for primary servers" \
       defaultValue "" // All servers are primary

define.dnParameter "baseDn" \
       expressionAllowed() \
       multivalued "Add another base DN" \
       optional "You will be prompted for the LDAP request forwarding configuration. ",
                "You can configure the proxy to forward only requests with target DNs under specific base DNs. ",
                "If you choose not to do so then requests will be forwarded to all public naming contexts of " \
                + "the remote servers.",
                "Do you want to specify target DNs" \
       descriptionIfNoValueSet "Forward requests to all public naming contexts of the remote servers" \
       help "Base DN for user information in the Proxy Server." \
          + "Multiple base DNs may be provided by using this option multiple times." \
          + "If no base DNs are defined then the proxy will forward requests to all public naming contexts of " \
          + "the remote servers" \
       description "Forward requests under" \
       prompt "Base DN"

