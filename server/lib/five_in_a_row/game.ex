defmodule FiveInARow.Game do
  alias FiveInARow.Cells
  alias __MODULE__, as: Self

  defstruct cells: %{},
            next_player: :X,
            winner: nil

  def new(size) do
    %Self{
      cells: Cells.new(size)
    }
  end

  def take_turn(game = %Self{}, pos) when game.winner == nil do
    new_cells = Cells.set_cell(game.cells, pos, game.next_player)
    winner = if FiveInARow.WinCondition.check?(new_cells, pos), do: game.next_player, else: nil
    next_player = if game.next_player == :X, do: :O, else: :X
    %Self{game | cells: new_cells, winner: winner, next_player: next_player}
  end
end
