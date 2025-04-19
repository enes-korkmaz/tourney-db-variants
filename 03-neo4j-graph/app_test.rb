require "minitest/autorun"
require "./app.rb"
require "./fixtures.rb"

class AppTest < Minitest::Test
  def setup
    puts "\n"
    @app = App.new
    @fixtures = Fixtures.new
    @fixtures.load_fixtures(@app.driver)
  end

  def teardown
    @fixtures.clear_database(@app.driver)
    @app.driver.close
    puts "Driver closed\n"
  end

  def test_access_pattern_1
    # Define the test data using fixtures
    registered_player_id = @fixtures.player2_id
    unregistered_player_id = @fixtures.player4_id
    tournament_id = @fixtures.tournament_id

    # 1. Test case: Player does not exist
    refute(@app.register("non-existing-player-id", tournament_id))
    
    # 2. Test case: Tournament does not exist
    refute(@app.register(unregistered_player_id, "non-existing-tournament-id"))

    # 3. Test case: Player already registered in the tournament
    refute(@app.register(registered_player_id, tournament_id))

    @app.driver.session do |session|
      session.read_transaction do |tx|
        result = tx.run(
          'MATCH (:Player {id: $player_id})-[edge:ATTENDS]->(:Tournament {id: $tournament_id}) RETURN edge',
          player_id: unregistered_player_id, tournament_id: tournament_id 
        )
        assert_equal(0, result.to_a.size)
      end
    end

    # 4. Test case: Valid player and tournament, thus we can register the player
    @app.register(unregistered_player_id, tournament_id)
    
    @app.driver.session do |session|
      session.read_transaction do |tx|
        result = tx.run(
          'MATCH (:Player {id: $player_id})-[edge:ATTENDS]->(:Tournament {id: $tournament_id}) RETURN edge',
          player_id: unregistered_player_id, tournament_id: tournament_id 
        )
        assert_equal(1, result.to_a.size)
      end
    end
  end

  def test_access_pattern_2
    player1_id = @fixtures.player1_id
    player2_id = @fixtures.player2_id
    match_id = @fixtures.match2_id

    # Test Case 1: Attempt to enter result for a non-existing match
    assert_equal(false, @app.enter_result('non_existing_match_id', player1_id, player2_id, 11, 7))

    # Test Case 2: One or both players are not part of the match
    assert_equal(false, @app.enter_result(match_id, player1_id, 'invalid_player_id', 11, 6))

    # Test Case 3: Successfully entering a score for a valid match and player pair
    assert_equal(true, @app.enter_result(match_id, player1_id, player2_id, 9, 11))
    assert_equal(true, @app.enter_result(match_id, player1_id, player2_id, 7, 11))

    # Test Case 4: Entering a scorce for a match that has already been finished
    assert_equal(false, @app.enter_result(match_id, player1_id, player2_id, 11, 7))
    
    @app.driver.session do |session|
      session.read_transaction do |tx|
        winner = tx.run(
          'MATCH (winner:Player {id: $player_id})-[:WON]->(m:Match {id: $match_id}) ' \
          'MATCH (winner)-[:PLAYS {score: 2}]->(m) RETURN winner',
          match_id: match_id, player_id: player2_id
        )
        assert_equal(1, winner.to_a.size)

        loser = tx.run(
          'MATCH (loser:Player {id: $player_id})-[:LOST]->(m:Match {id: $match_id}) ' \
          'MATCH (loser)-[:PLAYS {score: 0}]->(m) RETURN loser',
          match_id: match_id, player_id: player1_id
        )
        assert_equal(1, loser.to_a.size)

        games = tx.run(
          'MATCH (:Match {id: $match_id})-[:CONTAINS]->(g:Game) RETURN g',
          match_id: match_id
        )
        assert_equal(2, games.to_a.size)
      end
      
    end
  end

  def test_access_pattern_3
    id = @app.create_tournament

    @app.driver.session do |session|
      session.read_transaction do |tx|
        result = tx.run(
          'MATCH (t:Tournament) RETURN t'
        )
        assert_equal(2, result.to_a.size)

        result = tx.run(
          'MATCH (x:Tournament {id: $tournament_id}) RETURN x', 
           tournament_id: id
        )
        assert_equal(1, result.to_a.size)
      end
    end
  end

  def test_access_pattern_4
    non_existing_tournament_id = "non-existing-tournament-id"
    existing_tournament_id = @fixtures.tournament_id
    non_existing_player_id = "non_existing_player_id"
    existing_player_id_1 = @fixtures.player1_id
    existing_player_id_2 = @fixtures.player2_id

    # 1. Test case: Tournament does not exist
    assert_nil(@app.create_match(non_existing_tournament_id, existing_player_id_1, existing_player_id_2))

    # 2. Test case: Player does not exist
    assert_nil(@app.create_match(existing_tournament_id, non_existing_player_id, existing_player_id_2))
    assert_nil(@app.create_match(existing_tournament_id, existing_player_id_1, non_existing_player_id))

    # 3. Test case: Create the match and associate it with the tournament
    match_id = @app.create_match(existing_tournament_id, existing_player_id_1, existing_player_id_2)
    
    # Test case: Match with id does already exist - not a practical test scenario
    # Unless there is a bug in UUID v4 generation this case should be extremly low
    
    # Ensure tournament was created and returned an ID
    refute_nil(match_id, "Expected a valid tournament ID to be returned.")

    @app.driver.session do |session|
      session.read_transaction do |tx|
        # Query the BELONGS_TO relationship between Match and Tournament
        result = tx.run(
          'MATCH (match:Match {id: $match_id})-[:BELONGS_TO]->(:Tournament {id: $tournament_id}) ' \
          'MATCH (:Player {id: $player1_id})-[:PLAYS {score: 0}]->(match) ' \
          'MATCH (:Player {id: $player2_id})-[:PLAYS {score: 0}]->(match) ' \
          'RETURN match',
          match_id: match_id, tournament_id: existing_tournament_id,
          player1_id: existing_player_id_1, player2_id: existing_player_id_2
        )
        
        assert_equal(1, result.to_a.size)
      end
    end
  end  

  def test_access_pattern_5
    # Define the test data using fixtures
    tournament_id = @fixtures.tournament_id
    player1_with_matches_id = @fixtures.player1_id
    player2_with_matches_id = @fixtures.player2_id
    player_without_matches_id = @fixtures.player3_id
    player_without_tournament_id = @fixtures.player4_id
      
    # 1. Test case: Tournament does not exist
    assert_nil(@app.view_player_statistic(player2_with_matches_id, "non-existing-tournament-id"))

    # 2. Test case: Player does not exist
    assert_nil(@app.view_player_statistic("non-existing-player-id", tournament_id))

    # 3. Test case: Player is not in tournament
    assert_nil(@app.view_player_statistic(player_without_tournament_id, tournament_id))

    # 4. Test case: Player has no matches in the tournament
    assert_equal([0, 0, 0], @app.view_player_statistic(player_without_matches_id, tournament_id))

    # 5. Test case: Player with matches in the tournament
    assert_equal([1, 0, 1], @app.view_player_statistic(player1_with_matches_id, tournament_id))
    assert_equal([1, 1, 0], @app.view_player_statistic(player2_with_matches_id, tournament_id))

    # 6. Test case: No Tournament specified - Fetches general statistic
    assert_equal([1, 0, 1], @app.view_player_statistic(player1_with_matches_id, nil))
    assert_equal([1, 1, 0], @app.view_player_statistic(player2_with_matches_id, nil))
  end
end