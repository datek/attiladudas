defmodule FiveInARow.WinCondition do
  alias __MODULE__, as: Self

  @next_direction_map %{
    # N -> S
    {0, -1} => {0, 1},
    # S -> NW
    {0, 1} => {1, -1},
    # NW -> SE
    {1, -1} => {-1, 1},
    # SE -> W
    {-1, 1} => {1, 0},
    # W -> E
    {1, 0} => {-1, 0},
    # E -> SW
    {-1, 0} => {1, 1},
    # SW -> NE
    {1, 1} => {-1, -1}
  }

  defstruct cells: %{},
            last_taken_position: {0, 0},
            last_checked_position: {0, 0},
            direction: {0, -1},
            watched_value: nil,
            count: 1

  def check?(cells, last_taken_position) do
    state = %Self{
      cells: cells,
      last_taken_position: last_taken_position,
      last_checked_position: last_taken_position,
      watched_value: FiveInARow.Cells.get_cell(cells, last_taken_position)
    }

    check_next(state)
  end

  defp check_next(%Self{count: 5}), do: true

  defp check_next(%Self{direction: nil}), do: false

  defp check_next(state = %Self{direction: {i, j}, last_checked_position: {x, y}}) do
    current_position = {x + i, y + j}
    cell_value = FiveInARow.Cells.get_cell(state.cells, current_position)
    found = cell_value == state.watched_value

    next_direction =
      if found, do: state.direction, else: Map.get(@next_direction_map, state.direction)

    last_checked_position = if found, do: current_position, else: state.last_taken_position

    %Self{
      state
      | count: get_count(state.direction, state.count, found),
        direction: next_direction,
        last_checked_position: last_checked_position
    }
    |> check_next()
  end

  defp get_count(direction, count, found) do
    if found do
      count + 1
    else
      case direction do
        {0, 1} -> 1
        {-1, 1} -> 1
        {-1, 0} -> 1
        {-1, -1} -> 1
        _ -> count
      end
    end
  end
end
