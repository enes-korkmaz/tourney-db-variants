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