# Loaf - Keysystem
Version 2. Works with ESX & QBCore. 
If you find any issues, please report them to me on discord @Loaf Scripts#7785, or open an issue here.

## Requirements
* [loaf_lib](https://github.com/loaf-scripts/loaf_lib)
* [mysql-async](https://github.com/brouznouf/fivem-mysql-async) or [oxmysql](https://github.com/overextended/oxmysql/releases/tag/v1.9.3), one of these should already be on your server.

## Installation
1. Install all the requirements
2. Clone the repository
3. Extract the zip in your resources folder
4. Rename from loaf_keysystem-master to loaf_keysystem
5. Set `Config.Framework` to "esx" if you use ESX or "qb" if you use QBCore
6. Run `keysystem.sql`
7. Modify the config to your liking
8. Done!

## Usage for resource developers
### Server exports
Export        | Parameters                            | Returns
---           | ---                                   | ---
GetKeys       | source (number)                       | the user's keys (table)
GetKey        | unique key id (string)                | the key (table)
HasKey        | source (number), key id (string)      | if the user has the specified key (boolean)
RemoveKey     | unique key id (string)                | if the key was removed (boolean)
RemoveAllKeys | key id (string)                       | nothing
TransferKey   | unique key id, player to transfer to  | if the key was transferred (boolean)
GenerateKey   | source (number), key id (string), key label (string), eventtype (optional, string server or client), eventname (optional, string the name of the event) | nothing

### Client exports
Export        | Parameters                            | Returns
---           | ---                                   | ---
SetKeyUsage   | key id (string), on usage (function)  | nothing
HasKey        | key id (string)                       | if the player has the specified key (boolean)
GetKeys       | none                                  | all keys the player has (table)
GetKey        | unique key id (string)                | the key (table)