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

require 'mongo'

class App
  attr_accessor :tournament_db

  def initialize
    mongo_client = Mongo::Client.new(['mongo:27017'], 
    database: 'tournament_db', 
    user: 'root', 
    password: 'hhn', 
    auth_source: 'admin')

    begin
      mongo_client.database.collections
      puts "\nSuccessfully connected to MongoDB."
      @tournament_db = mongo_client[:tournaments]
    rescue => e
      puts "Error connecting to MongoDB: #{e.message}"
    end
  end 

  def register(tournament_id, player_id, player_name)
    tournament = @tournament_db.find( { "_id": tournament_id } ).first
    
    if tournament.nil?
      puts "Tournament not found."
      return
    end  
    
    if tournament["players"].any? { |player| player["_id"] == player_id }
      puts "Player is already registered."
      return
    end
    
    new_player = {
      "_id": player_id,
      "name": player_name,
      "statistic": [0, 0, 0]
    }

    @tournament_db.update_one(
      { "_id" => tournament_id },
      { "$push" => { "players" => new_player } }
    )

    puts "Player registered successfully."
  end

  def enter_result(tournament_id, match_id, score)
    # Find the tournament and ensure it exists
    tournament = @tournament_db.find( { "_id": tournament_id } ).first
    
    if tournament.nil?
      puts "Tournament not found."
      return
    end
  
    # Find the match in the tournament
    match = tournament["matches"].find { |match| match["_id"] == match_id }
  
    if match.nil?
      puts "Match not found."
      return
    end
  
    # Ensure that the match is not finished
    if match["score"].any? { |score| score >= 2 }
      puts "Match is already finished."
      return
    end

    # Add the new game score to the match
    match["game_scores"] ||= [] # if nil or false assign this
    match["game_scores"] << score # adds the new score to the array

    # Update the score based on the game result
    if score[0] > score[1]
      match["score"][0] += 1
    elsif score[0] < score[1]
      match["score"][1] += 1
    end

    # Check if the match is finished
    if match["score"][0] >= 2 || match["score"][1] >= 2
      winner_position = match["score"][0] == 2 ? 0 : 1
      loser_position = winner_position == 0 ? 1 : 0

      # Get the winning and losing players
      winner = match["players"][winner_position]
      loser = match["players"][loser_position]

      # Update player statistics for the winner and loser
      winner_statistic = winner["statistic"]
      loser_statistic = loser["statistic"]

      # Update statistics: games played, games won/lost
      winner_statistic[0] += 1  # Games played
      winner_statistic[1] += 1  # Games won
      loser_statistic[0] += 1   # Games played
      loser_statistic[2] += 1   # Games lost

      # Update player statistics in the database
      @tournament_db.update_one(
        { "_id": tournament_id, "players._id": winner["_id"] },
        { "$set" => { "players.$.statistic" => winner_statistic } }
      )

      @tournament_db.update_one(
        { "_id": tournament_id, "players._id": loser["_id"] },
        { "$set" => { "players.$.statistic" => loser_statistic } }
      )

      # Update player statistics in each match's players array
      @tournament_db.update_many(
        { "_id": tournament_id, "matches.players._id" => winner["_id"] },
        { "$set" => { "matches.$[match].players.$[player].statistic" => winner_statistic } },
        array_filters: [
          { "match._id" => { "$exists" => true } },
          { "player._id" => winner["_id"] }
        ]
      )

      @tournament_db.update_many(
        { "_id": tournament_id, "matches.players._id" => loser["_id"] },
        { "$set" => { "matches.$[match].players.$[player].statistic" => loser_statistic } },
        array_filters: [
          { "match._id" => { "$exists" => true } },
          { "player._id" => loser["_id"] }
        ]
      )
    end

    # Update the match back in the database if not finished
    @tournament_db.update_one(
      { "_id": tournament_id, "matches._id": match_id },
      { "$set" => { "matches.$.score" => match["score"], "matches.$.game_scores" => match["game_scores"] } }
    )

    puts "Match result entered successfully."
  end

  def create_tournament(tournament_id)
    # Search the tournament and ensure it does not exists
    tournament = @tournament_db.find( { "_id": tournament_id } ).first
    
    if not tournament.nil?
      puts "Tournament already exist."
      return
    end
    
    # Configuring new tournemnet to be added to db
    new_tournamnet = {
      "_id": tournament_id,
      "players": [],
      "matches": []
    }

    # Insert the new tournament into the database
    @tournament_db.insert_one(new_tournamnet)
    puts "Tournament created successfully."
  end

  def create_match(tournament_id, match_id, player_1_id, player_2_id)
    # Find the tournament and ensure it exists
    tournament = @tournament_db.find( { "_id": tournament_id } ).first
    
    if tournament.nil?
      puts "Tournament not found."
      return
    end

    if tournament["matches"].any? { |match| match["_id"] == match_id }
      puts "Match with this ID already exists in the tournament."
      return
    end

    if not (tournament["players"].any? { |player| player["_id"] == player_1_id } && tournament["players"].any? { |player| player["_id"] == player_2_id })
      puts "Players or player is not registered."
      return
    end

    player_1 = tournament["players"].find { |player| player["_id"] == player_1_id }
    player_2 = tournament["players"].find { |player| player["_id"] == player_2_id }

    new_match = {
      "_id": match_id,
      "players": [player_1, player_2],
      "game_scores": [],  
      "score": [0, 0],      
    }

    @tournament_db.update_one(
      { "_id": tournament_id },
      { "$push": { "matches" => new_match } }
    )
    puts "Match created succefully."
  end

  def view_player_statistic(tournament_id, player_id)
    # Find the tournament using the provided tournament_id
    tournament = @tournament_db.find( { "_id": tournament_id } ).first
    
    # If tournament is not found, return an error message
    if tournament.nil?
      puts "Tournament not found."
      return
    end
    
    # Find the player in the players array using player_id
    player = tournament["players"].find { |player| player["_id"] == player_id }

    # If player is not found, return an error message
    if player.nil?
      puts "Player is not registered."
      return
    end

    # Return the player's statistics
    return player["statistic"]
  end
end