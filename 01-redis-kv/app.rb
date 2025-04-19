=begin
Copyright (c) 2025 Enes Korkmaz, Jascha Sonntag and David Koch

This file is part of tourney-db-variants.

tourney-db-variants is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published
by the Free Software Foundation, either version 3 of the License, or
any later version.

tourney-db-variants is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with tourney-db-variants. If not, see <http://www.gnu.org/licenses/>.
=end

require "redis"
require "./serializable_classes.rb"

class App
  attr_accessor :redis

	def initialize
    @redis = Redis.new(host: "redis", port: 6379)
    begin
      @redis.ping
    rescue => e
      puts "Fehler bei der Verbindung zu Redis: #{e.message}"
    end
  end
	
  # fuer access pattern 1
	def register(tournament_id, player_id)
    #  Überprüfen, ob der Spieler bereits existiert
    if @redis.get("player:#{player_id.to_s}").nil?
      puts "Spieler existiert nicht."
      return
    end

    # Überprüfen, ob das Turnier bereits existiert
    if @redis.get("tournament:#{tournament_id.to_s}").nil?
      puts "Tournament existiert nicht."
      return
    end

    key_tournament_players = "tournament:#{tournament_id.to_s}:players"
    @redis.rpush(key_tournament_players, player_id.to_s)
  end

  # fuer access pattern 2
  def enter_result(match_id, score)
    key = "match:#{match_id.to_s}"
    match_json = @redis.get(key)
    if match_json.nil?
      puts "Match with ID #{match_id} not found."
      return
    end
    match = Match.from_json(match_json)
    games_played = match.score[0] + match.score[1]
    if match.score[0] == 2 or match.score[1] == 2
      puts "Match with ID #{match.id} already finished after #{games_played} games."
      return 
    end
    match.game_scores[games_played] = score
    if score[0] > score[1]
      match.score[0] += 1
    elsif score[0] < score[1]
      match.score[1] += 1
    end
    @redis.set(key, match.to_json)
    if match.score[0] >= 2
      winner_id = match.players[0].id
      loser_id = match.players[1].id
    elsif match.score[1] >= 2
      winner_id = match.players[1].id
      loser_id = match.players[0].id
    else
      return
    end
    winner_statistic_key = "player:#{winner_id}:statistic"
    loser_statistic_key = "player:#{loser_id}:statistic"
    if @redis.get(winner_statistic_key).nil?
      @redis.set(winner_statistic_key, PlayerStatistic.new(0, 0, 0).to_json)
    end
    if @redis.get(loser_statistic_key).nil?
      @redis.set(loser_statistic_key, PlayerStatistic.new(0, 0, 0).to_json)
    end
    winner_statistic = PlayerStatistic.from_json(@redis.get(winner_statistic_key))
    loser_statistic = PlayerStatistic.from_json(@redis.get(loser_statistic_key))
    winner_statistic.games_played += 1
    winner_statistic.games_won += 1
    loser_statistic.games_played += 1
    loser_statistic.games_lost += 1
    @redis.set(winner_statistic_key, winner_statistic.to_json)
    @redis.set(loser_statistic_key, loser_statistic.to_json)
  end

  # fuer access pattern 3
  def create_tournament(tournament)
    @redis.set("tournament:#{tournament.id}", tournament.to_json)
  end

  # fuer access pattern 4
  def create_match(match)
    @redis.set("match:#{match.id}", match.to_json)
  end

  # fuer access pattern 5
  def view_player_statistic(player_id)
    stats_key = "player:#{player_id}:statistic"
  
    # Check if player statistics exist
    if @redis.exists(stats_key)
      PlayerStatistic.from_json(@redis.get(stats_key))
    else
      nil
    end
  end    
end