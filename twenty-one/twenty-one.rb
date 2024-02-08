class Participant
  attr_reader :cards

  def initialize
    @cards = []
  end

  # what goes in here? all the redundant behaviors from Player and Dealer?
  def hit; end

  def stay; end

  def busted?; end

  def total
    # definitely looks like we need to know about "cards" to produce some total
  end
end

class Player < Participant
  def initialize
    # what would the "data" or "states" of a Player object entail?
    # maybe cards? a name?
  end
end

class Dealer < Participant
  def initialize
    # seems like very similar to Player... do we even need this?
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
    number_cards.times { participant.cards << @deck.pop }
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
    deal_cards
    display_cards
    player_turn
    dealer_turn
    show_result
  end

  private

  attr_reader :deck, :player, :dealer

  def initialize
    @deck = Deck.new
    @player = Player.new
    @dealer = Dealer.new
  end

  def deal_cards
    [player, dealer].each { |participant| deck.deal(participant, 2) }
  end

  def display_cards(reveal_dealer: false); end
end

# Game.new.start
# puts Card.full_deck.map(&:to_s)
