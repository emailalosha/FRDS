/*
 * Copyright 2018-2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

ds.addBackend backendName, baseDn
ds.addSchemaFiles()

ds.config "create-schema-provider",
        "--provider-name", "CTS OAuth2 Grant Set Matching Rule",
        "--type", "json-equality-matching-rule",
        "--set", "enabled:true",
        "--set", "case-sensitive-strings:true",
        "--set", "ignore-white-space:true",
        "--set", "matching-rule-name:ctsOAuth2GrantSetEqualityMatch",
        "--set", "matching-rule-oid:1.3.6.1.4.1.36733.2.2.4.1",
        "--set", "json-keys:g"

// CTS v2 Indexes
ds.addIndex "coreTokenUserId", "equality"
ds.addIndex "coreTokenString01", "equality"
ds.addIndex "coreTokenString02", "equality"
ds.addIndex "coreTokenString03", "equality"
// There are no searches that filter on the following, so avoid maintenance overheads by not indexing them:
// coreTokenString04 stores the session's latestAccessTimeInMillis.
// coreTokenString05 stores the session's sessionID.
// coreTokenString06 stores the session's sessionHandle.
ds.addIndex "coreTokenString08", "equality"
ds.addIndex "coreTokenString09", "equality"
ds.addIndex "coreTokenString10", "equality"
// There are no searches that filter on the following, so avoid maintenance overheads by not indexing them:
// coreTokenString11 stores the session's realm.
// As the realm values are not distinct enough, indexing on it would cause a performance bottleneck on writes.
// coreTokenString12 stores the session's creationTime.
ds.addIndex "coreTokenString14", "equality"
ds.addIndex "coreTokenString15", "equality"
ds.addIndex "coreTokenInteger01", "equality"
ds.addIndex "coreTokenInteger02", "equality"
ds.addIndex "coreTokenInteger03", "equality"
ds.addIndex "coreTokenInteger04", "equality"
ds.addIndex "coreTokenInteger05", "equality"
// There are no searches that filter on the following, so avoid maintenance overheads by not indexing them:
// coreTokenInteger06 stores the session's maxSessionTimeInMinutes.
// coreTokenInteger07 stores the session's maxIdleTimeInMinutes.
ds.addIndex "coreTokenDate03", "equality"
ds.addIndex "coreTokenDate04", "equality"
ds.addIndex "coreTokenDate05", "equality"
ds.addIndex "coreTokenMultiString01", "equality"
ds.addIndex "coreTokenMultiString02", "equality"

ds.addIndex "coreTokenExpirationDate", "ordering"
ds.addIndex "coreTokenDate01", "ordering"
ds.addIndex "coreTokenDate02", "ordering"

// The cn and mail indexes are required for the following cert mapper:
// dn: cn=Subject Attribute to User Attribute,cn=Certificate Mappers,cn=config
ds.addIndex "cn", "equality"
ds.addIndex "mail", "equality"

// Disable cn=changelog for the CTS as it consumes resources and is not generally needed by applications
try {
    ds.config "set-replication-server-prop",
              "--provider-name", "Multimaster Synchronization",
              "--set", "changelog-enabled-excluded-domains:" + baseDn
} catch (ignored) {
    // Ignore errors as this indicates that the replication server has not been configured.
}

switch (tokenExpirationPolicy) {
case "am":
    // Let AM CTS reaper manage token expiration and deletion, nothing to configure on DJ side
    break
case "am-sessions-only":
    ds.addIndex "coreTokenTtlDate", "ordering"
    enableTtl backendName, "coreTokenTtlDate"
    break
case "ds":
    enableTtl backendName, "coreTokenExpirationDate"
    break
default:
    throw new IllegalArgumentException(
            "Invalid value '" + tokenExpirationPolicy + "' for 'tokenExpirationPolicy' parameter")
}

ds.importLdifTemplate "base-entries.ldif"

def enableTtl(String backendName, String ttlAttribute) {
    ds.config "set-backend-index-prop",
            "--backend-name", backendName,
            "--index-name", ttlAttribute,
            "--set", "ttl-enabled:true",
            "--set", "ttl-age:10s"
}
