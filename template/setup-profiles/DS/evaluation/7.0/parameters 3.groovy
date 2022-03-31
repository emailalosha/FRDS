/*
 * Copyright 2018-2019 ForgeRock AS. All Rights Reserved
 *
 * Use of this code requires a commercial software license with ForgeRock AS.
 * or with one of its affiliates. All use shall be exclusively subject
 * to such license between the licensee and ForgeRock AS.
 */

define.integerParameter "generatedUsers" \
       help "Specifies the number of generated user entries to import. " \
          + "The evaluation profile always imports entries used in documentation examples, such as uid=bjensen. " \
          + "Optional generated users have RDNs of the form uid=user.%d, yielding uid=user.0, uid=user.1, " \
          + "uid=user.2 and so on. " \
          + "All generated users have the same password, \"password\". " \
          + "Generated user entries are a good fit for performance testing with tools like addrate and searchrate" \
       description "Number of additional sample entries to import" \
       prompt "Import generated user entries (uid=user.0, uid=user.1, uid=user.2 and so on)? " \
            + "Generated user entries are a good fit for performance testing with tools like addrate and searchrate.",
              "",
              "Enter 0 to disable import of generated entries. ",
              "Number of generated users to import" \
       defaultValue 100_000
