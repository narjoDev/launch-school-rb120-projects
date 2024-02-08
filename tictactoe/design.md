# Tic Tac Toe Design

1. Write a description of the problem and extract major nouns and verbs.
1. Make an initial guess at organizing the verbs into nouns and do a spike to explore the problem with temporary code.
1. Optional - when you have a better idea of the problem, model your thoughts into CRC cards.

## Description, Nouns and Verbs

Tic Tac Toe is played on a 3 by 3 board of squares. It is a two player game, with players alternating turns. On a turn, a player fills an empty square with their symbol. One player plays O, the other X. Once a player achieves three in a row--horizontally, vertically, or diagonally--or once all nine squares of the board are full, the game is over. If no player achieved three in a row, the game is a tie.

### Nouns

- Game
- Players
- Board
- Match, continuity across games (optional)

### Verbs

- Move
- Evaluate game state
- Display
- Prompt user (name)

## Organizing Verbs Into Nouns

- Game: Prompt
- Board: Evaluate, Display
- Players: Move

Dilemma: connection between players and board

- Player should have access to the board state
- Board should be able to return which player won (use id tokens placed by players)
- Where do we keep track of the player's designated token? (set when initializing player)
- Where do we manage the turn cycle? (Game)

## Class Responsibility Collaborator (CRC) Cards

### TTTGame

#### Responsibilities

- has a human player
- has a computer player
- has a board
- displays game (?)
- coordinates turns

#### Collaborators

- Human
- Computer
- Board

### Board

#### Responsibilities

- stores game state
- confirm move validity
- evaluates itself for game end
- returns game result
- displays board

#### Collaborators

- Player

### Player (Human, Computer)

#### Responsibilities

- has a unique id
- has a name
- chooses a move

#### Collaborators

- Board (confirm move validity)

## Questions for Code Review

- I am curious when there's much point creating private getters, e.g. for `@rows`, `@winning_lines`, etc? It's worth noting that rubocop counts the getters toward Branches for ABC size, so converting to getters raises more complaints.
