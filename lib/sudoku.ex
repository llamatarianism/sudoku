defmodule Sudoku do
  @moduledoc """
    Solves easy Sudoku puzzles.
  """

  import Enum

  @type board :: %{0..8 => %{0..8 => 0..9}}

  @spec list_to_map([any]) :: %{non_neg_integer => any}
  defp list_to_map(list) do
    list
    |> with_index
    |> map(fn {x, i} -> {i, x} end)
    |> Map.new
  end

  @doc ~S"""
    Converts a list of lists into a map of non-negative integers to maps of
    non-negative integers to any type. This provides much faster random access
    than a list of lists would.

    ## Example
    ```elixir
    board_to_matrix([["X", "O", "X"], ["O", "X", "X"], ["X", "X", "O"]])

    %{0 => %{0 => "X", 1 => "O", 2 => "X"},
      1 => %{0 => "O", 1 => "X", 2 => "X"},
      2 => %{0 => "X", 1 => "X", 2 => "O"}}
    ```
  """
  @spec board_to_matrix([[...]]) :: %{non_neg_integer => %{non_neg_integer => any}}
  def board_to_matrix(board) do
    board
    |> map(&list_to_map/1)
    |> list_to_map
  end

  @spec row(board, 0..8) :: [0..9]
  defp row(board, y) do
    Map.values board[y]
  end

  @spec col(board, 0..8) :: [0..9]
  defp col(board, x) do
    for y <- 0..8, do: board[y][x]
  end

  @spec grid(board, 0..8, 0..8) :: [0..9]
  defp grid(board, y, x) do
    y_limit = div(y, 3) * 3
    x_limit = div(x, 3) * 3

    for new_y <- y_limit..(y_limit + 2),
        new_x <- x_limit..(x_limit + 2) do
      board[new_y][new_x]
    end
  end

  @spec peers(board, 0..8, 0..8) :: %MapSet{}
  defp peers(board, y, x) do
    [row(board, y), ol(board, x), grid(board, y, x)]
    |> concat
    |> MapSet.new
    |> MapSet.delete(board[y][x])
  end

  @spec possible_values(board, 0..8, 0..8) :: [1..9]
  defp possible_values(board, y, x) do
    peer_set = peers(board, y, x)
    reject 1..9, fn n -> n in peer_set end
  end
  
  @spec do_solve(board, 0..9, 0..9) :: {:ok, board} | :error
  # 9 is out of the bounds of the board. Move on to the next row.
  defp do_solve(board, y, 9), do: do_solve(board, y + 1, 0)
  # Base case; the entire board is filled in.
  defp do_solve(board, 9, _x), do: {:ok, board}
  defp do_solve(board, y, x) do
    if board[y][x] != 0 do
      do_solve board, y, x + 1
    else
      # Lazy evaluation is used here for performance. The moment a successful
      # move is found, it stops calculating other moves and whether or not they fail.
      solutions =
        board
        |> possible_values(y, x)
        |> Stream.map(fn val ->
          do_solve %{board | y => %{board[y] | x => val}}, y, x + 1
        end)
        |> Stream.drop_while(& &1 == :error)
        |> Stream.take(1)
        |> Enum.to_list

      case solutions do
        # There's an incorrect move somewhere. Start backtracking.
        [] ->
          :error
        [solution] ->
          solution
      end
    end
  end

  @doc """
    Finds the solution of a partially filled in Sudoku board.
    Returns `{:ok, board}`, or `:error` if there is a contradiction and the game
    can not be solved without changing squares that are already filled in.
  """
  @spec solve(board) :: {:ok, board} | :error
  def solve(board) do
    do_solve board, 0, 0
  end

  @doc """
    Takes in a string containing 81 numbers and returns a board where each square
    corresponds to a number in the string.
  """
  @spec parse_board(String.t) :: board
  def parse_board(string) do
    string
    |> String.codepoints
    |> map(&String.to_integer/1)
    |> chunk(9)
    |> board_to_matrix
  end

  @doc """
    Takes in a `board` and converts it into a string that more closely resembles
    a Sudoku board, making it easier to read.
  """
  @spec display_board(board) :: String.t
  def display_board(board) do
    board
    |> Map.values
    |> map(&Map.values/1)
    |> map(&join(&1, " "))
    |> join("\n")
  end
end


