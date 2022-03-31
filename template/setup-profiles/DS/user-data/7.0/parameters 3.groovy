/*
 * Copyright 2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

define.stringParameter "backendName" \
       usage "Name" \
       help "Name of the backend to be created by this profile" \
       defaultValue "userData" \
       advanced()

define.dnParameter "baseDn" \
       help "Base DN for your users data. " \
       description "Base DN" \
       prompt "Provide base DN for your users data"

define.pathParameter "ldifFile" \
       optional "You can specify LDIF files containing data to import. ",
        "If you do not specify any files, this profile creates entries for the specified base DN by default. ",
        "Import data from LDIF files" \
       descriptionIfNoValueSet "Only create entry for the specified base DN" \
       help "Path to an LDIF file containing data to import. " \
           + "Use this option multiple times to specify multiple LDIF files" \
       description "Import data from LDIF file" \
       prompt "LDIF file path" \
       multivalued "Import data from another LDIF file"

define.booleanParameter "addBaseEntry" \
       help "Create entries for specified base DNs when the 'ldifFile' parameter is not used. " \
          + "When this option is set to 'false' and the 'ldifFile' parameter is not used, create an empty backend." \
       defaultValue true \
       advanced()
