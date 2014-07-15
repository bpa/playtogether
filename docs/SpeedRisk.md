# SpeedRisk

## States
- [WaitingForPlayers](states/WaitingForPlayers.md)
- Placing
- Playing
- [GameOver](states/GameOver.md)

## Game data
- players Hash { player_id => data }
  - public Hash
    - theme str Player's chosen color/pattern
    - ready int representing whether or not the player is ready to play
  - id str same as in_game_id of connection
- countries Array[{armies=>int, owner=>str}]

##Commands

Command   |State(s)                 |Sender|Arguments   |Notes
----------|-------------------------|------|------------|-----
ready     |WaitingForPlayers,Placing|Both  |None        |     
not ready |WaitingForPlayers,Placing|Both  |None        |     
armies    |Placing,Playing          |Server|armies(int) |Number of armies currently held
place     |Placing,Playing          |Client|country(int),armies(int)|
country   |Placing,Playing          |Server|country(int),armies(int),owner|Update country data
move      |Playing                  |Client|from(int),to(int),armies(int)|Attack if to not owned
move      |Playing                  |Server|result(array(from,to) of {owner=>int,country=>int,armies=>int}|
attack    |Playing                  |Server|result(array(from,to) of {owner=>int,country=>int,armies=>int}|Same as move, but indicates a battle occurred
army timer|Playing                  |Server|seconds(int)|Seconds until armies are generated again
defeated  |Playing                  |Server|player      |A player has lost
victory   |Placing,Playing          |Server|player      |A player has conquered the world
theme     |*All*                    |Client|theme(str)  |Request a color/theme as identity
theme     |*All*                    |Server|theme(str),player,available(arr[str])|Notify all players of a registered color/theme
