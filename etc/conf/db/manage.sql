-- Slette alle tabeller

DROP TABLE mem CASCADE;
DROP TABLE swportblocked CASCADE;
DROP TABLE swportallowedvlan CASCADE;
DROP TABLE swportvlan CASCADE;
DROP TABLE gwport CASCADE;
DROP TABLE vlan CASCADE;
DROP TABLE prefix CASCADE;
DROP TABLE swport CASCADE;
DROP TABLE module CASCADE;
DROP TABLE netboxcategory;
DROP TABLE netboxinfo;
DROP TABLE netbox CASCADE;
DROP TABLE cat CASCADE;
DROP TABLE device CASCADE;
DROP TABLE product CASCADE;
DROP TABLE vendor CASCADE;
DROP TABLE type CASCADE;
DROP TABLE snmpoid CASCADE;
DROP TABLE typesnmpoid CASCADE;
DROP TABLE typegroup CASCADE;
DROP TABLE room CASCADE;
DROP TABLE location CASCADE;
DROP TABLE usage CASCADE;
DROP TABLE org CASCADE;
DROP TABLE port2off CASCADE;

DROP TABLE swp_netbox CASCADE;

DROP TABLE netboxdisk CASCADE;
DROP TABLE netboxinterface CASCADE;

-------VP - fingra fra fatet, Sigurd:
DROP TABLE vp_netbox_xy CASCADE;
DROP TABLE vp_netbox_grp CASCADE;
DROP TABLE vp_netbox_grp_info CASCADE;

-- Slette alle sekvenser
DROP SEQUENCE netbox_netboxid_seq;
DROP SEQUENCE gwport_gwportid_seq;
DROP SEQUENCE prefix_prefixid_seq;
DROP SEQUENCE type_typeid_seq;
DROP SEQUENCE swport_swportid_seq;
DROP SEQUENCE swp_netbox_swp_netboxid_seq;
DROP SEQUENCE device_deviceid_seq;
DROP SEQUENCE product_productid_seq;
DROP SEQUENCE module_moduleid_seq;
DROP SEQUENCE mem_memid_seq;

-------------
DROP SEQUENCE vp_netbox_grp_vp_netbox_grp_seq;
DROP SEQUENCE vp_netbox_xy_vp_netbox_xyid_seq;

-- Slette alle indekser

DROP TABLE status CASCADE;
DROP SEQUENCE status_statusid_seq;

CREATE TABLE status (
  statusid SERIAL PRIMARY KEY,
  trapsource VARCHAR NOT NULL,
  trap VARCHAR NOT NULL,
  trapdescr VARCHAR,
  tilstandsfull CHAR(1) CHECK (tilstandsfull='Y' OR tilstandsfull='N') NOT NULL,
  boksid INT2,
  fra TIMESTAMP NOT NULL,
  til TIMESTAMP
);

------------------------------------------

-- Definerer gruppe nav:
DROP GROUP nav;
CREATE GROUP nav;

------------------------------------------------------------------------------------------

CREATE TABLE org (
  orgid VARCHAR(10) PRIMARY KEY,
  parent VARCHAR(10) REFERENCES org (orgid),
  descr VARCHAR,
  org2 VARCHAR,
  org3 VARCHAR,
  org4 VARCHAR
);


CREATE TABLE usage (
  usageid VARCHAR(10) PRIMARY KEY,
  descr VARCHAR NOT NULL
);


CREATE TABLE location (
  locationid VARCHAR(12) PRIMARY KEY,
  descr VARCHAR NOT NULL
);

CREATE TABLE room (
  roomid VARCHAR(10) PRIMARY KEY,
  locationid VARCHAR(12) REFERENCES location,
  descr VARCHAR,
  room2 VARCHAR,
  room3 VARCHAR,
  room4 VARCHAR,
  room5 VARCHAR
);

CREATE TABLE vlan (
  vlan INT4 PRIMARY KEY,
  nettype VARCHAR NOT NULL,
  orgid VARCHAR(10) REFERENCES org,
  usageid VARCHAR(10) REFERENCES usage,
  netident VARCHAR,
  description VARCHAR
);  

CREATE TABLE prefix (
  prefixid SERIAL PRIMARY KEY,
  netaddr CIDR NOT NULL,
  rootgwid INT4 UNIQUE,
  active_ip_cnt INT4,
  max_ip_cnt INT4,
  to_gw VARCHAR,
  vlan INT4 REFERENCES vlan ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE vendor (
  vendorid VARCHAR(15) PRIMARY KEY
);

CREATE TABLE typegroup (
  typegroupid VARCHAR(15) PRIMARY KEY,
  descr VARCHAR
);

CREATE TABLE cat (
  catid VARCHAR(8) PRIMARY KEY,
  descr VARCHAR
);

CREATE TABLE product (
  productid SERIAL PRIMARY KEY,
  vendorid VARCHAR(15) NOT NULL REFERENCES vendor ON UPDATE CASCADE ON DELETE CASCADE,
  productno VARCHAR NOT NULL,
  descr VARCHAR,
  UNIQUE (vendorid,productno)
);


CREATE TABLE device (
  deviceid SERIAL PRIMARY KEY,
  productid INT4 REFERENCES product ON UPDATE CASCADE ON DELETE SET NULL,
  serial VARCHAR,
  hw_ver VARCHAR,
  sw_ver VARCHAR,
  UNIQUE(serial)
-- productid burde v�rt NOT NULL, men det g�r ikke n�
);
-- tror ikke uniquene jeg har lagt inn skader.

CREATE TABLE type (
  typeid SERIAL PRIMARY KEY,
  vendorid VARCHAR(15) NOT NULL REFERENCES vendor ON UPDATE CASCADE ON DELETE CASCADE,
  typename VARCHAR(10) NOT NULL,
  typegroupid VARCHAR(15) NOT NULL REFERENCES typegroup ON UPDATE CASCADE ON DELETE CASCADE,
  sysObjectID VARCHAR NOT NULL,
  cdp BOOL DEFAULT false,
  tftp BOOL DEFAULT false,
  frequency INT4,
  descr VARCHAR,
  UNIQUE (vendorid,typename)
);

CREATE TABLE snmpoid (
	snmpoidid SERIAL PRIMARY KEY,
	oidkey VARCHAR NOT NULL,
	snmpoid VARCHAR NOT NULL,
	descr VARCHAR
);

CREATE TABLE typesnmpoid (
	typeid INT4 REFERENCES type ON UPDATE CASCADE ON DELETE CASCADE,
	snmpoidid INT4 REFERENCES snmpoid ON UPDATE CASCADE ON DELETE CASCADE,
	frequency INT4,
	UNIQUE(typeid, snmpoidid)
);  

CREATE TABLE netbox (
  netboxid SERIAL PRIMARY KEY,
  ip INET NOT NULL,
  roomid VARCHAR(10) NOT NULL REFERENCES room,
  typeid INT4 REFERENCES type ON UPDATE CASCADE ON DELETE CASCADE,
  deviceid INT4 NOT NULL REFERENCES device ON UPDATE CASCADE ON DELETE CASCADE,
  sysname VARCHAR UNIQUE,
  catid VARCHAR(8) NOT NULL REFERENCES cat ON UPDATE CASCADE ON DELETE CASCADE,
  subcat VARCHAR,
  orgid VARCHAR(10) NOT NULL REFERENCES org,
  ro VARCHAR,
  rw VARCHAR,
  prefixid INT4 REFERENCES prefix ON UPDATE CASCADE ON DELETE SET null,
  up CHAR(1) NOT NULL DEFAULT 'y' CHECK (up='y' OR up='n' OR up='s'), -- y=up, n=down, s=shadow
  snmp_version INT4 NOT NULL DEFAULT 1,
  snmp_agent VARCHAR,
  UNIQUE(ip)
);
CREATE TABLE netboxcategory (
  netboxid INT4 NOT NULL REFERENCES netbox ON UPDATE CASCADE ON DELETE CASCADE,
  category VARCHAR NOT NULL,
  PRIMARY KEY(netboxid, category)
);
GRANT ALL ON netboxcategory TO navall;
GRANT ALL ON netboxcategory TO getDeviceData;


CREATE TABLE netboxinfo (
	netboxinfoid SERIAL PRIMARY KEY,
  netboxid INT4 NOT NULL REFERENCES netbox ON UPDATE CASCADE ON DELETE CASCADE,
  key VARCHAR,
  var VARCHAR NOT NULL,
  val TEXT NOT NULL,
	UNIQUE(netboxid, key, var, val)
);

-- netboxdisk and netboxinterface should be obsoleted by netboxinfo
--
--CREATE TABLE netboxdisk (
--  netboxid INT4 NOT NULL REFERENCES netbox ON UPDATE CASCADE ON DELETE CASCADE,
--  path VARCHAR NOT NULL,
--  blocksize INT4 NOT NULL DEFAULT 1024,
--  PRIMARY KEY (netboxid, path)
--);
--CREATE TABLE netboxinterface (
--  netboxid INT4 NOT NULL REFERENCES netbox ON UPDATE CASCADE ON DELETE CASCADE,
--  interf VARCHAR NOT NULL,
--  PRIMARY KEY (netboxid, interf)
--);

CREATE TABLE module (
  moduleid SERIAL PRIMARY KEY,
  deviceid INT4 NOT NULL REFERENCES device ON UPDATE CASCADE ON DELETE CASCADE,
  netboxid INT4 NOT NULL REFERENCES netbox ON UPDATE CASCADE ON DELETE CASCADE,
  module VARCHAR(4) NOT NULL,
  submodule VARCHAR, -- what is this used for?
  up CHAR(1) NOT NULL DEFAULT 'y' CHECK (up='y' OR up='n'), -- y=up, n=down
  downsince TIMESTAMP,
  UNIQUE (netboxid, module)
);

CREATE TABLE mem (
  memid SERIAL PRIMARY KEY,
  netboxid INT4 NOT NULL REFERENCES netbox ON UPDATE CASCADE ON DELETE CASCADE,
  memtype VARCHAR NOT NULL,
  device VARCHAR NOT NULL,
  size INT4 NOT NULL,
  used INT4
);


CREATE TABLE swp_netbox (
  swp_netboxid SERIAL PRIMARY KEY,
  netboxid INT4 NOT NULL REFERENCES netbox ON UPDATE CASCADE ON DELETE CASCADE,
  module VARCHAR(4) NOT NULL,
  port INT4 NOT NULL,
  to_netboxid INT4 NOT NULL REFERENCES netbox ON UPDATE CASCADE ON DELETE CASCADE,
  to_module VARCHAR(4),
  to_port INT4,
  misscnt INT4 NOT NULL DEFAULT '0',
  UNIQUE(netboxid, module, port, to_netboxid)
);

CREATE TABLE swport (
  swportid SERIAL PRIMARY KEY,
  moduleid INT4 NOT NULL REFERENCES module ON UPDATE CASCADE ON DELETE CASCADE,
  port INT4 NOT NULL,
  ifindex INT4 NOT NULL,
  link CHAR(1) NOT NULL DEFAULT 'y' CHECK (link='y' OR link='n' OR link='d'), -- y=up, n=down (operDown), d=down (admDown)
  speed DOUBLE PRECISION NOT NULL,
  duplex CHAR(1) NOT NULL CHECK (duplex='f' OR duplex='h'), -- f=full, h=half
  media VARCHAR,
  trunk BOOL NOT NULL DEFAULT false,
  portname VARCHAR,
  to_netboxid INT4 REFERENCES netbox ON UPDATE CASCADE ON DELETE SET NULL,
  to_swportid INT4 REFERENCES swport (swportid) ON UPDATE CASCADE ON DELETE SET NULL,
  to_catid VARCHAR(8),
  UNIQUE(moduleid, port)
);

CREATE TABLE gwport (
  gwportid SERIAL PRIMARY KEY,
  moduleid INT4 NOT NULL REFERENCES module ON UPDATE CASCADE ON DELETE CASCADE,
  prefixid INT4 REFERENCES prefix ON UPDATE CASCADE ON DELETE SET null,
  ifindex INT4 NOT NULL,
  masterindex INT4,
  interface VARCHAR,
  gwip INET,
  speed DOUBLE PRECISION NOT NULL,
  ospf INT4,
  to_netboxid INT4 REFERENCES netbox ON UPDATE CASCADE ON DELETE SET NULL,
  to_swportid INT4 REFERENCES swport (swportid) ON UPDATE CASCADE ON DELETE SET NULL
);
CREATE INDEX gwport_to_swportid_btree ON gwport USING btree (to_swportid);

CREATE TABLE swportvlan (
  swportvlanid SERIAL PRIMARY KEY,
  swportid INT4 NOT NULL REFERENCES swport ON UPDATE CASCADE ON DELETE CASCADE,
  vlan INT4 NOT NULL REFERENCES vlan ON UPDATE CASCADE ON DELETE CASCADE,
  direction CHAR(1) NOT NULL DEFAULT 'x', -- u=up, d=down, ...
  UNIQUE (swportid, vlan)
);

CREATE TABLE swportallowedvlan (
  swportid INT4 NOT NULL PRIMARY KEY REFERENCES swport ON UPDATE CASCADE ON DELETE CASCADE,
  hexstring VARCHAR
);


CREATE TABLE swportblocked (
  swportid INT4 NOT NULL REFERENCES swport ON UPDATE CASCADE ON DELETE CASCADE,
  vlan INT4 NOT NULL,
  PRIMARY KEY(swportid, vlan)
);


CREATE TABLE port2off (
  swportid INTEGER REFERENCES swport(swportid) ON UPDATE CASCADE ON DELETE SET NULL,
  roomid VARHCAR(10) NOT NULL REFERENCES room(roomid) ON UPDATE CASCADE ON DELETE CASCADE,
  socket VARCHAR NOT NULL,
  office VARCHAR,
  PRIMARY KEY(roomid,socket)
);



GRANT ALL ON org TO navall;
GRANT ALL ON usage TO navall;
GRANT ALL ON location TO navall;
GRANT ALL ON room TO navall;
GRANT ALL ON prefix TO navall;
GRANT ALL ON type TO navall;
GRANT ALL ON netbox TO navall;
GRANT ALL ON netboxinfo TO navall;
GRANT ALL ON module TO navall;
GRANT ALL ON mem TO navall;
GRANT ALL ON gwport TO navall;
GRANT ALL ON swport TO navall;
GRANT ALL ON swportvlan TO navall;
GRANT ALL ON swportallowedvlan TO navall;
GRANT ALL ON vendor TO navall;
GRANT ALL ON product TO navall;
GRANT ALL ON device TO navall;
GRANT ALL ON cat TO navall;
GRANT ALL ON typegroup TO navall;
GRANT ALL ON vlan TO navall;
GRANT ALL ON port2off TO navall;

GRANT ALL ON netbox_netboxid_seq TO navall;
GRANT ALL ON gwport_gwportid_seq TO navall;
GRANT ALL ON prefix_prefixid_seq TO navall;
GRANT ALL ON swport_swportid_seq TO navall;
GRANT ALL ON module_moduleid_seq TO navall;
GRANT ALL ON mem_memid_seq TO navall;
GRANT ALL ON product_productid_seq TO navall;
GRANT ALL ON device_deviceid_seq TO navall;
GRANT ALL ON type_typeid_seq TO navall;

------------------------------------------------------------------
------------------------------------------------------------------

DROP TABLE arp CASCADE;
DROP TABLE cam CASCADE;
DROP VIEW netboxmac CASCADE;
DROP TABLE eventtype CASCADE;

DROP SEQUENCE arp_arpid_seq; 
DROP SEQUENCE cam_camid_seq; 

DROP FUNCTION netboxid_null_upd_end_time();

-- arp og cam trenger en spesiell funksjon for � v�re sikker p� at records alltid blir avsluttet
-- Merk at "createlang -U manage -d manage plpgsql" m� kj�res f�rst (passord m� skrives inn flere ganger!!)
CREATE FUNCTION netboxid_null_upd_end_time () RETURNS opaque AS
  'BEGIN
     IF old.netboxid IS NOT NULL AND new.netboxid IS NULL THEN
       new.end_time = current_timestamp;
     END IF;
     RETURN new;
   end' LANGUAGE plpgsql;

CREATE TABLE arp (
  arpid SERIAL PRIMARY KEY,
  netboxid INT4 REFERENCES netbox ON UPDATE CASCADE ON DELETE SET NULL,
  prefixid INT4 REFERENCES prefix ON UPDATE CASCADE ON DELETE SET NULL,
  sysname VARCHAR NOT NULL,
  ip INET NOT NULL,
  mac CHAR(12) NOT NULL,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP NOT NULL DEFAULT 'infinity'
);
CREATE TRIGGER update_arp BEFORE UPDATE ON arp FOR EACH ROW EXECUTE PROCEDURE netboxid_null_upd_end_time();
CREATE INDEX arp_mac_btree ON arp USING btree (mac);
CREATE INDEX arp_ip_btree ON arp USING btree (ip);
CREATE INDEX arp_start_time_btree ON arp USING btree (start_time);
CREATE INDEX arp_end_time_btree ON arp USING btree (end_time);

CREATE TABLE cam (
  camid SERIAL PRIMARY KEY,
  netboxid INT4 REFERENCES netbox ON UPDATE CASCADE ON DELETE SET NULL,
  sysname VARCHAR NOT NULL,
  module VARCHAR(4) NOT NULL,
  port INT4 NOT NULL,
  mac CHAR(12) NOT NULL,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP NOT NULL DEFAULT 'infinity',
  misscnt INT4 DEFAULT '0',
  UNIQUE(netboxid,sysname,module,port,mac,start_time)
);
CREATE TRIGGER update_cam BEFORE UPDATE ON cam FOR EACH ROW EXECUTE PROCEDURE netboxid_null_upd_end_time();
CREATE INDEX cam_mac_btree ON cam USING btree (mac);
CREATE INDEX cam_start_time_btree ON cam USING btree (start_time);
CREATE INDEX cam_end_time_btree ON cam USING btree (end_time);
CREATE INDEX cam_misscnt_btree ON cam USING btree (misscnt);

GRANT all ON arp TO navall;
GRANT all ON arp_arpid_seq TO navall;
GRANT SELECT ON cam TO navall;

-- VIEWs -----------------------
CREATE VIEW netboxmac AS  
(SELECT DISTINCT ON (mac) netbox.netboxid,mac
 FROM arp
 JOIN netbox USING (ip)
 WHERE arp.end_time='infinity')
UNION
(SELECT DISTINCT ON (mac) module.netboxid,mac
 FROM arp
 JOIN gwport ON (arp.ip=gwport.gwip)
 JOIN module USING (moduleid)
 WHERE arp.end_time='infinity');


-------- vlanPlot tabeller ------
CREATE TABLE vp_netbox_grp_info (
  vp_netbox_grp_infoid SERIAL PRIMARY KEY,
  name VARCHAR NOT NULL,
  x INT4 NOT NULL DEFAULT '0',
  y INT4 NOT NULL DEFAULT '0'
);
-- Default nett
INSERT INTO vp_netbox_grp_info (vp_netbox_grp_infoid,name) VALUES (0,'Bynett');
INSERT INTO vp_netbox_grp_info (name) VALUES ('Kjernenett');
INSERT INTO vp_netbox_grp_info (name) VALUES ('Testnett');

CREATE TABLE vp_netbox_grp (
  vp_netbox_grp_infoid INT4 REFERENCES vp_netbox_grp_info ON UPDATE CASCADE ON DELETE CASCADE,
  pnetboxid INT4 NOT NULL,
  UNIQUE(vp_netbox_grp_infoid, pnetboxid)
);

CREATE TABLE vp_netbox_xy (
  vp_netbox_xyid SERIAL PRIMARY KEY, 
  pnetboxid INT4 NOT NULL,
  x INT4 NOT NULL,
  y INT4 NOT NULL,
  vp_netbox_grp_infoid INT4 NOT NULL REFERENCES vp_netbox_grp_info ON UPDATE CASCADE ON DELETE CASCADE,
  UNIQUE(pnetboxid, vp_netbox_grp_infoid)
);

-- vPServer bruker
-- CREATE USER vpserver WITH PASSWORD '' NOCREATEDB NOCREATEUSER;
-- CREATE USER navadmin WITH PASSWORD '' NOCREATEDB NOCREATEUSER;
-- CREATE USER getboksmacs WITH PASSWORD '' NOCREATEDB NOCREATEUSER;
-- CREATE USER getportdata WITH PASSWORD '' NOCREATEDB NOCREATEUSER;

GRANT SELECT ON netbox TO vPServer;
GRANT SELECT ON netboxinfo TO vPServer;
GRANT SELECT ON gwport TO vPServer;
GRANT SELECT ON prefix TO vPServer;
GRANT SELECT ON vlan TO vPServer;
GRANT SELECT ON swport TO vPServer;
GRANT SELECT ON swportvlan TO vPServer;
GRANT SELECT,UPDATE ON vp_netbox_grp_info TO vPServer;
GRANT ALL    ON vp_netbox_grp TO vPServer;
GRANT ALL    ON vp_netbox_xy TO vPServer;
GRANT ALL    ON vp_netbox_xy_vp_netbox_xyid_seq TO vPServer;

GRANT SELECT ON netbox TO navadmin;
GRANT SELECT ON type TO navadmin;
GRANT SELECT ON netboxmac TO navadmin;
GRANT SELECT ON gwport TO navadmin;
GRANT SELECT ON vlan TO navadmin;
GRANT SELECT ON prefix TO navadmin;
GRANT SELECT ON module TO navadmin;
GRANT ALL    ON swport TO navadmin;
GRANT ALL    ON swport_swportid_seq TO navadmin;
GRANT ALL    ON swportvlan TO navadmin;
GRANT SELECT,DELETE ON swp_netbox TO navadmin;
GRANT ALL    ON swportallowedvlan TO navadmin;
GRANT SELECT ON swportblocked TO navadmin;

GRANT SELECT ON netbox TO getBoksMacs;
GRANT SELECT ON type TO getBoksMacs;
GRANT SELECT ON module TO getBoksMacs;
GRANT SELECT ON swport TO getBoksMacs;
GRANT SELECT ON vlan TO getBoksMacs;
GRANT ALL    ON swportvlan TO getBoksMacs;
GRANT SELECT ON swportallowedvlan TO getBoksMacs;
GRANT SELECT,UPDATE ON gwport TO getBoksMacs;
GRANT SELECT ON prefix TO getBoksMacs;
GRANT SELECT ON netboxmac TO getBoksMacs;
GRANT ALL    ON swp_netbox TO getBoksMacs;
GRANT ALL    ON swp_netbox_swp_netboxid_seq TO getBoksMacs;
GRANT ALL    ON swportblocked TO getBoksMacs;
GRANT ALL    ON cam TO getBoksMacs;
GRANT ALL    ON cam_camid_seq TO getBoksMacs;

GRANT ALL    ON device TO getDeviceData;
GRANT ALL    ON device_deviceid_seq TO getDeviceData;
GRANT SELECT,UPDATE ON netbox TO getDeviceData;
GRANT SELECT,UPDATE ON netboxinfo TO getDeviceData;
GRANT SELECT ON type TO getDeviceData;
GRANT ALL    ON netboxdisk TO getDeviceData;
GRANT ALL    ON netboxinterface TO getDeviceData;
GRANT ALL    ON cat TO getDeviceData;
GRANT ALL    ON module TO getDeviceData;
GRANT ALL    ON module_moduleid_seq TO getDeviceData;
GRANT ALL    ON swport TO getDeviceData;
GRANT ALL    ON swport_swportid_seq TO getDeviceData;
GRANT ALL    ON vlan TO getDeviceData;
GRANT ALL    ON swportvlan TO getDeviceData;
GRANT ALL    ON swportallowedvlan TO getDeviceData;

-------- vlanPlot end ------

------------------------------------------------------------------------------------------
-- rrd metadb tables
------------------------------------------------------------------------------------------

DROP TABLE subsystem CASCADE;
DROP TABLE rrd_file CASCADE;
DROP TABLE rrd_datasource CASCADE;

DROP SEQUENCE rrd_file_seq;
DROP SEQUENCE rrd_datasource_seq;

-- This table contains the different systems that has rrd-data.
-- Replaces table eventprocess
CREATE TABLE subsystem (
  name      VARCHAR PRIMARY KEY, -- name of the system, e.g. Cricket
  descr     VARCHAR  -- description of the system
);

INSERT INTO subsystem (name) VALUES ('eventEngine');
INSERT INTO subsystem (name) VALUES ('pping');
INSERT INTO subsystem (name) VALUES ('serviceping');
INSERT INTO subsystem (name) VALUES ('moduleMon');
INSERT INTO subsystem (name) VALUES ('thresholdMon');
INSERT INTO subsystem (name) VALUES ('trapParser');
INSERT INTO subsystem (name) VALUES ('cricket');
INSERT INTO subsystem (name) VALUES ('deviceTracker');

-- Each rrdfile should be registered here. We need the path to find it,
-- and also a link to which unit or service it has data about to easily be
-- able to select all relevant files to a unit or service. Key and value
-- are meant to be combined and thereby point to a specific row in the db.
CREATE TABLE rrd_file (
  rrd_fileid    SERIAL PRIMARY KEY,
  path      VARCHAR NOT NULL, -- complete path to the rrdfile
  filename  VARCHAR NOT NULL, -- name of the rrdfile (including the .rrd)
  step      INT, -- the number of seconds between each update
  subsystem VARCHAR REFERENCES subsystem (name) ON UPDATE CASCADE ON DELETE CASCADE,
  netboxid  INT REFERENCES netbox ON UPDATE CASCADE ON DELETE SET NULL,
  key       VARCHAR,
  value     VARCHAR
);

-- Each datasource for each rrdfile is registered here. We need the name and
-- desc for instance in Cricket. Cricket has the name ds0, ds1 and so on, and
-- to understand what that is for humans we need the descr.
CREATE TABLE rrd_datasource (
  rrd_datasourceid  SERIAL PRIMARY KEY,
  rrd_fileid        INT REFERENCES rrd_file ON UPDATE CASCADE ON DELETE CASCADE,
  name          VARCHAR, -- name of the datasource in the file
  descr         VARCHAR, -- human-understandable name of the datasource
  dstype        VARCHAR CHECK (dstype='GAUGE' OR dstype='DERIVE' OR dstype='COUNTER' OR dstype='ABSOLUTE'),
  units         VARCHAR -- textual decription of the y-axis (percent, kilo, giga, etc.)
);

GRANT ALL ON rrd_file TO rrduser;
GRANT ALL ON rrd_file TO manage;
GRANT ALL ON rrd_datasource TO rrduser;
GRANT ALL ON rrd_datasource TO manage;
GRANT SELECT ON subsystem TO rrduser;
GRANT ALL ON subsystem TO manage;

------------------------------------------------------------------------------------------
-- event system tables
------------------------------------------------------------------------------------------

-- event tables
CREATE TABLE eventtype (
  eventtypeid VARCHAR(32) PRIMARY KEY,
  eventtypedesc VARCHAR,
  statefull CHAR(1) NOT NULL CHECK (statefull='y' OR statefull='n')
);
INSERT INTO eventtype (eventtypeid,eventtypedesc,statefull) VALUES 
	('boxState','Tells us whether a network-unit is down or up.','y');
INSERT INTO eventtype (eventtypeid,eventtypedesc,statefull) VALUES 
	('serviceState','Tells us whether a service on a server is up or down.','y');
INSERT INTO eventtype (eventtypeid,eventtypedesc,statefull) VALUES
	('moduleState','Tells us whether a module in a device is working or not.','y');
INSERT INTO eventtype (eventtypeid,eventtypedesc,statefull) VALUES
	('thresholdState','Tells us whether the load has passed a certain threshold.','y');
INSERT INTO eventtype (eventtypeid,eventtypedesc,statefull) VALUES
	('linkState','Tells us whether a link is up or down.','y');
INSERT INTO eventtype (eventtypeid,eventtypedesc,statefull) VALUES
	('coldStart','Tells us that a network-unit has done a coldstart','n');
INSERT INTO eventtype (eventtypeid,eventtypedesc,statefull) VALUES
	('warmStart','Tells us that a network-unit has done a warmstart','n');
INSERT INTO eventtype (eventtypeid,eventtypedesc,statefull) VALUES
	('info','Basic information','n');
INSERT INTO eventtype (eventtypeid,eventtypedesc,statefull) VALUES
    ('deviceOrdered','Tells us that a device has been ordered or that an ordered device has arrived','y');
INSERT INTO eventtype (eventtypeid,eventtypedesc,statefull) VALUES
    ('deviceRegistered','Tells us that a device has been registered with a serial number','n');

DROP TABLE eventq CASCADE;
DROP SEQUENCE eventq_eventqid_seq;
DROP TABLE eventqvar CASCADE;

CREATE TABLE eventq (
  eventqid SERIAL PRIMARY KEY,
  source VARCHAR(32) NOT NULL REFERENCES subsystem (name) ON UPDATE CASCADE ON DELETE CASCADE,
  target VARCHAR(32) NOT NULL REFERENCES subsystem (name) ON UPDATE CASCADE ON DELETE CASCADE,
  deviceid INT4 REFERENCES device ON UPDATE CASCADE ON DELETE CASCADE,
  netboxid INT4 REFERENCES netbox ON UPDATE CASCADE ON DELETE CASCADE,
  subid INT4,
  time TIMESTAMP NOT NULL DEFAULT 'NOW()',
  eventtypeid VARCHAR(32) NOT NULL REFERENCES eventtype ON UPDATE CASCADE ON DELETE CASCADE,
  state CHAR(1) NOT NULL DEFAULT 'x' CHECK (state='x' OR state='s' OR state='e'), -- x = stateless, s = start, e = end
  value INT4 NOT NULL DEFAULT '100',
  severity INT4 NOT NULL DEFAULT '50'
);
CREATE INDEX eventq_target_btree ON eventq USING btree (target);
CREATE TABLE eventqvar (
  eventqid INT4 REFERENCES eventq ON UPDATE CASCADE ON DELETE CASCADE,
  var VARCHAR NOT NULL,
  val TEXT NOT NULL,
	UNIQUE(eventqid, var) -- only one val per var per event
);
CREATE INDEX eventqvar_eventqid_btree ON eventqvar USING btree (eventqid);

-- alert tables
DROP TABLE alertq CASCADE;
DROP SEQUENCE alertq_alertqid_seq;
DROP TABLE alertqvar CASCADE;

CREATE TABLE alertq (
  alertqid SERIAL PRIMARY KEY,
  source VARCHAR(32) NOT NULL REFERENCES subsystem (name) ON UPDATE CASCADE ON DELETE CASCADE,
  deviceid INT4 REFERENCES device ON UPDATE CASCADE ON DELETE CASCADE,
  netboxid INT4 REFERENCES netbox ON UPDATE CASCADE ON DELETE CASCADE,
  subid INT4,
  time TIMESTAMP NOT NULL,
  eventtypeid VARCHAR(32) REFERENCES eventtype ON UPDATE CASCADE ON DELETE CASCADE,
  state CHAR(1) NOT NULL,
  value INT4 NOT NULL,
  severity INT4 NOT NULL
);
CREATE TABLE alertqvar (
  alertqid INT4 REFERENCES alertq ON UPDATE CASCADE ON DELETE CASCADE,
  msgtype VARCHAR NOT NULL,
  language VARCHAR NOT NULL,
  msg TEXT NOT NULL,
  UNIQUE(alertqid, msgtype, language)
);

DROP TABLE alerthist CASCADE;
DROP SEQUENCE alerthist_alerthistid_seq;
DROP TABLE alerthistvar CASCADE;

CREATE TABLE alerthist (
  alerthistid SERIAL PRIMARY KEY,
  source VARCHAR(32) NOT NULL REFERENCES subsystem (name) ON UPDATE CASCADE ON DELETE CASCADE,
  deviceid INT4 REFERENCES device ON UPDATE CASCADE ON DELETE CASCADE,
  netboxid INT4 REFERENCES netbox ON UPDATE CASCADE ON DELETE CASCADE,
  subid INT4,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP DEFAULT 'infinity',
  eventtypeid VARCHAR(32) NOT NULL REFERENCES eventtype ON UPDATE CASCADE ON DELETE CASCADE,
  value INT4 NOT NULL,
  severity INT4 NOT NULL
);
CREATE INDEX alerthist_end_time_btree ON alerthist USING btree (end_time);
CREATE TABLE alerthistvar (
  alerthistid INT4 REFERENCES alerthist ON UPDATE CASCADE ON DELETE CASCADE,
  state CHAR(1) NOT NULL,
  msgtype VARCHAR NOT NULL,
  language VARCHAR NOT NULL,
  msg TEXT NOT NULL,
  UNIQUE(alerthistid, state, msgtype, language)
);

------------------------------------------------------------------------------------------
-- servicemon tables
------------------------------------------------------------------------------------------

DROP TABLE service CASCADE;
DROP TABLE serviceproperty CASCADE;
DROP SEQUENCE service_serviceid_seq;

CREATE TABLE service (
  serviceid SERIAL PRIMARY KEY,
  netboxid INT4 REFERENCES netbox ON UPDATE CASCADE ON DELETE CASCADE,
  active BOOL DEFAULT true,
  handler VARCHAR,
  version VARCHAR,
  up CHAR(1) NOT NULL DEFAULT 'y' CHECK (up='y' OR up='n' OR up='s') -- y=up, n=down, s=shadow
);

CREATE TABLE serviceproperty (
serviceid INT4 NOT NULL REFERENCES service ON UPDATE CASCADE ON DELETE CASCADE,
  property VARCHAR(64) NOT NULL,
  value VARCHAR,
  PRIMARY KEY(serviceid, property)
);

------------------------------------------------------------------------------------------
-- GRANTS AND GRUNTS
------------------------------------------------------------------------------------------

GRANT ALL ON alerthist TO navall;
GRANT ALL ON eventtype TO navall;
GRANT ALL ON service TO navall;
GRANT SELECT ON eventtype TO eventengine;
GRANT SELECT ON subsystem TO eventengine;
GRANT ALL ON eventq TO eventengine;
GRANT ALL ON eventq_eventqid_seq TO eventengine;
GRANT ALL ON eventqvar TO eventengine;
GRANT ALL ON alertq TO eventengine;
GRANT ALL ON alertq_alertqid_seq TO eventengine;
GRANT ALL ON alertqvar TO eventengine;
GRANT ALL ON alerthist TO eventengine;
GRANT ALL ON alerthist_alerthistid_seq TO eventengine;
GRANT ALL ON alerthistvar TO eventengine;
GRANT SELECT ON device TO eventengine;
GRANT SELECT,UPDATE ON netbox TO eventengine;
GRANT SELECT ON cat TO eventengine;
GRANT SELECT ON type TO eventengine;
GRANT SELECT ON room TO eventengine;
GRANT SELECT ON location TO eventengine;
GRANT SELECT,UPDATE ON module TO eventengine;
GRANT SELECT ON swport TO eventengine;
GRANT SELECT ON swportvlan TO eventengine;
GRANT SELECT ON gwport TO eventengine;
GRANT SELECT ON vlan TO eventengine;
GRANT SELECT ON prefix TO eventengine;
GRANT SELECT ON service TO eventengine;
GRANT SELECT ON serviceproperty TO eventengine;

-- adding grant select for NAVprofiles.....
GRANT SELECT ON status, netboxcategory, mem, org,  usage,  vendor,  product,  typegroup,  arp, port2pkt,  pkt2rom,  vp_netbox_grp_info,  vp_netbox_grp,  vp_netbox_xy,  swp_netbox,  swportblocked,  cam,  netboxinfo,  netboxdisk,  netboxinterface,  swportallowedvlan,  eventtype,  eventprocess,  eventq,  eventqvar,  alertq,  alertqvar,  alerthist,  alerthistvar,  netbox,  cat,  type, room,  location,  module,  swport,  swportvlan,  gwport,  prefix,  serviceproperty,  alertengine,  device,  service TO navprofilemanage;
-- skal inneholde alle tabeller i manage til en hver tid.
-- -Andreas-
