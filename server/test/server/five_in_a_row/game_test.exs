defmodule Server.FiveInARow.GameTakeTurnTest do
  use ExUnit.Case, async: true

  alias Server.FiveInARow.Game, as: Game
  alias Server.FiveInARow.Cells, as: Cells

  test "X takes turn" do
    # given
    game = Game.new(10)

    # when
    game = Game.take_turn(game, {5, 6})

    # then
    assert game.next_player == :O

    cell_value = Cells.get_cell(game.cells, {5, 6})
    assert cell_value == :X
  end

  test "O takes turn" do
    # given
    game = Game.new(10)

    # when
    game =
      game
      |> Game.take_turn({3, 4})
      |> Game.take_turn({8, 4})

    # then
    assert game.next_player == :X

    cell_value = Cells.get_cell(game.cells, {8, 4})
    assert cell_value == :O
  end

  for {
        name,
        taken_cells,
        cell_to_take,
        next_player,
        expected_winner
      } <- [
        {
          "no winner - 1",
          Macro.escape(%{}),
          {1, 1},
          :X,
          nil
        },
        {
          "no winner - 2",
          Macro.escape(%{
            {5, 5} => :O,
            {4, 4} => :O,
            {3, 3} => :X,
            {2, 2} => :O
          }),
          {1, 1},
          :O,
          nil
        },
        {
          "X wins in directon N",
          Macro.escape(%{
            {1, 2} => :X,
            {1, 3} => :X,
            {1, 4} => :X,
            {1, 5} => :X
          }),
          {1, 1},
          :X,
          :X
        },
        {
          "X wins in directon S",
          Macro.escape(%{
            {1, 2} => :X,
            {1, 3} => :X,
            {1, 4} => :X,
            {1, 5} => :X
          }),
          {1, 6},
          :X,
          :X
        },
        {
          "O wins in directon NW",
          Macro.escape(%{
            {5, 5} => :O,
            {4, 4} => :O,
            {3, 3} => :O,
            {2, 2} => :O
          }),
          {1, 1},
          :O,
          :O
        },
        {
          "O wins in directon SE",
          Macro.escape(%{
            {5, 5} => :O,
            {4, 6} => :O,
            {3, 7} => :O,
            {2, 8} => :O
          }),
          {1, 9},
          :O,
          :O
        },
        {
          "X wins in directon W",
          Macro.escape(%{
            {1, 2} => :X,
            {2, 2} => :X,
            {3, 2} => :X,
            {4, 2} => :X
          }),
          {5, 2},
          :X,
          :X
        },
        {
          "X wins in directon E",
          Macro.escape(%{
            {1, 2} => :X,
            {2, 2} => :X,
            {3, 2} => :X,
            {4, 2} => :X
          }),
          {0, 2},
          :X,
          :X
        },
        {
          "X wins in directon SW",
          Macro.escape(%{
            {3, 3} => :X,
            {4, 4} => :X,
            {5, 5} => :X,
            {6, 6} => :X
          }),
          {7, 7},
          :X,
          :X
        },
        {
          "X wins in directon NE",
          Macro.escape(%{
            {3, 3} => :X,
            {4, 4} => :X,
            {5, 5} => :X,
            {6, 6} => :X
          }),
          {2, 2},
          :X,
          :X
        }
      ] do
    test "#{name}" do
      # given
      game = Game.new(10)

      game = %Game{
        game
        | next_player: unquote(next_player),
          cells: Map.merge(game.cells, unquote(taken_cells))
      }

      # when
      game = Game.take_turn(game, unquote(cell_to_take))

      # then
      assert game.winner == unquote(expected_winner)
    end
  end
end
