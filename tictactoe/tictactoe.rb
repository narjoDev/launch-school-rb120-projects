module Promptable
  def prompt_continue(message = "Press enter to continue.")
    puts message
    gets
  end

  def generic_prompt_number(message, range)
    number = nil

    loop do
      puts message
      puts "Enter a number between #{range.min} and #{range.max}."
      number = gets.chomp.to_i
      return number if range.include?(number)
      puts "Invalid. Number was not in range."
    end
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
      return choice if options.include?(choice)
      puts "Invalid input"
    end
  end

  def generic_prompt_open(message, block: [], max_length: 20)
    entry = nil

    loop do
      puts message
      puts "Reserved: (#{block.join(', ')})" unless block.empty?
      puts "Max characters: #{max_length}"
      entry = gets.strip[...max_length]
      return entry unless entry.empty? || block.include?(entry)
      puts "Input cannot be empty or reserved."
    end
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
  NAMES = ['Lovelace', 'Row-gue AI', 'Beep, Son of Boop']
  PERCENT_MISFIRES = 20

  def move
    choice = win_or_save
    choice = board.open_squares.sample if choice.nil? || misfires?

    board[choice] = self
  end

  def win_or_save
    wins = board.open_wins
    self_wins = wins[self] || []
    others_wins = wins.reject { |player, _| player == self }.values.flatten
    self_wins.sample || others_wins.sample || nil
  end

  def misfires?
    rand(100) < PERCENT_MISFIRES
  end

  def choose_name
    @name = NAMES.sample
  end

  def choose_token
    @token = (TOKENS - board.claimed_tokens).sample
    board.claimed_tokens << token
  end
end

class Board
  attr_reader :squares, :move_log, :claimed_tokens, :size

  SIZE_RANGE = 3..5
  # 5x5 is barely playable without rule changes
  ROW_LETTERS = Array('a'..'i')
  COL_NUMBERS = Array('1'..'9')

  TOKEN_NIL = '.'

  def initialize(size = 3)
    @claimed_tokens = [TOKEN_NIL]
    @size = size
    generate_board_attributes
    reset
  end

  def reset
    @squares = @square_names.to_h { |name| [name, nil] }
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
    @winning_lines.each do |line|
      square_contents = line.map { |name| squares[name] }
      next unless square_contents.all? && square_contents.uniq.size == 1
      player = square_contents.first
      return player
    end
    nil
  end

  # returns hash; keys are players, values are lists of squares
  def open_wins
    return if game_over?
    moves = {}
    @winning_lines.each do |line|
      square_contents = line.map { |name| squares[name] }
      next unless square_contents.one?(nil) && square_contents.uniq.size == 2
      square = line[square_contents.index(nil)]
      player = square_contents.compact.first
      moves[player] = moves.fetch(player, []).append(square)
    end
    moves
  end

  def display
    system 'clear'
    display_last_move
    display_grid
    display_winner if game_over?
  end

  private

  def generate_board_attributes
    generate_names
    generate_lines
  end

  def generate_names
    @rows = ROW_LETTERS[0, size]
    @cols = COL_NUMBERS[0, size]
    @square_names = @rows.product(@cols).map(&:join)
  end

  def generate_lines
    @row_groups = @rows.map { |r| @cols.map { |c| r + c } }
    col_groups = @row_groups.transpose
    diag_groups = [@rows.zip(@cols).map(&:join),
                   @rows.zip(@cols.reverse).map(&:join)]
    @winning_lines = @row_groups + col_groups + diag_groups
  end

  def display_last_move
    return if move_log.empty?
    square, player = move_log.last
    puts "#{player.name} (#{player.token}) played #{square}."
    puts
  end

  def display_grid
    token_rows = @row_groups.map do |group|
      group.map { |name| squares[name] }
           .map { |player| player ? player.token : TOKEN_NIL }
    end

    puts "   #{@cols.join(' ')}"

    size.times do |index|
      puts "#{@rows[index]} |#{token_rows[index].join('|')}|"
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
    populate_board
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
  PLAYER_NUMBER_RANGE = 1..2
  # 3 players would call for a mechanical change to feel playable

  # Why no initialize method?
  # - virtually all the initialization requires prompting the user
  #   for the board size and for player information
  # - we want play to initiate on game.play rather than TTTGame.new
  # - we don't want the user to be prompted upon instantiating a game object

  def populate_board
    board_size = prompt_board_size
    @board = Board.new(board_size)
  end

  def populate_players
    @players = []
    number_players = prompt_number_players
    while players.size < number_players
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

  def prompt_board_size
    message = "What size board would you like to play on? (NxN)"
    generic_prompt_number(message, Board::SIZE_RANGE)
  end

  def prompt_number_players
    message = "How many players would you like there to be? (2 is standard)"
    generic_prompt_number(message, PLAYER_NUMBER_RANGE)
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
