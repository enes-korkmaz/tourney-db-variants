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
require "./fixtures.rb"

class AppTest < Minitest::Test
  def setup
    @table_name = 'badminton_tournaments'
    @app = App.new(@table_name)
    @fixtures = Fixtures.new(@app.dynamodb, @table_name)
    @fixtures.load_fixtures
  end

  def teardown
    @fixtures.clear_database
  end

  def test_access_pattern_1
    @app.register(@fixtures.player4_id, @fixtures.tournament_id)

    registered_player = @app.dynamodb.get_item({ 
      table_name: @table_name,
      key: {
        'PK' => 'TOURNAMENT#' + @fixtures.tournament_id,
        'SK' => 'PLAYER#' + @fixtures.player4_id
      }
    })

    assert_equal("Eve", registered_player[:item]['name'])
  end 

  def test_access_pattern_2
    @app.enter_restult(@fixtures.match2_id, @fixtures.player1_id, @fixtures.player2_id, 8, 11)
    @app.enter_restult(@fixtures.match2_id, @fixtures.player1_id, @fixtures.player2_id, 11, 5)
    @app.enter_restult(@fixtures.match2_id, @fixtures.player1_id, @fixtures.player2_id, 9, 11)

    the_match = @app.dynamodb.get_item({
      table_name: 'badminton_tournaments',
      key: {
        'PK' => 'MATCH#' + @fixtures.match2_id,
        'SK' => 'MATCH#' + @fixtures.match2_id
      }
    })
    player1 = @app.dynamodb.get_item({
      table_name: 'badminton_tournaments',
      key: {
        'PK' => 'MATCH#' + @fixtures.match2_id,
        'SK' => 'PLAYER#' + @fixtures.player1_id
      }
    })
    player2 = @app.dynamodb.get_item({
      table_name: 'badminton_tournaments',
      key: {
        'PK' => 'MATCH#' + @fixtures.match2_id,
        'SK' => 'PLAYER#' + @fixtures.player2_id
      }
    })

    assert_equal(3, the_match[:item]['played'])
    assert_equal(true, the_match[:item]['over'])
    assert_equal(1, player1[:item]['score'])
    assert_equal(8, player1[:item]['game1'])
    assert_equal(11, player1[:item]['game2'])
    assert_equal(9, player1[:item]['game3'])
    assert_equal(2, player2[:item]['score'])
    assert_equal(11, player2[:item]['game1'])
    assert_equal(5, player2[:item]['game2'])
    assert_equal(11, player2[:item]['game3'])

    player1_statistic_all = @app.dynamodb.get_item({
      table_name: 'badminton_tournaments',
      key: {
        'PK' => 'PLAYER#' + @fixtures.player1_id,
        'SK' => 'PLAYER#' + @fixtures.player1_id
      }
    })
    player2_statistic_all = @app.dynamodb.get_item({
      table_name: 'badminton_tournaments',
      key: {
        'PK' => 'PLAYER#' + @fixtures.player2_id,
        'SK' => 'PLAYER#' + @fixtures.player2_id
      }
    })
    player1_statistic_tournament = @app.dynamodb.get_item({
      table_name: 'badminton_tournaments',
      key: {
        'PK' => 'TOURNAMENT#' + @fixtures.tournament_id,
        'SK' => 'PLAYER#' + @fixtures.player1_id
      }
    })
    player2_statistic_tournament = @app.dynamodb.get_item({
      table_name: 'badminton_tournaments',
      key: {
        'PK' => 'TOURNAMENT#' + @fixtures.tournament_id,
        'SK' => 'PLAYER#' + @fixtures.player2_id
      }
    })

    assert_equal(2, player1_statistic_all[:item]['played'])
    assert_equal(0, player1_statistic_all[:item]['won'])
    assert_equal(2, player1_statistic_all[:item]['lost'])
    assert_equal(2, player1_statistic_tournament[:item]['played'])
    assert_equal(0, player1_statistic_tournament[:item]['won'])
    assert_equal(2, player1_statistic_tournament[:item]['lost'])
    assert_equal(2, player2_statistic_all[:item]['played'])
    assert_equal(2, player2_statistic_all[:item]['won'])
    assert_equal(0, player2_statistic_all[:item]['lost'])
    assert_equal(2, player2_statistic_tournament[:item]['played'])
    assert_equal(2, player2_statistic_tournament[:item]['won'])
    assert_equal(0, player2_statistic_tournament[:item]['lost'])
  end 

  def test_access_pattern_3
    tournament_id = @app.create_tournament('tournament')

    new_tournament = @app.dynamodb.get_item({ 
      table_name: @table_name,
      key: {
        'PK' => 'TOURNAMENT#' + tournament_id,
        'SK' => 'TOURNAMENT#' + tournament_id
      }
    })

    assert_equal('tournament', new_tournament[:item]['name'])
  end 
   
  def test_access_pattern_4
    match_id = @app.create_match(@fixtures.tournament_id, @fixtures.player3_id, @fixtures.player4_id)

    new_match = @app.dynamodb.get_item({ 
      table_name: @table_name,
      key: {
        'PK' => 'MATCH#' + match_id,
        'SK' => 'MATCH#' + match_id
      }
    })
    also_new_match = @app.dynamodb.query({
      table_name: @table_name,
      index_name: 'GSI1',
      key_condition_expression: 'GSI1PK = :partition_value AND GSI1SK = :sort_value',
      expression_attribute_values: {
        ':partition_value' => 'TOURNAMENT#' + @fixtures.tournament_id,
        ':sort_value' => 'MATCH#' + match_id
      },
    })
    player3 = @app.dynamodb.get_item({ 
      table_name: @table_name,
      key: {
        'PK' => 'MATCH#' + match_id,
        'SK' => 'PLAYER#' + @fixtures.player3_id
      }
    })
    player4 = @app.dynamodb.get_item({ 
      table_name: @table_name,
      key: {
        'PK' => 'MATCH#' + match_id,
        'SK' => 'PLAYER#' + @fixtures.player4_id
      }
    })

    assert_equal(new_match[:item], also_new_match.items.first)
    assert_equal(0, new_match[:item]['played'])
    assert_equal(false, new_match[:item]['over'])
    assert_equal(0, player3[:item]['game1'])
    assert_equal(0, player3[:item]['score'])
    assert_equal(0, player4[:item]['game1'])
    assert_equal(0, player4[:item]['score'])
  end 

  def test_access_pattern_5
    statistic1 = @app.view_player_statistc(@fixtures.player1_id, @fixtures.tournament_id)
    statistic2 = @app.view_player_statistc(@fixtures.player1_id, nil)

    assert_equal(1, statistic1[:item]['played'])
    assert_equal(0, statistic1[:item]['won'])
    assert_equal(1, statistic1[:item]['lost'])
    assert_equal(1, statistic2[:item]['played'])
    assert_equal(0, statistic2[:item]['won'])
    assert_equal(1, statistic2[:item]['lost'])
  end 
end