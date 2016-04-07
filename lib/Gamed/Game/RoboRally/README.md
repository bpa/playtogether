Communication
=============

|Phase|Client/Server|Command|Content|Notes|
|-----|-------------|-------|-------|-----|
|Joining|client|bot|string(name of available bot)|Subject to review, list of available bots in [bots](../../public/g/RoboRally/bots).|
|Joining|server|bot|bot:`str`, player:`str`|Broadcast bot selection|
|Joining|client|ready||Signals ready to play (not waiting on players to join)|
|Joining|server|ready|player:`str`|Broadcast ready state|
|Joining|server|pieces|pieces:Array[Piece]|Gives starting locations for everyone, etc.  Signals end of joining, start of programming phase|
|Programming|server|programming|cards:Array[`str`]|Cards available for programming|
|Programming|client|program|registers:Array[up to 5 Array[`str`]]|Program registers|
|Programming|server|program|registers:Array[Array[]]|Repeat to client as ack|
|Programming|client|ready|-|Signal program is complete.  No more modifications are allowed|
|Programming|server|ready|player:`str`|Broadcast when player is ready|
|Programming|client|shutdown|activate:`bool`|Tell the server whether or not to trigger shutdown after the round|
|Executing|server|execute|phase:`str`,actions:Array[Movement]|See Movement and Phase tables below|
|Executing|server|repairs|repair:Hash{bot:`str`=>`int`(damage repaired)}, options:Hash{bot:`str`=>`str`(new option card), pieces=>Array[Piece]|Automatic cleanup items|
|Executing|server|damage|damage:`int`|Player is taking damage and can optionally dispose of one or more option cards|
|Executing|client|damage|registers:`int`, options:Array[`str`(option card ids)]|Specify how to allocate damage.|
|Executing|server|option|bot:`int`, option:`str`|Signifies a player must choose whether or not to excersize an option|
|Executing|client|option|option:`str`,activate:`bool`|Tell the server|
|Executing|server|placing|bot:`str`|Signifies a bot is ready to be placed back on the board|
|Executing|client|place|x:`int`,y:`int`,o:`int`|Player specifies where (x,y) and which direction(o, NESW => 0123) to place the bot back on the board|
|Executing|server|place|bot:`str`,x:`int`,y:`int`,o:`int`|Broadcast placement|

Phases
------
|Phase|Comment|
|-----|-------|
|movement|Bots move|
|express_conveyors|Express only|
|conveyors|Express and normal conveyors|
|gears|Gears rotate|
|lasers|Lasers fire|

Movement
--------
*Not all elements will appear*

|Element|Type|Comment|
|-------|----|-------|
|piece|`str`|Name(id) of Bot/Flag/etc|
|move|`int`|Tiles to move|
|dir|`int`|Which way to move NESW => 0123|
|rotate|`str`|r => right, l => left, u => u-turn|
|die|`str`|fall => in pit or off board, damage => ran out of registers|
|damage|`int`|x number of registers got damaged|
|lost|Array[`str`]|Options lost to damage|
|effect|Array[`str`]|Status effects (radio controlled, push, etc.)|

Data
====

Game
----
* public
    + course: RoboRally::Course
    + bots: Hash with filename as key, used to create pieces
        - name: bot's name
        - image: href of image to display
* movement_cards: Gamed::Object::Deck
* option_cards: Gamed::Object::Deck

RoboRally::Course
-----------------
* pieces: Array of Piece
* course: raw course data
* tiles: Array[y][x] of tile data
    + pieces: Array of Piece found on the tile
    + w: bitset of walls NESW => 1248
    + o: orientation NESW => 0123
    + t: tile type name (floor, conveyor, gear, 1, 2, 3, etc)
* start: hash with key start position (int)
    + [ x, y ]
* w: int, width
* h: int, height

Pieces
------

#### Piece (base)
* id: string
* type: string (bot, flag, archive, etc.)
* x: int
* y: int
* o: int, orientation NESW => 0123
* solid: bool, can push or be pushed
* active: bool, is piece on the board

#### Bot
Piece adding the following fields
* player: id of player controlling bot
* number: starting position
* flag: int, last flag captured (0 for none)
* lives: int
* damage: int
* options: Array of option names active on bot
* registers: Array
    + damaged: bool
    + program: Array of cards
    
#### Flag
Piece adding:
* flag: the id of this flag

Player Data
-----------
* public
    + bot: hashref of game.public.course.pieces Bot instance
        - number: starting position
    + ready: bool
* private
    + cards: Bag of cards
    + registers: Array
    
Joining
-------
* min: int, number of players required to start
* max: int, number of bots supported by course

Executing
---------
* register: int, 0-4
* phase: int, index of current phase (references internal [ &code, ... args ] )
