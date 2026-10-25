# SQL files

Pure Inventory creates its tables **by itself** at the first start. These files are here if you prefer to create them
yourself (HeidiSQL, phpMyAdmin...), or if your database user cannot create tables.

| File | When |
| --- | --- |
| `1_all_frameworks.sql` | always |
| `2_standalone.sql` | only without framework (`Config.Framework = 'standalone'`) |
| `3_qbcore.sql` | only with QBCore / Qbox, if the columns are missing |

Coming from **ox_inventory**: keep your `ox_inventory` table, nothing to convert.
