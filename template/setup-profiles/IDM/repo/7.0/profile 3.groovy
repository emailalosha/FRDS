/*
 * Copyright 2018-2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

def addJsonEqualityMatchingRule(String providerName, String name, String oid, Collection<String> indexedFields) {
    def arguments = [ "create-schema-provider",
                      "--type", "json-query-equality-matching-rule",
                      "--set", "enabled:true",
                      "--set", "case-sensitive-strings:false",
                      "--set", "ignore-white-space:true",
                      "--provider-name", providerName,
                      "--set", "matching-rule-name:" + name,
                      "--set", "matching-rule-oid:" + oid ]
    for (String indexedField in indexedFields) {
        arguments.add("--set")
        arguments.add("indexed-field:" + indexedField)
    }
    ds.config arguments
}

addJsonEqualityMatchingRule "IDM managed/user Json Schema",
                            "caseIgnoreJsonQueryMatchManagedUser",
                            "1.3.6.1.4.1.36733.2.3.4.1",
                            [ "userName", "givenName", "sn", "mail", "accountStatus"]

addJsonEqualityMatchingRule "IDM managed/role Json Schema",
                            "caseIgnoreJsonQueryMatchManagedRole",
                            "1.3.6.1.4.1.36733.2.3.4.2",
                            [ "condition/**", "temporalConstraints/**" ]

addJsonEqualityMatchingRule "IDM Relationship Json Schema",
                            "caseIgnoreJsonQueryMatchRelationship",
                            "1.3.6.1.4.1.36733.2.3.4.3",
                            [ "firstResourceCollection", "firstResourceId", "firstPropertyName",
                              "secondResourceCollection", "secondResourceId", "secondPropertyName" ]

addJsonEqualityMatchingRule "IDM Cluster Object Json Schema",
                            "caseIgnoreJsonQueryMatchClusterObject",
                            "1.3.6.1.4.1.36733.2.3.4.4",
                            [ "timestamp", "state"]

ds.addBackendWithDefaultUserIndexes backendName, "dc=openidm," + domain

ds.addSchemaFiles()

ds.addIndex "fr-idm-uuid", "equality"
ds.addIndex "fr-idm-managed-user-json", "equality"
ds.addIndex "fr-idm-managed-role-json", "equality"
ds.addIndex "fr-idm-relationship-json", "equality"
ds.addIndex "fr-idm-cluster-json", "equality"
ds.addIndex "fr-idm-json", "equality"
ds.addIndex "fr-idm-link-type", "equality"
ds.addIndex "fr-idm-link-firstid", "equality"
ds.addIndex "fr-idm-link-secondid", "equality"
ds.addIndex "fr-idm-link-qualifier", "equality"
ds.addIndex "fr-idm-link-firstid-constraint", "equality"
ds.addIndex "fr-idm-link-secondid-constraint", "equality"
ds.addIndex "fr-idm-lock-nodeid", "equality"
ds.addIndex "fr-idm-syncqueue-mapping", "equality"
ds.addIndex "fr-idm-syncqueue-resourceid", "equality"
ds.addIndex "fr-idm-syncqueue-state", "equality"
ds.addIndex "fr-idm-syncqueue-createdate", "equality"
ds.addIndex "fr-idm-custom-attrs", "equality"
ds.addIndex "fr-idm-managed-user-custom-attrs", "equality"

ds.config "create-backend-index",
        "--index-name", "fr-idm-managed-user-roles",
        "--backend-name", backendName,
        "--set", "index-type:extensible",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9"
ds.config "create-backend-index",
        "--index-name", "fr-idm-managed-user-manager",
        "--backend-name", backendName,
        "--set", "index-type:extensible",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9"
ds.config "create-backend-index",
        "--index-name", "fr-idm-managed-role-assignments",
        "--backend-name", backendName,
        "--set", "index-type:extensible",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9"
ds.config "create-backend-index",
        "--index-name", "fr-idm-managed-user-meta",
        "--backend-name", backendName,
        "--set", "index-type:extensible",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9"
ds.config "create-backend-index",
        "--index-name", "fr-idm-managed-user-notifications",
        "--backend-name", backendName,
        "--set", "index-type:extensible",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9"
ds.config "create-backend-index",
        "--index-name", "fr-idm-internal-user-authzroles-managed-role",
        "--backend-name", backendName,
        "--set", "index-type:extensible",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9"
ds.config "create-backend-index",
        "--index-name", "fr-idm-internal-user-authzroles-internal-role",
        "--backend-name", backendName,
        "--set", "index-type:extensible",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9"
ds.config "create-backend-index",
        "--index-name", "fr-idm-internal-role-authzmembers-managed-user",
        "--backend-name", backendName,
        "--set", "index-type:extensible",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9"
ds.config "create-backend-index",
        "--index-name", "fr-idm-internal-role-authzmembers-internal-user",
        "--backend-name", backendName,
        "--set", "index-type:extensible",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9"
ds.config "create-backend-index",
        "--index-name", "fr-idm-managed-user-authzroles-internal-role",
        "--backend-name", backendName,
        "--set", "index-type:extensible",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9"
ds.config "create-backend-index",
        "--index-name", "fr-idm-managed-user-authzroles-managed-role",
        "--backend-name", backendName,
        "--set", "index-type:extensible",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.7",
        "--set", "index-extensible-matching-rule:1.3.6.1.4.1.36733.2.1.4.9"

// create vlv index on fr-idm-syncqueue-createdate to support sorting of potentially > 4000 entries
ds.config "create-backend-vlv-index",
        "--index-name", "syncqueue-by-create-date",
        "--backend-name", backendName,
        "--set", "base-dn:ou=queue,ou=sync,dc=openidm," + domain,
        "--set", "sort-order:+fr-idm-syncqueue-createdate",
        "--set", "scope:single-level",
        "--set", "filter:(&)"

ds.config "create-plugin",
        "--set", "enabled:true",
        "--set", "type:fr-idm-link-firstid-constraint",
        "--set", "base-dn:ou=links,dc=openidm," + domain,
        "--type", "unique-attribute",
        "--plugin-name", "FirstId Links Unique Atttribute"

ds.config "create-plugin",
        "--set", "enabled:true",
        "--set", "type:fr-idm-link-secondid-constraint",
        "--set", "base-dn:ou=links,dc=openidm," + domain,
        "--type", "unique-attribute",
        "--plugin-name", "SecondId Links Unique Atttribute"

ds.importLdifTemplate "base-entries.ldif"
