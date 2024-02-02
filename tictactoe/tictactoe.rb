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
    choice = generic_prompt_select(options, "#{name}, choose your next move:")
    board[choice] = self
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

  def []=(name, contents)
    move_log << [name, contents]
    squares[name] = contents
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

  def display_last_move
    return if move_log.empty?
    square, player = move_log.last
    puts "#{player.name} played #{square}."
  end

  def display_grid
    display_last_move

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

    @players = [Human.new(board), Computer.new(board)]
  end

  def play_round
    board.reset
    players.cycle do |player|
      system 'clear'
      board.display_grid
      break if board.game_over?
      player.move
    end
    board.display_winner
    board.winner&.score += 1
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
