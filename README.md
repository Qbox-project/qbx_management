# qb-management

Business and gang management menu for shared stashes, wardrobes and money

## Dependencies
- [qb-core](https://github.com/qbcore-framework/qb-core)
- [qb-smallresources](https://github.com/qbcore-framework/qb-smallresources) (For the Logs)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [qb-clothing](https://github.com/qbcore-framework/qb-clothing)

## Screenshots
*We need new ones*

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
