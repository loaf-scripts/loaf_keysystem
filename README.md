# Loaf - Keysystem

Version 3. Works with ESX, QBCore, and Standalone.
If you encounter any issues, create a [bug report](https://discord.com/channels/668570162609520653/1164708334931296276/threads/1164711664885710998) in my [discord](https://discord.com/invite/4dUvf34) or open an [issue](https://github.com/loaf-scripts/loaf_keysystem/issues).

## Requirements

-   [loaf_lib](https://github.com/loaf-scripts/loaf_lib)
-   [mysql-async](https://github.com/brouznouf/fivem-mysql-async) or [oxmysql](https://github.com/overextended/oxmysql/releases/tag/v1.9.3), one of these should already be on your server.

## Installation

1. Install all the [requirements](#requirements)
2. Download the latest [release](https://github.com/loaf-scripts/loaf_keysystem/releases/latest)
3. Extract the zip file into your resources folder
4. Run `keysystem.sql`
5. Modify the config/config.lua to your liking
6. Add `start loaf_keysystem` to your server.cfg
7. Done!

## Usage for resource developers

### Server exports

| Export        | Parameters                                                                                                     | Returns                                     |
| ------------- | -------------------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| GetKeys       | source: number                                                                                                 | the user's keys (table)                     |
| GetKey        | uniqueId: string                                                                                               | the key (table)                             |
| HasKey        | source: number, keyId: string                                                                                  | if the user has the specified key (boolean) |
| RemoveKey     | uniqueId: string                                                                                               | if the key was removed (boolean)            |
| RemoveAllKeys | keyId: string                                                                                                  | void                                        |
| TransferKey   | uniqueId, player to transfer to                                                                                | if the key was transferred (boolean)        |
| GenerateKey   | source: number, keyId: string, keyLabel: string, eventtype?: string ("server" or "client"), eventname?: string | the generated key's unique id (string)      |

### Client exports

| Export      | Parameters                  | Returns                                       |
| ----------- | --------------------------- | --------------------------------------------- |
| SetKeyUsage | keyId: string, cb: function | void                                          |
| HasKey      | keyId: string               | if the player has the specified key (boolean) |
| GetKeys     |                             | all keys the player has (table)               |
| GetKey      | uniqueId: string            | the key (table)                               |
| UseKey      | uniqueId: string            | void                                          |
