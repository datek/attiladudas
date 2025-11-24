defmodule FiveInARow.Cells do
  def new(size) when size > 0 do
    range = 0..(size - 1)

    for i <- range, j <- range, into: %{} do
      {{i, j}, nil}
    end
  end

  def set_cell(cells, position, value) when value in [:X, :O] do
    %{cells | position => value}
  end

  def get_cell(cells, position) do
    Map.get(cells, position)
  end
end
