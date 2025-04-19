require 'json'

class Player
  attr_accessor :id, :name

  def initialize(id, name)
    @id = id
    @name = name
  end

  # JSON Serialisierung für Player
  def to_json(*options)
    { 'id' => @id, 'name' => @name }.to_json(*options)
  end

  # JSON Deserialisierung für Player
  def self.from_json(string)
    data = JSON.parse(string)
    new(data['id'], data['name'])
  end
end

class Tournament
  attr_accessor :id, :matches

  def initialize(id)
    @id = id
    @matches = []
  end

  # JSON Serialisierung für Tournament (alle Matches)
  def to_json(*options)
    { 'id' => @id, 'matches' => @matches.map(&:to_json) }.to_json(*options)
  end

  # JSON Deserialisierung für Tournament
  def self.from_json(string)
    data = JSON.parse(string)
    tournament = new(data['id'])
    tournament.matches = data['matches'].map { |match_json| Match.from_json(match_json) }
    tournament
  end
end

class Match
  attr_accessor :id, :players, :game_scores, :score

  def initialize(id, player1, player2)
    @id = id
    @players = [player1, player2]
    @game_scores = [
      [0, 0],
      [0, 0],
      [0, 0]
    ]
    @score = [0, 0]
  end

  # JSON Serialisierung für Match
  def to_json(*options)
    {
      'id' => @id,  
      'players' => @players.map(&:to_json),
      'game_scores' => @game_scores,
      'score' => @score
    }.to_json(*options)
  end

  # JSON Deserialisierung für Match
  def self.from_json(string)
    data = JSON.parse(string)
    player1 = Player.from_json(data['players'][0])
    player2 = Player.from_json(data['players'][1])
    match = new(data['id'], player1, player2)
    match.game_scores = data['game_scores']
    match.score = data['score']
    match
  end
end

class PlayerStatistic
  attr_accessor :games_played, :games_won, :games_lost

  def initialize(games_played, games_won, games_lost)
    @games_played = games_played
    @games_won = games_won
    @games_lost = games_lost
  end

  # JSON Serialisierung für PlayerStatistic
  def to_json(*options)
    {
      'games_played' => @games_played,
      'games_won' => @games_won,
      'games_lost' => @games_lost
    }.to_json(*options)
  end

  # JSON Deserialisierung für PlayerStatistic
  def self.from_json(string)
    data = JSON.parse(string)
    new(data['games_played'], data['games_won'], data['games_lost'])
  end
end
