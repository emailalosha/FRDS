--
-- Copyright 2018 ForgeRock AS. All Rights Reserved
--
-- Use of this code requires a commercial software license with ForgeRock AS.
-- or with one of its affiliates. All use shall be exclusively subject
-- to such license between the licensee and ForgeRock AS.
--

CREATE SCHEMA IF NOT EXISTS audit AUTHORIZATION audit;

-- -----------------------------------------------------
-- Table audit.ldapaccess
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS audit.ldapaccess (
  id VARCHAR(56) NOT NULL ,
  timestamp_ VARCHAR(29) NULL ,
  transactionid VARCHAR(255) NULL ,
  eventname VARCHAR(255) ,
  userid VARCHAR(255) NULL ,
  runAs VARCHAR(255) NULL ,
  server_ip VARCHAR(40) ,
  server_port INTEGER ,
  client_ip VARCHAR(40) ,
  client_port INTEGER ,
  request_protocol VARCHAR(255) ,
  request_operation VARCHAR(255) ,
  request_attr VARCHAR(255) NULL, 
  request_attrs VARCHAR(1024) NULL ,
  request_authType VARCHAR(255) NULL , 
  request_connId INTEGER , 
  request_msgId INTEGER , 
  request_controls VARCHAR(255) NULL , 
  request_deleteOldRDN BOOLEAN NULL , 
  request_dn VARCHAR(255) NULL , 
  request_filter VARCHAR(255) NULL , 
  request_idToAbandon INTEGER NULL ,
  request_message VARCHAR(1024) NULL ,
  request_name VARCHAR(255) NULL , 
  request_newRDN VARCHAR(255) NULL , 
  request_newSup VARCHAR(255) NULL , 
  request_oid VARCHAR(255) NULL , 
  request_opType VARCHAR(255) NULL , 
  request_scope VARCHAR(255) NULL ,
  request_version VARCHAR(255) NULL , 
  response_additionalItems VARCHAR(255) NULL , 
  response_controls VARCHAR(255) NULL , 
  response_failureReason VARCHAR(255) NULL , 
  response_maskedMessage VARCHAR(1024) NULL ,
  response_maskedResult VARCHAR(255) NULL , 
  response_nentries INTEGER NULL , 
  response_reason VARCHAR(255) NULL , 
  response_status VARCHAR(10) ,
  response_statuscode VARCHAR(255) ,
  response_elapsedtime INTEGER ,
  response_elapsedtimeunits VARCHAR(255) ,
  PRIMARY KEY (id)
);

CREATE INDEX idx_ldapaccess_dn ON audit.ldapaccess (request_dn ASC);
CREATE INDEX idx_ldapaccess_userid ON audit.ldapaccess (userid ASC);
COMMENT ON COLUMN audit.ldapaccess.timestamp_ IS 'Date format: 2011-09-09T14:58:17.654+02:00';

-- -----------------------------------------------------
-- Table audit.httpaccess
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS audit.httpaccess (
  id VARCHAR(56) NOT NULL ,
  timestamp_ VARCHAR(29) NULL,
  transactionid VARCHAR(255) NULL ,
  eventname VARCHAR(255) ,
  userid VARCHAR(255) NULL ,
  server_ip VARCHAR(40) ,
  server_port INTEGER ,
  client_ip VARCHAR(40) ,
  client_port INTEGER ,
  request_protocol VARCHAR(255) NULL ,
  request_operation VARCHAR(255) NULL ,
  request_secure BOOLEAN NULL ,
  request_method VARCHAR(7) NULL ,
  request_path VARCHAR(255) NULL ,
  request_queryparameters TEXT NULL ,
  request_headers TEXT NULL ,
  request_cookies TEXT NULL ,
  response_headers TEXT NULL ,
  response_status VARCHAR(10) ,
  response_statuscode VARCHAR(255) ,
  response_elapsedtime INTEGER ,
  response_elapsedtimeunits VARCHAR(255) ,
  PRIMARY KEY (id)
);

CREATE INDEX idx_httpaccess_userid ON audit.httpaccess (userid ASC);
COMMENT ON COLUMN audit.httpaccess.timestamp_ IS 'Date format: 2011-09-09T14:58:17.654+02:00';
