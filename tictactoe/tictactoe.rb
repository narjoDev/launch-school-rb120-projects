class Player
  attr_accessor :board, :score
  attr_reader :id, :name

  def reset
    self.score = 0
  end

  private

  @@instances = 0

  def initialize
    @id = @@instances
    @@instances += 1

    choose_name
    reset
  end
end

class Human < Player
  def move
    choice = nil
    options = board.open_squares
    loop do
      puts "#{name}, choose your next move (#{options.join(', ')})"
      choice = gets.strip.downcase
      break if options.include?(choice)
      puts "Invalid input"
    end
    board.write(choice, id)
  end

  def choose_name
    choice = nil
    loop do
      puts "Enter your name (cannot be blank)"
      choice = gets.strip
      break unless choice.empty?
      puts "Invalid input"
    end
    @name = choice
  end
end

class Computer < Player
  def move
    options = board.open_squares
    choice = options.sample
    puts "#{name} plays #{choice}"
    board.write(choice, id)
  end

  def choose_name
    @name = 'Computer'
  end
end

class Board
  attr_reader :squares, :players

  ROWS = %w(a b c)
  COLS = %w(1 2 3)
  SQUARE_NAMES = ROWS.product(COLS).map(&:join)

  ROW_GROUPS = ROWS.map { |r| COLS.map { |c| r + c } }
  COL_GROUPS = COLS.map { |c| ROWS.map { |r| r + c } }
  DIAG_GROUPS = [(0..2).map { |offset| ROWS[offset] + COLS[offset] },
                 (0..2).map { |offset| ROWS[offset] + COLS[2 - offset] }]
  WINNING_LINES = ROW_GROUPS + COL_GROUPS + DIAG_GROUPS

  PLAYER_TOKENS = %w(X O)
  NIL_TOKEN = '.'

  def initialize(players)
    @players = players
    players.values.each { |player| player.board = self }
    reset
  end

  def reset
    @squares = SQUARE_NAMES.to_h { |name| [name, nil] }
  end

  def open_squares
    squares.keys.select { |name| squares[name].nil? }
  end

  def write(name, contents)
    squares[name] = contents
  end

  def game_over?
    open_squares.empty? || winner
  end

  def winner
    id_lines = WINNING_LINES.map do |group|
      group.map { |name| squares[name] }
    end

    winning_line = id_lines.find do |line|
      line.all? && line.uniq.size == 1
    end

    winning_id = winning_line&.first
    winning_id ? players[winning_id] : nil
  end

  def display_grid
    token_rows = ROW_GROUPS.map do |group|
      group.map { |name| squares[name] }
           .map { |id| id ? PLAYER_TOKENS[id] : NIL_TOKEN }
    end

    puts "   #{COLS.join(' ')}"

    3.times do |index|
      puts "#{ROWS[index]} |#{token_rows[index].join('|')}|"
    end
  end

  def display_winner
    winning_player = winner

    if winning_player
      puts "#{winning_player.name} wins the round."
    else
      puts "Tie round."
    end
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

  GAME_NAME = "Tic Tac Toe"

  def initialize
    system 'clear'

    @player1 = Human.new
    @player2 = Computer.new
    @players = [@player1, @player2].to_h { |player| [player.id, player] }

    @board = Board.new(players)
  end

  def play_round
    board.reset
    players.values.cycle do |player|
      player.move
      board.display_grid
      break if board.game_over?
    end
    board.display_winner
    board.winner&.score += 1
  end

  def prompt_play_again?
    choice = nil
    options = %w(y n)
    loop do
      puts "Would you like to play again?"
      choice = gets.strip.downcase
      break if options.include?(choice)
      puts "Invalid input"
    end
    choice == 'y'
  end

  def display_welcome
    puts "Welcome to #{GAME_NAME}!"
  end

  def display_goodbye
    puts "Thanks for playing #{GAME_NAME}. Goodbye."
  end

  def display_score
    players.values.each do |player|
      plural_suffix = player.score == 1 ? '' : 's'
      puts "#{player.name} has #{player.score} point#{plural_suffix}."
    end
  end
end

TTTGame.new.play
