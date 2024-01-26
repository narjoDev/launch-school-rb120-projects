class Player
  attr_accessor :board, :score
  attr_reader :id, :name

  def move; end

  private

  @@instances = 0

  def initialize
    @id = @@instances
    @@instances += 1

    @name = choose_name
  end

  def choose_name; end
end

class Human < Player
end

class Computer < Player
end

class Board
  ROWS = %w(a b c)
  COLS = %w(1 2 3)
  SQUARE_NAMES = ROWS.product(COLS).map(&:join)

  def open_squares
    squares.keys.select { |name| square_open?(name) }
  end

  def write(name, contents)
    squares[name] = contents
  end

  def game_over?
    squares.values.all? || winner
  end

  def winner; end

  def display_grid; end

  def display_winner; end

  private

  attr_reader :squares, :players

  def initialize(players)
    @players = players
    reset
  end

  def reset
    @squares = SQUARE_NAMES.to_h { |name| [name, nil] }
  end

  def square_open?(name)
    squares[name].nil?
  end
end

class TTTGame
  def play
    display_welcome
    loop do
      play_round
      display_score
      break unless prompt_play_again?
    end
    display_goodbye
  end

  private

  attr_reader :board, :players

  def initialize
    system 'clear'

    @player1 = Human.new
    @player2 = Computer.new
    @players = [@player1, @player2].to_h { |player| [player.id, player] }

    @board = Board.new(players)
  end

  def play_round
    reset
    players.cycle do |player|
      player.move
      board.display_grid
      break if board.game_over?
    end
    board.display_winner
    board.winner&.score += 1
  end
end
