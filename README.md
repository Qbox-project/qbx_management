# qb-management

New qb-bossmenu / qb-gangmenu converted into one resource using qb-menu and qb-input, with SQL support for society funds!

## Dependencies
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [qb-smallresources](https://github.com/qbcore-framework/qb-smallresources) (For the Logs)
- [qb-input](https://github.com/qbcore-framework/qb-input)
- [qb-menu](https://github.com/qbcore-framework/qb-menu)
- [qb-inventory](https://github.com/qbcore-framework/qb-inventory)
- [qb-clothing](https://github.com/qbcore-framework/qb-clothing)

## Screenshots
![image](https://i.imgur.com/9yiQZDX.png)
![image](https://i.imgur.com/MRMWeqX.png)

## Installation
### Manual
- Download the script and put it in the `[qb]` directory.
- IF NEW SERVER: Import `qb-management.sql` in your database
- IF EXISTING SERVER: Import `qb-management_upgrade.sql` in your database
- Edit config.lua with coords
- Restart Script / Server

## ATTENTION
### YOU NEED TO CREATE A ROW IN DATABASE WITH NAME OF SOCIETY IN MANAGEMENT_FUNDS TABLE IF YOU HAVE CUSTOM JOBS / GANGS
![database](https://i.imgur.com/6cd3NLU.png)
