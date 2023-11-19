# Area6510

### RL-INIT
RL-INIT includes some small tools to easily setup your ramlink with a defined partition list without adding all partitions manually.

#### rl-edit
Use this program to create a 'rl.ini' configuration file which includes a list of partitions that should automatically created and formatted using 'rl.init'.
This program will not modify any data on your ramlink.

#### rl-init
Use this program to automatically setup your ramlink with the partition list from the 'rl.ini' configuration file. Note that this will erease all data and all partitions from your ramlink!
This program ise useful if you have many different partitions on your ramlink and don't want to setup your ramlink after a crash of power-loss manually.

#### rl-sortview
This program will just print a list of all partitions on your ramlink with information about size and partition type.

#### rl-partview
This program will print a list of all partitions on your ramlink with additional info of the start adress of the partition in the memory map of your ramlink.
