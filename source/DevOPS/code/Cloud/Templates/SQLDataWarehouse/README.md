## Purpose

Before you can deploy an Azure SQL Data Warehouse you must first create a logical SQL Server, or have one already created.  

## SQLServer.json

`SQLServer.json` creates just the logical SQL Server. 

### Assumptions

* the server will always allow Azure services to connect without firewall changes
* there are no failover groups
* no databases (or data warehouses) are created
* all settings are at their defaults
* VNets are applied to the logical SQL Server.  All dbs under that logical server inherit those VNet settings.  

## ASQLDW.json

`ASQLDW.json` creates the actual warehouse database

### Assumptions

* logical SQL Server must exist
* keys are service-managed
* VNet settings are inherited from the logical SQL Server

