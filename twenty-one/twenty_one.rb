class Participant
  attr_reader :hand

  def initialize
    reset
  end

  def reset
    @hand = Hand.new
  end

  def busts?
    hand.busts?
  end

  def display(obscure: false)
    puts "#{self.class} hand:"
    hand.display(obscure: obscure)
    puts
  end

  def <=>(other)
    hand <=> other.hand
  end

  def total
    hand.value
  end

  def receive(card)
    hand << card
  end
end

class Player < Participant
  def hit?
    choice = nil

    loop do
      puts 'hit or stay? (h/s)'
      choice = gets.strip.downcase[0]
      break if %w(h s).include?(choice)
      puts 'invalid input'
    end
    choice == 'h'
  end
end

class Dealer < Participant
  STAY_THRESHOLD = 17

  def hit?
    total < STAY_THRESHOLD
  end
end

class Deck
  def initialize
    reset
  end

  def reset
    @deck = Card.full_deck.shuffle
  end

  def deal(participant, number_cards = 1)
    number_cards.times { participant.receive(@deck.pop) }
  end
end

class Hand
  attr_reader :cards

  MAX_VALUE = 21
  ACE_CONTINGENT_VALUE = 10

  def initialize
    @cards = []
  end

  def value
    number_aces = cards.count(&:ace?)
    total = cards.sum(&:value)
    while number_aces > 0 && (total + ACE_CONTINGENT_VALUE) <= MAX_VALUE
      total += ACE_CONTINGENT_VALUE
      number_aces -= 1
    end
    total
  end

  def busts?
    value > MAX_VALUE
  end

  def <<(card)
    cards << card
    refresh_value
  end

  def <=>(other)
    value <=> other.value # does not take into account busts
  end

  def display(obscure: false)
    if obscure
      puts cards.first
      puts(cards[1..-1].map { "???" })
    else
      puts cards
      puts "=>#{value}" + (busts? ? " (BUSTED!)" : '')
    end
  end
end

class Card
  NUMBERS = (2..10).map(&:to_s)
  ROYALS = ['jack', 'queen', 'king']
  ACE = 'ace'
  FACES = NUMBERS + ROYALS + [ACE]

  SUITS = ['hearts', 'diamonds', 'clubs', 'spades']

  def self.full_deck
    FACES.product(SUITS).map { |face, suit| Card.new(face, suit) }
  end

  attr_reader :face, :suit

  def initialize(face, suit)
    @face = face
    @suit = suit
  end

  def number?
    NUMBERS.include?(face)
  end

  def royal?
    ROYALS.include?(face)
  end

  def ace?
    face == ACE
  end

  def value
    if number?
      face.to_i
    elsif royal?
      10
    elsif ace?
      1 # possible value of 11 handled when totaling hand
    end
  end

  def to_s
    "#{face} of #{suit}"
  end
end

class Game
  def start
    loop do
      deal_cards
      display_cards
      player_turn
      dealer_turn
      show_result
      break unless prompt_play_again?
      reset
    end
  end

  private

  attr_reader :deck, :player, :dealer

  def initialize
    @deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
  end

  def reset
    deck.reset
    player.reset
    dealer.reset
  end

  def deal_cards
    [player, dealer].each { |participant| deck.deal(participant, 2) }
  end

  def prompt_play_again?
    choice = nil

    loop do
      puts "Would you like to play again? (y/n)"
      choice = gets.strip.downcase[0]
      break if %w(y n).include?(choice)
      puts "Invalid input"
    end
    choice == 'y'
  end

  def display_cards(obscure_dealer: true)
    system 'clear'
    dealer.display(obscure: obscure_dealer)
    player.display
  end

  def player_turn
    loop do
      break if player.busts? || !player.hit?
      deck.deal(player)
      display_cards
    end
  end

  def dealer_turn
    return if player.busts?
    deck.deal(dealer) while dealer.hit?
  end

  def show_result
    display_cards(obscure_dealer: false)
    if player.busts?
      puts "Player busted, Dealer wins!"
    elsif dealer.busts?
      puts "Dealer busted, Player wins!"
    else
      puts winner_by_score
    end
  end

  def winner_by_score
    case player <=> dealer
    when  1 then "Player wins with a total of #{player.total}"
    when  -1 then "Dealer wins with a total of #{dealer.total}"
    when 0 then "Player and dealer tie with a total of #{player.total}"
    end
  end
end

Game.new.start
