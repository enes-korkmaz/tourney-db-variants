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

class Fixtures
  attr_accessor :player1_id, :player2_id, :player3_id, :player4_id, :tournament_id, 
                :match1_id, :match2_id

  def initialize
    @player1_id = SecureRandom.uuid
    @player2_id = SecureRandom.uuid
    @player3_id = SecureRandom.uuid
    @player4_id = SecureRandom.uuid
    @tournament_id = SecureRandom.uuid
    @match1_id = SecureRandom.uuid
    @match2_id = SecureRandom.uuid
    @game1_id = SecureRandom.uuid
    @game2_id = SecureRandom.uuid
    @game3_id = SecureRandom.uuid
  end 
  
  def load_fixtures(driver)
    driver.session do |session|
      session.write_transaction do |tx|
        tx.run(
          'CREATE (player1:Player {name: $name_1, id: $id_1}) ' \
          'CREATE (player2:Player {name: $name_2, id: $id_2}) ' \
          'CREATE (player3:Player {name: $name_3, id: $id_3}) ' \
          'CREATE (player4:Player {name: $name_4, id: $id_4}) ' \
          'CREATE (tournament:Tournament {id: $id_5}) ' \
          'CREATE (match1:Match {id: $id_6}) ' \
          'CREATE (match2:Match {id: $id_7}) ' \
          'CREATE (game1:Game {id: $id_8}) ' \
          'CREATE (game2:Game {id: $id_9}) ' \
          'CREATE (game3:Game {id: $id_10}) ' \
          'CREATE (player1)-[:ATTENDS]->(tournament) ' \
          'CREATE (player2)-[:ATTENDS]->(tournament) ' \
          'CREATE (player3)-[:ATTENDS]->(tournament) ' \
          'CREATE (match1)-[:BELONGS_TO]->(tournament) ' \
          'CREATE (match2)-[:BELONGS_TO]->(tournament) ' \
          'CREATE (player1)-[:PLAYS{score: 1}]->(match1) ' \
          'CREATE (player2)-[:PLAYS{score: 2}]->(match1) ' \
          'CREATE (player1)-[:PLAYS{score: 0}]->(match2) ' \
          'CREATE (player2)-[:PLAYS{score: 0}]->(match2) ' \
          'CREATE (player1)-[:LOST]->(match1) ' \
          'CREATE (player2)-[:WON]->(match1) ' \
          'CREATE (match1)-[:CONTAINS]->(game1) ' \
          'CREATE (match1)-[:CONTAINS]->(game2) ' \
          'CREATE (match1)-[:CONTAINS]->(game3) ' \
          'CREATE (game1)-[:INCLUDES{score:7}]->(player1) ' \
          'CREATE (game2)-[:INCLUDES{score:11}]->(player1) ' \
          'CREATE (game3)-[:INCLUDES{score:5}]->(player1) ' \
          'CREATE (game1)-[:INCLUDES{score:11}]->(player2) ' \
          'CREATE (game2)-[:INCLUDES{score:9}]->(player2) ' \
          'CREATE (game3)-[:INCLUDES{score:11}]->(player2)',
          name_1: 'Bob', name_2: 'Alice', name_3: 'Mister_X', name_4: "Eve",
          id_1: @player1_id, id_2: @player2_id, id_3: @player3_id, id_4: @player4_id, id_5: @tournament_id, 
          id_6: @match1_id, id_7: @match2_id, id_8: @game1_id, id_9: @game2_id, id_10: @game3_id
        )
      end
    end
  end

  def clear_database(driver)
    driver.session do |session|
      session.write_transaction do |tx|
        tx.run(
          'MATCH (n) DETACH DELETE n'
        )
      end
    end
  end
end  