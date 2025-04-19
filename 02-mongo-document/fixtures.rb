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
  attr_accessor :tournament

  def initialize
    @tournament = {
      "_id": 1,
      "players": [
        {
          "_id": 1,
          "name": "BOB",
          "statistic": [1, 1, 0]
        },
        {
          "_id": 2,
          "name": "ALICE",
          "statistic": [1, 0, 1]
        }
      ],
      "matches": [
        {
          "_id": 1,
          "score": [2, 1],
          "game_scores": [
            [11, 7],
            [9, 11],
            [11, 4]
          ],
          "players": [
            {
              "_id": 1,
              "name": "BOB",
              "statistic": [1, 1, 0]
            },
            {
              "_id": 2,
              "name": "ALICE",
              "statistic": [1, 0, 1]
            }
          ]
        },
        {
          "_id": 2,
          "score": [1, 0],
          "game_scores": [
            [11, 7]
          ],
          "players": [
            {
              "_id": 1,
              "name": "BOB",
              "statistic": [1, 1, 0]
            },
            {
              "_id": 2,
              "name": "ALICE",
              "statistic": [1, 0, 1]
            }
          ]
        },
        {
          "_id": 4,
          "score": [1, 0],
          "game_scores": [
            [11, 7]
          ],
          "players": [
            {
              "_id": 1,
              "name": "BOB",
              "statistic": [1, 1, 0]
            },
            {
              "_id": 2,
              "name": "ALICE",
              "statistic": [1, 0, 1]
            }
          ]
        }  
      ]
    }
  end
end  