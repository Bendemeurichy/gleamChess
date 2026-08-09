import gleam/dict
import gleam/list
import gleam/option.{type Option, None, Some}
import piece.{
  type Color, type Piece, type PieceType, Bishop, Black, King, Knight, Pawn,
  Piece, Queen, Rook, White,
}

pub type Square =
  #(Int, Int)

pub type Board =
  dict.Dict(Square, Option(Piece))

pub fn init_board() -> Board {
  let indices = range(0, 8)

  let empty_board =
    {
      use row <- list.flat_map(indices)
      use col <- list.map(indices)
      #(#(row, col), None)
    }
    |> dict.from_list()

  //add pieces
  empty_board
  |> deploy_row(0, White, [
    Rook,
    Knight,
    Bishop,
    Queen,
    King,
    Bishop,
    Knight,
    Rook,
  ])
  |> deploy_pawn_row(1, White)
  |> deploy_pawn_row(6, Black)
  |> deploy_row(7, Black, [
    Rook,
    Knight,
    Bishop,
    Queen,
    King,
    Bishop,
    Knight,
    Rook,
  ])
}

//helper to place a row of pawns
fn deploy_pawn_row(board: Board, row: Int, color: Color) -> Board {
  use board_acc, col <- list.fold(range(0, 8), board)
  { dict.insert(board_acc, #(row, col), Some(Piece(color, Pawn))) }
}

//helper to place row of pieces
fn deploy_row(
  board: Board,
  row: Int,
  color: Color,
  pieces: List(PieceType),
) -> Board {
  let columns_with_pieces = list.zip(range(0, 8), pieces)

  use board_acc, pair <- list.fold(columns_with_pieces, board)
  {
    let #(col, piece_type) = pair
    dict.insert(board_acc, #(row, col), Some(Piece(color, piece_type)))
  }
}

//helper to make python like range list
pub fn range(start: Int, stop: Int) -> List(Int) {
  case start >= stop {
    True -> []
    False -> [start, ..range(start + 1, stop)]
  }
}

pub fn get(board: Board, row: Int, col: Int) -> Result(Option(Piece), Nil) {
  case dict.get(board, #(row, col)) {
    Ok(piece) -> Ok(piece)
    Error(_) -> Error(Nil)
  }
}

pub fn set(
  board: Board,
  row: Int,
  col: Int,
  piece: Option(Piece),
) -> Result(Board, Nil) {
  Ok(dict.insert(board, #(row, col), piece))
}

pub fn execute_move(
  board: Board,
  from_row: Int,
  from_col: Int,
  to_row: Int,
  to_col: Int,
) -> Board {
  case get(board, from_row, from_col) {
    Ok(Some(p)) -> {
      let assert Ok(board) = set(board, from_row, from_col, None)
      let assert Ok(board) = set(board, to_row, to_col, Some(p))
      board
    }

    _ -> board
  }
}
