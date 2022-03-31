
@echo off
REM Copyright 2018 ForgeRock AS. All Rights Reserved
REM
REM Use of this code requires a commercial software license with ForgeRock AS.
REM or with one of its affiliates. All use shall be exclusively subject
REM to such license between the licensee and ForgeRock AS.

setlocal

set OPENDJ_INVOKE_CLASS="org.opends.server.replication.server.changelog.file.ChangelogStat"
set SCRIPT_NAME=changelogstat
call "%~dp0\..\lib\_server-script.bat" %*

