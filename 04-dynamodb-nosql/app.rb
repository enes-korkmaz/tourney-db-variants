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

require 'aws-sdk-dynamodb'

class App
  attr_reader :dynamodb

  def initialize(table_name)
    @table_name = table_name
    @dynamodb = Aws::DynamoDB::Client.new(
      endpoint: 'http://dynamo:8000',
      region: ENV['REGION'],
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY']
    )
  end

  def register(player_id, tournament_id)
    player = @dynamodb.get_item({
      table_name: 'badminton_tournaments',
      key: {
        'PK' => 'PLAYER#' + player_id,
        'SK' => 'PLAYER#' + player_id
      }
    })
    @dynamodb.put_item({
      table_name: 'badminton_tournaments',
      item: {
        'PK' => 'TOURNAMENT#' + tournament_id,
        'SK' => 'PLAYER#' + player_id,
        'name' => player[:item]['name'],
        'played' => 0,
        'won' => 0,
        'lost' => 0
      }
    })
  end 

  def enter_restult(match_id, player1_id, player2_id, score_player1, score_player2)
    the_match = @dynamodb.get_item({
      table_name: 'badminton_tournaments',
      key: {
        'PK' => 'MATCH#' + match_id,
        'SK' => 'MATCH#' + match_id
      }
    })
    player1 = @dynamodb.get_item({
      table_name: 'badminton_tournaments',
      key: {
        'PK' => 'MATCH#' + match_id,
        'SK' => 'PLAYER#' + player1_id
      }
    })
    player2 = @dynamodb.get_item({
      table_name: 'badminton_tournaments',
      key: {
        'PK' => 'MATCH#' + match_id,
        'SK' => 'PLAYER#' + player2_id
      }
    })

    game = (the_match[:item]['played'] + 1).to_i
    player1_won = score_player1 > score_player2
    new_player1_score = (player1_won ? player1[:item]['score'] + 1 : player1[:item]['score']).to_i
    new_player2_score = (player1_won ? player2[:item]['score'] : player2[:item]['score'] + 1).to_i
    game_over = (new_player1_score >= 2 or new_player2_score >= 2)

    @dynamodb.update_item({
      table_name: @table_name,
      key: {
        'PK' => 'MATCH#' + match_id,
        'SK' => 'MATCH#' + match_id
      },
      update_expression: 'SET #played = :played_val, #over = :over_val',
      expression_attribute_names: {
        '#played' => 'played',
        '#over' => 'over'
      },
      expression_attribute_values: {
        ':played_val' => game,
        ':over_val' => game_over
      }
    })
    @dynamodb.update_item({
      table_name: @table_name,
      key: {
        'PK' => 'MATCH#' + match_id,
        'SK' => 'PLAYER#' + player1_id
      },
      update_expression: 'SET #game = :game_val, #score = :score_val',
      expression_attribute_names: {
        '#game' => 'game' + game.to_s,
        '#score' => 'score'
      },
      expression_attribute_values: {
        ':game_val' => score_player1,
        ':score_val' => new_player1_score
      }
    })
    @dynamodb.update_item({
      table_name: @table_name,
      key: {
        'PK' => 'MATCH#' + match_id,
        'SK' => 'PLAYER#' + player2_id
      },
      update_expression: 'SET #game = :game_val, #score = :score_val',
      expression_attribute_names: {
        '#game' => 'game' + game.to_s,
        '#score' => 'score'
      },
      expression_attribute_values: {
        ':game_val' => score_player2,
        ':score_val' => new_player2_score
      }
    })

    if game_over
      @dynamodb.update_item({
        table_name: @table_name,
        key: {
          'PK' => the_match[:item]['GSI1PK'],
          'SK' => 'PLAYER#' + player1_id
        },
        update_expression: 'SET #played = #played + :played_val, #won = #won + :won_val, #lost = #lost + :lost_val',
        expression_attribute_names: {
          '#played' => 'played',
          '#won' => 'won',
          '#lost' => 'lost'
        },
        expression_attribute_values: {
          ':played_val' => 1,
          ':won_val' => player1_won ? 1 : 0,
          ':lost_val' => player1_won ? 0 : 1
        }
      })
      @dynamodb.update_item({
        table_name: @table_name,
        key: {
          'PK' => 'PLAYER#' + player1_id,
          'SK' => 'PLAYER#' + player1_id
        },
        update_expression: 'SET #played = #played + :played_val, #won = #won + :won_val, #lost = #lost + :lost_val',
        expression_attribute_names: {
          '#played' => 'played',
          '#won' => 'won',
          '#lost' => 'lost'
        },
        expression_attribute_values: {
          ':played_val' => 1,
          ':won_val' => player1_won ? 1 : 0,
          ':lost_val' => player1_won ? 0 : 1
        }
      })
      @dynamodb.update_item({
        table_name: @table_name,
        key: {
          'PK' => the_match[:item]['GSI1PK'],
          'SK' => 'PLAYER#' + player2_id
        },
        update_expression: 'SET #played = #played + :played_val, #won = #won + :won_val, #lost = #lost + :lost_val',
        expression_attribute_names: {
          '#played' => 'played',
          '#won' => 'won',
          '#lost' => 'lost'
        },
        expression_attribute_values: {
          ':played_val' => 1,
          ':won_val' => player1_won ? 0 : 1,
          ':lost_val' => player1_won ? 1 : 0
        }
      })
      @dynamodb.update_item({
        table_name: @table_name,
        key: {
          'PK' => 'PLAYER#' + player2_id,
          'SK' => 'PLAYER#' + player2_id
        },
        update_expression: 'SET #played = #played + :played_val, #won = #won + :won_val, #lost = #lost + :lost_val',
        expression_attribute_names: {
          '#played' => 'played',
          '#won' => 'won',
          '#lost' => 'lost'
        },
        expression_attribute_values: {
          ':played_val' => 1,
          ':won_val' => player1_won ? 0 : 1,
          ':lost_val' => player1_won ? 1 : 0
        }
      })
    end
  end

  def create_tournament(tournament_name)
    tournament_id = SecureRandom.uuid

    @dynamodb.put_item(
      table_name: @table_name,
      item: {
        'PK' => 'TOURNAMENT#' + tournament_id,
        'SK' => 'TOURNAMENT#' + tournament_id,
        'name' => tournament_name
      }
    )

    tournament_id
  end 

  def create_match(tournament_id, player1_id, player2_id)
    match_id = SecureRandom.uuid

    items = [
      {
        put_request: {
          item: {
            'PK' => 'MATCH#' + match_id,
            'SK' => 'MATCH#' + match_id,
            'GSI1PK' => 'TOURNAMENT#' + tournament_id,
            'GSI1SK' => 'MATCH#' + match_id,
            'played' => 0,
            'over' => false
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'MATCH#' + match_id,
            'SK' => 'PLAYER#' + player1_id,
            'game1' => 0,
            'game2' => 0,
            'game3' => 0,
            'score' => 0
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'MATCH#' + match_id,
            'SK' => 'PLAYER#' + player2_id,
            'game1' => 0,
            'game2' => 0,
            'game3' => 0,
            'score' => 0
          }
        }
      }
    ]
    @dynamodb.batch_write_item({
      request_items: {
        @table_name => items
      }
    })

    match_id
  end 

  def view_player_statistc(player_id, tournament_id)
    if tournament_id
      return @dynamodb.get_item({
        table_name: 'badminton_tournaments',
        key: {
          'PK' => 'TOURNAMENT#' + tournament_id,
          'SK' => 'PLAYER#' + player_id
        }
      })
    else
      return @dynamodb.get_item({
        table_name: 'badminton_tournaments',
        key: {
          'PK' => 'PLAYER#' + player_id,
          'SK' => 'PLAYER#' + player_id
        }
      })
    end
  end 
end