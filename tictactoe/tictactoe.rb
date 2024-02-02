module Promptable
  def generic_prompt_binary?(true_answer, false_answer, message)
    options = [true_answer, false_answer]
    generic_prompt_select(options, message, '/') == true_answer
  end

  def generic_prompt_select(options, message, separator = ', ')
    choice = nil

    loop do
      puts "#{message} (#{options.join(separator)})"
      choice = gets.chomp
      autocomplete!(choice, options)
      break if options.include?(choice)
      puts "Invalid input"
    end

    choice
  end

  def generic_prompt_open(message, block = [])
    choice = nil

    loop do
      puts message
      choice = gets.strip
      break unless choice.empty? || block.include?(choice)
      error = choice.empty? ? "empty." : "in blocklist (#{block.join(', ')})"
      puts "Input cannot be #{error}"
    end

    choice
  end

  def autocomplete!(partial, full_strings)
    matches = full_strings.select do |str|
      str.strip.downcase.start_with?(partial.strip.downcase)
    end

    partial.replace(matches.first.clone) if matches.size == 1
  end
end

class Player
  include Promptable

  attr_accessor :board, :score
  attr_reader :id, :name, :token

  def reset
    self.score = 0
  end

  private

  @@instances = 0

  def initialize(board)
    @id = @@instances
    @@instances += 1

    self.board = board
    @token = Board::PLAYER_TOKENS[id]

    choose_name
    reset
  end
end

class Human < Player
  def move
    options = board.open_squares
    message = "#{name} (#{token}), choose your next move:"
    choice = generic_prompt_select(options, message)
    board[choice] = self
  end

  def choose_name
    @name = generic_prompt_open('Enter your name:')
  end
end

class Computer < Player
  def move
    choice = board.open_squares.sample
    board[choice] = self
  end

  def choose_name
    @name = 'Computer'
  end
end

class Board
  attr_reader :squares, :move_log

  ROWS = %w(a b c)
  COLS = %w(1 2 3)
  SQUARE_NAMES = %w(a1 a2 a3 b1 b2 b3 c1 c2 c3)

  ROW_GROUPS = [["a1", "a2", "a3"], ["b1", "b2", "b3"], ["c1", "c2", "c3"]]

  WINNING_LINES = [["a1", "a2", "a3"],
                   ["b1", "b2", "b3"],
                   ["c1", "c2", "c3"],
                   ["a1", "b1", "c1"],
                   ["a2", "b2", "c2"],
                   ["a3", "b3", "c3"],
                   ["a1", "b2", "c3"],
                   ["a3", "b2", "c1"]]

  PLAYER_TOKENS = %w(X O)
  NIL_TOKEN = '.'

  def initialize
    reset
  end

  def reset
    @squares = SQUARE_NAMES.to_h { |name| [name, nil] }
    @move_log = []
  end

  def open_squares
    squares.keys.select { |name| squares[name].nil? }
  end

  def []=(square_name, player)
    move_log << [square_name, player]
    squares[square_name] = player
  end

  def game_over?
    open_squares.empty? || winner
  end

  # returns a Player object, or nil if no winner
  def winner
    WINNING_LINES.each do |line|
      values = line.map { |name| squares[name] }
      next unless values.all? && values.uniq.size == 1
      winning_player = values[0]
      return winning_player
    end
    nil
  end

  def display
    system 'clear'
    display_last_move
    display_grid
    display_winner if game_over?
  end

  def display_last_move
    return if move_log.empty?
    square, player = move_log.last
    puts "#{player.name} (#{player.token}) played #{square}."
  end

  def display_grid
    token_rows = ROW_GROUPS.map do |group|
      group.map { |name| squares[name] }
           .map { |player| player ? player.token : NIL_TOKEN }
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
  include Promptable

  def play
    display_welcome
    populate_players
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
    @board = Board.new

    @players = []
  end

  def play_round
    board.reset
    board.display
    players.cycle do |player|
      player.move
      board.display
      break if board.game_over?
    end
    board.winner&.score += 1
  end

  def populate_players(num_players = 2)
    while players.size < num_players
      players << (prompt_human? ? Human.new(board) : Computer.new(board))
    end
  end

  def prompt_human?
    puts "Players: #{players.map(&:name).join(', ')}"
    generic_prompt_binary?('human', 'computer',
                           'Fill next player slot with human or computer?')
  end

  def prompt_play_again?
    generic_prompt_binary?('y', 'n', 'Would you like to play again?')
  end

  def display_welcome
    system 'clear'
    puts "Welcome to #{GAME_NAME}!"
  end

  def display_goodbye
    puts "Thanks for playing #{GAME_NAME}. Goodbye."
  end

  def display_score
    players.each do |player|
      plural_suffix = player.score == 1 ? '' : 's'
      puts "#{player.name} has #{player.score} point#{plural_suffix}."
    end
  end
end

TTTGame.new.play
