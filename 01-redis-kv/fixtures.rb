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