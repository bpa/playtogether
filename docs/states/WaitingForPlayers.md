# State WaitingForPlayers

## Data
- available Set of available seats if the game enumerates the player positions
- min int Smallest number of players required to start
- max int number of players needed to automatically start the game
- next str state to change to when ready to start the game

## Game data used
- seats Array of predefined ids for game use *(optional)*
- min_players int value to use for min, defaults to seats or 1
- max_players int value to use for max, defaults to seats or 1000
- ids Hash of client login token to in_game_id
- players Hash of player data
