
@echo off
rem Copyright 2019 ForgeRock AS. All Rights Reserved
rem
rem Use of this code requires a commercial software license with ForgeRock AS.
rem or with one of its affiliates. All use shall be exclusively subject
rem to such license between the licensee and ForgeRock AS.

setlocal

set OPENDJ_INVOKE_CLASS="org.forgerock.opendj.tools.dsrepl.DsReplCli"
set SCRIPT_NAME=dsrepl
call "%~dp0\..\lib\_client-script.bat" %*
