/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

import java.nio.file.Path


ds.addBackendWithDefaultUserIndexes backendName, baseDn

List<Path> ldifFiles = ldifFile // 'ldifFile' is a multivalued parameter
if (!ldifFiles.isEmpty()) {
     ds.importLdif ldifFiles
} else if (addBaseEntry) {
     ds.importBaseEntry baseDn
}
