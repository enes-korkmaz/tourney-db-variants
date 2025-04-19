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

  def initialize(dynamodb, table_name)
    @dynamodb = dynamodb
    @table_name = table_name

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

  def load_fixtures
    dynamo_resource = Aws::DynamoDB::Resource.new(client: @dynamodb)
    @table = dynamo_resource.create_table(
      table_name: @table_name,
      key_schema: [
        { attribute_name: 'PK', key_type: 'HASH' },
        { attribute_name: 'SK', key_type: 'RANGE' }
      ],
      attribute_definitions: [
        { attribute_name: 'PK', attribute_type: 'S' },
        { attribute_name: 'SK', attribute_type: 'S' },
        { attribute_name: 'GSI1PK', attribute_type: 'S'},
        { attribute_name: 'GSI1SK', attribute_type: 'S'}
      ],
      global_secondary_indexes: [
        {
          index_name: 'GSI1',
          key_schema: [
            { attribute_name: 'GSI1PK', key_type: 'HASH' },
            { attribute_name: 'GSI1SK', key_type: 'RANGE' }
          ],
          projection: {
            projection_type: 'ALL' # Include all attributes in the index
          },
          provisioned_throughput: {
            read_capacity_units: 10,
            write_capacity_units: 10
          }
        }
      ],
      provisioned_throughput: { read_capacity_units: 10, write_capacity_units: 10 }
    )
    dynamo_resource.client.wait_until(:table_exists, table_name: @table_name)
    items = [
      {
        put_request: {
          item: {
            'PK' => 'TOURNAMENT#' + @tournament_id,
            'SK' => 'TOURNAMENT#' + @tournament_id,
            'name' => 'Smashbronn'
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'PLAYER#' + @player1_id,
            'SK' => 'PLAYER#' + @player1_id,
            'name' => 'Bob',
            'played' => 1,
            'won' => 0,
            'lost' => 1
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'TOURNAMENT#' + @tournament_id,
            'SK' => 'PLAYER#' + @player1_id,
            'name' => 'Bob',
            'played' => 1,
            'won' => 0,
            'lost' => 1
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'PLAYER#' + @player2_id,
            'SK' => 'PLAYER#' + @player2_id,
            'name' => 'Alice',
            'played' => 1,
            'won' => 1,
            'lost' => 0
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'TOURNAMENT#' + @tournament_id,
            'SK' => 'PLAYER#' + @player2_id,
            'name' => 'Alice',
            'played' => 1,
            'won' => 1,
            'lost' => 0
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'PLAYER#' + @player3_id,
            'SK' => 'PLAYER#' + @player3_id,
            'name' => 'Mister_X',
            'played' => 0,
            'won' => 0,
            'lost' => 0
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'TOURNAMENT#' + @tournament_id,
            'SK' => 'PLAYER#' + @player3_id,
            'name' => 'Mister_X',
            'played' => 0,
            'won' => 0,
            'lost' => 0
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'PLAYER#' + @player4_id,
            'SK' => 'PLAYER#' + @player4_id,
            'name' => 'Eve',
            'played' => 0,
            'won' => 0,
            'lost' => 0
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'MATCH#' + @match1_id,
            'SK' => 'MATCH#' + @match1_id,
            'GSI1PK' => 'TOURNAMENT#' + @tournament_id,
            'GSI1SK' => 'MATCH#' + @match1_id,
            'played' => 3,
            'over' => true
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'MATCH#' + @match1_id,
            'SK' => 'PLAYER#' + @player1_id,
            'game1' => 7,
            'game2' => 11,
            'game3' => 5,
            'score' => 1
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'MATCH#' + @match1_id,
            'SK' => 'PLAYER#' + @player2_id,
            'game1' => 11,
            'game2' => 9,
            'game3' => 11,
            'score' => 2
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'MATCH#' + @match2_id,
            'SK' => 'MATCH#' + @match2_id,
            'GSI1PK' => 'TOURNAMENT#' + @tournament_id,
            'GSI1SK' => 'MATCH#' + @match2_id,
            'played' => 0,
            'over' => false
          }
        }
      },
      {
        put_request: {
          item: {
            'PK' => 'MATCH#' + @match2_id,
            'SK' => 'PLAYER#' + @player1_id,
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
            'PK' => 'MATCH#' + @match2_id,
            'SK' => 'PLAYER#' + @player2_id,
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
  end

  def clear_database
    @table.delete
    @table = nil
  end 
end
