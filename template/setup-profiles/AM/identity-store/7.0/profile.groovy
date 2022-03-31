/*
 * Copyright 2018 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

ds.addBackendWithDefaultUserIndexes backendName, baseDn

ds.addSchemaFiles()
ds.addIndex "sun-fm-saml2-nameid-infokey", "equality"
ds.importLdifTemplate "base-entries.ldif"
