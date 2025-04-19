class Fixtures 
    attr_accessor :test_tournament, :test_match, :test_statistic_1, :test_statistic_2, :test_player_1, :test_player_2

    def initialize()
        @test_player_1 = Player.new(1,"BOB")
        @test_player_2 = Player.new(2,"ALICE")

        @test_match = Match.new(1, @test_player_1,@test_player_2)
        @test_match.game_scores = [
            [11, 5],  # Bob wins
            [7, 11],  # Alice wins
            [11, 9]   # Bob wins
        ]

        @test_statistic_1 = PlayerStatistic.new(1, 1, 0)
        @test_statistic_2 = PlayerStatistic.new(1, 0, 1)

        @test_tournament = Tournament.new(1)
        @test_tournament.matches << @test_match
    end 
end