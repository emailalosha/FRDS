/*
 * Copyright 2020 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

ds.config "create-backend", \
   "--backend-name", "proxyUser", \
   "--type", "ldif", \
   "--set", "enabled:true", \
   "--set", "base-dn:" + proxyUserDn, \
   "--set", "ldif-file:db/proxyUser/proxyUser.ldif"

ds.setWorkingBackend "proxyUser"
ds.importLdifTemplate "proxy-user.ldif"

// Compute dsconfig arguments from parameter values then create the global ACIs
arguments = [
        "set-access-control-handler-prop",
        "--add",
        // Allow proxy to read the server's configuration during service discovery.
        // Can be removed once OPENDJ-7302 is fixed.
        'global-aci:(target="ldap:///cn=config")(targetattr="*||+")' \
                 + '(version 3.0; acl "Proxy service discovery"; ' \
                 + 'allow (read,search,compare) userdn="ldap:///' + proxyUserDn + '";)'
]

baseDns = baseDn // 'baseDn' is a multivalued parameter

if (baseDns.isEmpty()) {
    arguments.add("--add")
    arguments.add('global-aci:(version 3.0; acl "Proxy as anyone"; allow(proxy) userdn="ldap:///' + proxyUserDn + '";)')
} else {
    for (dn in baseDns) {
        arguments.add("--add")
        arguments.add('global-aci:(target="ldap:///' + dn + '")' \
                      + '(version 3.0; acl "Proxy as users in ' + dn + '"; allow(proxy) userdn="ldap:///' + proxyUserDn + '";)')
    }
}

ds.config arguments
