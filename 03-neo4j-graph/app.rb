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

require 'neo4j-ruby-driver'

class App
  attr_accessor :driver

  def initialize
    @driver = Neo4j::Driver::GraphDatabase.driver('neo4j://neo:7687', Neo4j::Driver::AuthTokens.basic('neo4j', 'hello_neo'))
     
    begin
      @driver.verify_connectivity
      puts "Connection established"
    rescue => e
      puts "Error connecting to MongoDB: #{e.message}"
    end
  end 

  def register(player_id, tournament_id)
    success = false
    @driver.session do |session|
      session.write_transaction do |tx|
        player = tx.run(
          'MATCH (player:Player {id: $player_id}) RETURN player',
          player_id: player_id
        )
        tournament = tx.run(
          'MATCH (tournament:Tournament {id: $tournament_id}) RETURN tournament',
          tournament_id: tournament_id
        )
        edge = tx.run(
          'MATCH (:Player {id: $player_id})-[edge:ATTENDS]->(t:Tournament {id: $tournament_id}) RETURN edge',
          player_id: player_id, tournament_id: tournament_id
        )
        if player.to_a.size == 1 && tournament.to_a.size == 1 && edge.to_a.size == 0
          tx.run(
            'MATCH (player:Player {id: $player_id}) ' \
            'MATCH (tournament:Tournament {id: $tournament_id}) ' \
            'MERGE (player)-[:ATTENDS]->(tournament)',
            player_id: player_id, tournament_id: tournament_id
          )
          success = true
        end
      end
    end
    return success
  end

  def enter_result(match_id, player1_id, player2_id, score_player1, score_player2)
    success = false
    @driver.session do |session|
      session.write_transaction do |tx|
        # Check if the match with both players attending exists
        check = tx.run(
          'MATCH (p1:Player)-[:PLAYS]->(m:Match)<-[:PLAYS]-(p2:Player) ' \
          'WHERE m.id = $match_id AND p1.id = $player1_id AND p2.id = $player2_id ' \
          'RETURN m',
          match_id: match_id, player1_id: player1_id, player2_id: player2_id
        )

        if check.to_a.size == 1
          # Check if match is already finished - checking for WON-LOST-Relations is also viable
          match_finished = tx.run(
            'MATCH (p1:Player)-[rel1:PLAYS]->(m:Match)<-[rel2:PLAYS]-(p2:Player) ' \
            'WHERE m.id = $match_id AND p1.id = $player1_id AND p2.id = $player2_id ' \
            'RETURN rel1.score AS player1_match_score, rel2.score AS player2_match_score',
            match_id: match_id, player1_id: player1_id, player2_id: player2_id
          ).first
        
          player1_match_score = match_finished['player1_match_score'].to_i
          player2_match_score = match_finished['player2_match_score'].to_i
        
          if player1_match_score < 2 && player2_match_score < 2
            new_game_id = SecureRandom.uuid

            # Create the next game, link it to the match and set the scores for the players
            tx.run(
              'MATCH (m:Match {id: $match_id}) ' \
              'MATCH (p1:Player {id: $player1_id}) ' \
              'MATCH (p2:Player {id: $player2_id}) ' \
              'CREATE (g:Game {id: $game_id}) ' \
              'MERGE (m)-[:CONTAINS]->(g) ' \
              'MERGE (g)-[:INCLUDES {score: $p1_score}]->(p1) ' \
              'MERGE (g)-[:INCLUDES {score: $p2_score}]->(p2)',
              game_id: new_game_id, player1_id: player1_id, player2_id: player2_id,
              match_id: match_id, p1_score: score_player1, p2_score: score_player2
            )

            # Processing of the game scores
            game_over = false
            winner_id = nil
            loser_id = nil
            if score_player1 > score_player2
              player1_match_score += 1
              if player1_match_score >= 2
                game_over = true 
                winner_id = player1_id
                loser_id = player2_id
              end
            elsif score_player1 < score_player2
              player2_match_score += 1
              if player2_match_score >= 2
                game_over = true 
                winner_id = player2_id
                loser_id = player1_id
              end
            end

            # Update the scores for the match based on game results
            tx.run(
              'MATCH (p1:Player)-[r1:PLAYS]->(m:Match)<-[r2:PLAYS]-(p2:Player) ' \
              'WHERE m.id = $match_id AND p1.id = $player1_id AND p2.id = $player2_id ' \
              'SET r1.score = $player1_score, r2.score = $player2_score',
              match_id: match_id, player1_id: player1_id, player2_id: player2_id,
              player1_score: player1_match_score, player2_score: player2_match_score
            )

            if game_over
                # Adding winner and loser relationships for the match
                tx.run(
                  'MATCH (m:Match {id: $match_id}) ' \
                  'MATCH (winner:Player {id: $winner_id}) ' \
                  'MATCH (loser:Player {id: $loser_id}) ' \
                  'MERGE (winner)-[:WON]->(m) ' \
                  'MERGE (loser)-[:LOST]->(m)',
                  match_id: match_id, winner_id: winner_id, loser_id: loser_id
                )
            end

            success = true
          end
        end
      end
    end
    return success
  end  

  def create_tournament
    tournament_id = SecureRandom.uuid
    
    @driver.session do |session|
      session.write_transaction do |tx|
        # Create the tournament
        tx.run(
          'CREATE (:Tournament {id: $id})',
          id: tournament_id
        )
      end
    end

    return tournament_id
  end

  def create_match(tournament_id, player1_id, player2_id)
    match_id = nil
    
    @driver.session do |session|
      session.write_transaction do |tx|
        # Check if the tournament exists
        tournament = tx.run(
          'MATCH (t:Tournament {id: $tournament_id}) RETURN t',
          tournament_id: tournament_id
        )
        # Check if the players exist
        player1 = tx.run(
          'MATCH (p:Player {id: $player_id}) RETURN p',
          player_id: player1_id
        )
        player2 = tx.run(
          'MATCH (p:Player {id: $player_id}) RETURN p',
          player_id: player2_id
        )
  
        if tournament.to_a.size == 1 && player1.to_a.size == 1 && player2.to_a.size == 1
          # Create the match and associate it with the tournament
          match_id = SecureRandom.uuid
          result = tx.run(
            'MATCH (tournament:Tournament {id: $tournament_id}) ' \
            'MATCH (player1:Player {id: $player1_id}) ' \
            'MATCH (player2:Player {id: $player2_id}) ' \
            'CREATE (match:Match {id: $match_id}) ' \
            'MERGE (match)-[:BELONGS_TO]->(tournament)' \
            'MERGE (player1)-[:PLAYS {score: 0}]->(match) ' \
            'MERGE (player2)-[:PLAYS {score: 0}]->(match)',
            match_id: match_id, tournament_id: tournament_id, player1_id: player1_id, player2_id: player2_id
          )
        end
      end
    end

    return match_id
  end
  
  def view_player_statistic(player_id, tournament_id)
    statistic = nil

    @driver.session do |session|
      session.read_transaction do |tx|
        # Check if the player exists
        player = tx.run(
          'MATCH (p:Player {id: $player_id}) RETURN p',
          player_id: player_id
        )
        # Check if the player attends the tournament
        attending = tx.run(
          'MATCH (p:Player {id: $player_id})-[:ATTENDS]->(:Tournament {id: $tournament_id}) RETURN p',
          player_id: player_id, tournament_id: tournament_id
        )

        if player.to_a.size == 1
          if tournament_id.nil?
            # Get general statistic
            wins = tx.run(
              'MATCH (:Player {id: $player_id})-[w:WON]->(:Match) RETURN w',
              player_id: player_id
            )
            losses = tx.run(
              'MATCH (:Player {id: $player_id})-[l:LOST]->(:Match) RETURN l',
              player_id: player_id
            )
            win_count = wins.to_a.size
            loss_count = losses.to_a.size
            statistic = [win_count + loss_count, win_count, loss_count]
          elsif attending.to_a.size == 1
            # Get statistic for tournament
            wins = tx.run(
              'MATCH (:Player {id: $player_id})-[w:WON]->(match:Match),
                     (match)-[:BELONGS_TO]->(:Tournament {id: $tournament_id}) ' \
              'RETURN w',
              player_id: player_id, tournament_id: tournament_id
            )
            losses = tx.run(
              'MATCH (:Player {id: $player_id})-[l:LOST]->(match:Match),
                     (match)-[:BELONGS_TO]->(:Tournament {id: $tournament_id}) ' \
              'RETURN l',
              player_id: player_id, tournament_id: tournament_id
            )
            win_count = wins.to_a.size
            loss_count = losses.to_a.size
            statistic = [win_count + loss_count, win_count, loss_count]
          end
        end
      end
    end

    return statistic
  end
end  