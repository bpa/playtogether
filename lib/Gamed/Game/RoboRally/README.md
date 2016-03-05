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
* pieces: Bot (see below)
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
* register: Array
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
    + registers: Array
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
