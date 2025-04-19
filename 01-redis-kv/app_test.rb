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

require "minitest/autorun"
require "./app.rb"
require "./serializable_classes.rb"
require "./fixtures.rb"

class AppTest < Minitest::Test
	# create new app for each test
    def setup
        @app = App.new
        @fixtures = Fixtures.new
    end

    def teardown
        @app.redis.del("player:1")
        @app.redis.del("player:2")
        @app.redis.del("player:1:statistic")
        @app.redis.del("player:2:statistic")
        @app.redis.del("tournament:1")
        @app.redis.del("tournament:1:players")
        @app.redis.del("match:1")
    end
    
    # tests if players can be registered to a tournaments
    def test_access_pattern_1
        player_1 = @fixtures.test_player_1
        player_2 = @fixtures.test_player_2
        tournament = @fixtures.test_tournament

        #key_values für die einzelnen Objekte erstellen 
        key_player_1 = "player:#{player_1.id.to_s}"
        key_player_2 = "player:#{player_2.id.to_s}"
        key_tournament = "tournament:#{tournament.id.to_s}"

        # Spieler und Turnier in Redis speichern
        @app.redis.set(key_player_1, player_1.to_json)
        @app.redis.set(key_player_2, player_2.to_json)
        @app.redis.set(key_tournament, key_tournament.to_json)

        #IDs der Spieler werden dem Turnier zugewiesen - (per register-Methode in app.rb)
        @app.register(tournament.id, player_1.id)
        @app.register(tournament.id, player_2.id)

        key_tournament_players = "#{key_tournament}:players"

        assert_equal(player_1.id.to_s, @app.redis.lindex(key_tournament_players, 0))
        assert_equal(player_2.id.to_s, @app.redis.lindex(key_tournament_players, 1))
        assert_equal(2, @app.redis.llen(key_tournament_players))
    end

    # tests if match results can be entered
    def test_access_pattern_2
        id = 2
        test_match = Match.new(id, @fixtures.test_player_1, @fixtures.test_player_2)
        @app.redis.set("match:#{id.to_s}", test_match.to_json)
        
        key_player_1_statistic = "player:#{@fixtures.test_player_1.id}:statistic"
        key_player_2_statistic = "player:#{@fixtures.test_player_2.id}:statistic"
        
        @app.enter_result(id, [11, 3])
        match_1 = Match.from_json(@app.redis.get("match:#{id.to_s}"))
        assert_equal([[11, 3], [0, 0], [0, 0]], match_1.game_scores)
        assert_equal([1, 0], match_1.score)
        assert_nil(@app.redis.get(key_player_1_statistic))
        assert_nil(@app.redis.get(key_player_2_statistic))

        @app.enter_result(id, [9, 11])
        match_1 = Match.from_json(@app.redis.get("match:#{id.to_s}"))
        assert_equal([[11, 3], [9, 11], [0, 0]], match_1.game_scores)
        assert_equal([1, 1], match_1.score)
        assert_nil(@app.redis.get(key_player_1_statistic))
        assert_nil(@app.redis.get(key_player_2_statistic))

        @app.enter_result(id, [11, 6])
        match_1 = Match.from_json(@app.redis.get("match:#{id.to_s}"))
        assert_equal([[11, 3], [9, 11], [11, 6]], match_1.game_scores)
        assert_equal([2, 1], match_1.score)
        player_1_statistic = PlayerStatistic.from_json(@app.redis.get(key_player_1_statistic))
        player_2_statistic = PlayerStatistic.from_json(@app.redis.get(key_player_2_statistic))
        assert_equal(1, player_1_statistic.games_played)
        assert_equal(1, player_2_statistic.games_played)
        assert_equal(1, player_1_statistic.games_won)
        assert_equal(0, player_2_statistic.games_won)
        assert_equal(0, player_1_statistic.games_lost)
        assert_equal(1, player_2_statistic.games_lost)

        @app.enter_result(id, [11, 8])
        match_1 = Match.from_json(@app.redis.get("match:#{id.to_s}"))
        assert_equal([[11, 3], [9, 11], [11, 6]], match_1.game_scores)
        assert_equal([2, 1], match_1.score)
        player_1_statistic = PlayerStatistic.from_json(@app.redis.get(key_player_1_statistic))
        player_2_statistic = PlayerStatistic.from_json(@app.redis.get(key_player_2_statistic))
        assert_equal(1, player_1_statistic.games_played)
        assert_equal(1, player_2_statistic.games_played)
        assert_equal(1, player_1_statistic.games_won)
        assert_equal(0, player_2_statistic.games_won)
        assert_equal(0, player_1_statistic.games_lost)
        assert_equal(1, player_2_statistic.games_lost)
    end

    # tests if tournament can be created 
    def test_access_pattern_3
        test_tournament = @fixtures.test_tournament
        key = "tournament:#{test_tournament.id.to_s}"
        @app.create_tournament(test_tournament)
        new_tournament = Tournament.from_json(@app.redis.get(key))
        assert_equal(test_tournament.id, new_tournament.id)
        assert_equal(test_tournament.matches[0].id, new_tournament.matches[0].id)
    end

    # tests if match can be created
    def test_access_pattern_4
        test_match = @fixtures.test_match
        key = "match:#{test_match.id.to_s}"
        @app.create_match(test_match)
        new_match = Match.from_json(@app.redis.get(key))
        assert_equal(test_match.id, new_match.id)
        assert_equal(test_match.players[0].id, new_match.players[0].id)
        assert_equal(test_match.players[1].id, new_match.players[1].id)
    end

    # tests if player statistics can be read
    def test_access_pattern_5
        player1 = @fixtures.test_player_1
        player2 = @fixtures.test_player_2
        stat1 = @fixtures.test_statistic_1
        stat2 = @fixtures.test_statistic_2

        # Load statistics for the test players into Redis
        @app.redis.set("player:#{player1.id}:statistic", stat1.to_json)
        @app.redis.set("player:#{player2.id}:statistic", stat2.to_json)

        # Retrieves the statistics for player 1 & 2
        stats1 = @app.view_player_statistic(player1.id)
        stats2 = @app.view_player_statistic(player2.id)

        # Assert that the retrieved stats match the values from the fixtures
        assert_equal stat1.games_played, stats1.games_played
        assert_equal stat1.games_won, stats1.games_won
        assert_equal stat1.games_lost, stats1.games_lost
        
        assert_equal stat2.games_played, stats2.games_played
        assert_equal stat2.games_won, stats2.games_won
        assert_equal stat2.games_lost, stats2.games_lost
    end
end