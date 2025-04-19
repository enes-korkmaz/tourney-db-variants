require "minitest/autorun"
require "./app.rb"
require "./fixtures.rb"

class AppTest < Minitest::Test
  def setup
    @app = App.new
    @tournament_db = @app.tournament_db
    fixtures = Fixtures.new
    @tournament_db.insert_one(fixtures.tournament)
  end

  def teardown
    @tournament_db.delete_many
  end

  def test_access_pattern_1
    # Initial database state (db_state_1) before registration
    db_state_1 = @tournament_db.find()
  
    # Check the case where a player is already registered
    assert_output("Player is already registered.\n") do
      @app.register(1, 1, "BOB")
    end
  
    # Ensure that the database state has not changed
    db_state_2 = @tournament_db.find()
    assert_equal(db_state_1, db_state_2)
  
    # Check the case where the tournament does not exist
    assert_output("Tournament not found.\n") do
      @app.register(2, 3, "BOB")
    end
  
    # Ensure that the database state has not changed
    db_state_3 = @tournament_db.find()
    assert_equal(db_state_1, db_state_3)
  
    # Successful registration of a new player
    assert_output("Player registered successfully.\n") do
      @app.register(1, 3, "BOB")
    end
  
    # Verify that the database was updated
    tournament = @tournament_db.find( { "_id": 1 } ).first
    players = tournament["players"]
  
    # Check that there are now 3 players registered in the tournament
    assert_equal(3, players.size)
  
    # Check that the new player "BOB" with ID "3" exists
    refute_nil(players.find { |player| player["_id"] == 3 && player["name"] == "BOB" })      
  end

  def test_access_pattern_2
    # Initial database state (db_state_1) before creation
    db_state_1 = @tournament_db.find()
  
    # Check the case where a tournament exists
    assert_output("Tournament not found.\n") do
      @app.enter_result(2, 1, [11, 7])
    end
   
    # Ensure that the database state has not changed
    db_state_2 = @tournament_db.find()
    assert_equal(db_state_1, db_state_2)

    # Check the case where a match does not exists
    assert_output("Match not found.\n") do
      @app.enter_result(1, 3, [11, 7])
    end
  
    # Ensure that the database state has not changed
    db_state_3 = @tournament_db.find()
    assert_equal(db_state_1, db_state_3)

    # Check the case where a match is finished after 2 games
    assert_output("Match result entered successfully.\n") do
      @app.enter_result(1, 2, [11, 7])
    end

    assert_output("Match is already finished.\n") do
      @app.enter_result(1, 2, [11, 7])
    end
    
    db_state_4 = @tournament_db.find()
    assert_equal([2, 0], db_state_4.find( { "_id": 1 } ).first["matches"].find { |match| match["_id"] == 2 }["score"])
    assert_equal([[11, 7], [11, 7]], db_state_4.find( { "_id": 1 } ).first["matches"].find { |match| match["_id"] == 2 }["game_scores"])
    assert_equal([2, 2, 0], db_state_4.find( { "_id": 1 } ).first["players"].find { |player| player["_id"] == 1}["statistic"])
    assert_equal([2, 0, 2], db_state_4.find( { "_id": 1 } ).first["players"].find { |player| player["_id"] == 2}["statistic"])
    assert_equal([2, 2, 0], db_state_4.find( { "_id": 1 } ).first["matches"].find { |match| match["_id"] == 1 }["players"].find { |player| player["_id"] == 1}["statistic"])
    assert_equal([2, 0, 2], db_state_4.find( { "_id": 1 } ).first["matches"].find { |match| match["_id"] == 1 }["players"].find { |player| player["_id"] == 2}["statistic"])

    # Check the case where a match is finished after 3 games
    assert_output("Match result entered successfully.\n") do
      @app.enter_result(1, 4, [7, 11])
    end

    assert_output("Match result entered successfully.\n") do
      @app.enter_result(1, 4, [11, 7])
    end

    assert_output("Match is already finished.\n") do
      @app.enter_result(1, 4, [11, 7])
    end

    db_state_5 = @tournament_db.find()
    assert_equal([2, 1], db_state_5.find( { "_id": 1 } ).first["matches"].find { |match| match["_id"] == 4 }["score"])
    assert_equal([[11, 7], [7, 11], [11, 7]], db_state_5.find( { "_id": 1 } ).first["matches"].find { |match| match["_id"] == 4 }["game_scores"])
    assert_equal([3, 3, 0], db_state_4.find( { "_id": 1 } ).first["players"].find { |player| player["_id"] == 1}["statistic"])
    assert_equal([3, 0, 3], db_state_4.find( { "_id": 1 } ).first["players"].find { |player| player["_id"] == 2}["statistic"])
    assert_equal([3, 3, 0], db_state_4.find( { "_id": 1 } ).first["matches"].find { |match| match["_id"] == 1 }["players"].find { |player| player["_id"] == 1}["statistic"])
    assert_equal([3, 0, 3], db_state_4.find( { "_id": 1 } ).first["matches"].find { |match| match["_id"] == 1 }["players"].find { |player| player["_id"] == 2}["statistic"])

  end

  def test_access_pattern_3
    # Initial database state (db_state_1) before creation
    db_state_1 = @tournament_db.find()
  
    # Check the case where a tournement already exists
    assert_output("Tournament already exist.\n") do
      @app.create_tournament(1)
    end
  
    # Ensure that the database state has not changed
    db_state_2 = @tournament_db.find()
    assert_equal(db_state_1, db_state_2)
  
    # Check the case where the tournament does not exist
    assert_output("Tournament created successfully.\n") do
      @app.create_tournament(2)
    end

    # Check that there are now 2 tournaments in the db
    db_state_3 = @tournament_db.find()
    assert_equal(2, db_state_3.count_documents)

    # Check that the new player "BOB" with ID "3" exists
    # refute_nil(db_state_3.find { |tournament| tournament["_id"] == "2" && tournament["players"] == [] && tournament["matches"] == []})
  end

  def test_access_pattern_4
    # Initial database state (db_state_1) before creation
    db_state_1 = @tournament_db.find()
  
    # Check the case where a tournament exists
    assert_output("Tournament not found.\n") do
      @app.create_match(2, 1, 1, 2)
    end
   
    # Ensure that the database state has not changed
    db_state_2 = @tournament_db.find()
    assert_equal(db_state_1, db_state_2) 

    # Check the case where a match exists
    assert_output("Match with this ID already exists in the tournament.\n") do
      @app.create_match(1, 1, 1, 2)
    end
  
    # Ensure that the database state has not changed
    db_state_3 = @tournament_db.find()
    assert_equal(db_state_1, db_state_3)

    # Check the case where players are not registered
    assert_output("Players or player is not registered.\n") do
      @app.create_match(1, 3, 3, 4)
    end
  
    # Ensure that the database state has not changed
    db_state_4 = @tournament_db.find()
    assert_equal(db_state_1, db_state_4)

    # Check the case where the match can be created
    assert_output("Match created succefully.\n") do
      @app.create_match(1, 3, 1, 2)
    end
    
    # Verify that the database was updated
    tournament = @tournament_db.find( { "_id": 1 } ).first
    matches = tournament["matches"]
  
    # Check that there are now 3 players registered in the tournament
    assert_equal(4, matches.size)
  
    # Find players by ID within the players array of the tournament document
    player_1 = db_state_1.find( { "_id": 1 } ).first["players"].find { |player| player["_id"] == 1 }
    player_2 = db_state_1.find( { "_id": 1 } ).first["players"].find { |player| player["_id"] == 2 }
    
    # Ensure the match with the specified conditions exists
    refute_nil(
      matches.find do |match|
        match["_id"] == 3 &&
        match["game_scores"] == [] &&
        match["score"] == [0, 0] &&
        match["players"] == [player_1, player_2]
      end
    )
  end

  def test_access_pattern_5
    # Initial database state (db_state_1) before creation
    db_state_1 = @tournament_db.find()
  
    # Check the case where a tournament exists
    assert_output("Tournament not found.\n") do
      @app.view_player_statistic(2, 1)
    end
   
    # Ensure that the database state has not changed
    db_state_2 = @tournament_db.find()
    assert_equal(db_state_1, db_state_2)

    # Check the case where player is not registered
    assert_output("Player is not registered.\n") do
      @app.view_player_statistic(1, 3)
    end
  
    # Ensure that the database state has not changed
    db_state_3 = @tournament_db.find()
    assert_equal(db_state_1, db_state_3)
    
    assert_equal([1, 1, 0], @app.view_player_statistic(1, 1))
    
    # Ensure that the database state has not changed
    db_state_4 = @tournament_db.find()
    assert_equal(db_state_1, db_state_4)
  end
end