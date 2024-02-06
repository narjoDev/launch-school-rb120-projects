module Promptable
  def prompt_continue(message = "Press enter to continue.")
    puts message
    gets
  end

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

  def generic_prompt_open(message, block: [], max_length: 20)
    choice = nil

    loop do
      puts message
      puts "Reserved: (#{block.join(', ')})" unless block.empty?
      puts "Max characters: #{max_length}"
      choice = gets.strip[...max_length]
      break unless choice.empty? || block.include?(choice)
      puts "Input cannot be empty or reserved."
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

  attr_accessor :score
  attr_reader :name, :token, :board

  def reset
    self.score = 0
  end

  private

  def initialize(board)
    @board = board

    choose_name
    choose_token
    reset
  end
end

class Human < Player
  def move
    choice = generic_prompt_select(
      board.open_squares,
      "#{name} (#{token}), choose your next move:"
    )
    board[choice] = self
  end

  def choose_name
    @name = generic_prompt_open('Enter your name:')
  end

  def choose_token
    @token = generic_prompt_open(
      "Enter a character token",
      block: board.claimed_tokens,
      max_length: 1
    )
    board.claimed_tokens << token
  end
end

class Computer < Player
  TOKENS = %w(X O $ % *)

  def move
    choice = board.open_squares.sample
    board[choice] = self
  end

  def choose_name
    @name = 'Computer'
  end

  def choose_token
    @token = (TOKENS - board.claimed_tokens).sample
    board.claimed_tokens << token
  end
end

class Board
  attr_reader :squares, :move_log, :claimed_tokens

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

  TOKEN_NIL = '.'

  def initialize
    @claimed_tokens = [TOKEN_NIL]
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
    open_squares.empty? || winning_player
  end

  def winning_player
    WINNING_LINES.each do |line|
      square_contents = line.map { |name| squares[name] }
      next unless square_contents.all? && square_contents.uniq.size == 1
      player = square_contents[0]
      return player
    end
    nil
  end

  def display
    system 'clear'
    display_last_move
    display_grid
    display_winner if game_over?
  end

  private

  def display_last_move
    return if move_log.empty?
    square, player = move_log.last
    puts "#{player.name} (#{player.token}) played #{square}."
    puts
  end

  def display_grid
    token_rows = ROW_GROUPS.map do |group|
      group.map { |name| squares[name] }
           .map { |player| player ? player.token : TOKEN_NIL }
    end

    puts "   #{COLS.join(' ')}"

    3.times do |index|
      puts "#{ROWS[index]} |#{token_rows[index].join('|')}|"
    end
    puts
  end

  def display_winner
    puts (winning_player&.name&.+ " wins the round.") || "Tie round."
    puts
  end
end

class TTTGame
  include Promptable

  def play
    display_welcome
    populate_players
    loop do
      play_match
      break unless prompt_play_again?
    end
    display_goodbye
  end

  private

  attr_reader :board, :players

  GAME_NAME = "Tic Tac Toe"
  SCORE_TO_WIN = 3

  def initialize
    @board = Board.new
    @players = []
  end

  def populate_players(num_players = 2)
    while players.size < num_players
      players << (prompt_human? ? Human.new(board) : Computer.new(board))
    end
  end

  def play_match
    reset_match
    until match_over?
      play_round
      display_score
      prompt_continue unless match_over?
    end
  end

  def play_round
    board.reset
    players.cycle do |player|
      board.display
      break if board.game_over?
      player.move
    end
    board.winning_player&.score += 1
  end

  def reset_match
    players.each { |player| player.score = 0 }
  end

  def match_over?
    players.map(&:score).max >= SCORE_TO_WIN
  end

  def match_winner
    players.max_by(&:score)
  end

  def prompt_human?
    puts "Players: #{players.map(&:name).join(', ')}" unless players.empty?
    generic_prompt_binary?('human', 'computer',
                           'Fill next player slot with human or computer?')
  end

  def prompt_play_again?
    generic_prompt_binary?('y', 'n', 'Would you like to play again?')
  end

  def display_welcome
    system 'clear'
    puts "Welcome to #{GAME_NAME}!"
    puts
  end

  def display_goodbye
    puts "Thanks for playing #{GAME_NAME}. Goodbye."
  end

  def display_points
    players.each do |player|
      plural_suffix = player.score == 1 ? '' : 's'
      puts "#{player.name} has #{player.score} point#{plural_suffix}."
    end
  end

  def display_score
    display_points

    puts(if match_over?
           "#{match_winner.name} wins the match!"
         else
           "Playing to #{SCORE_TO_WIN} points."
         end)
    puts
  end
end

TTTGame.new.play
