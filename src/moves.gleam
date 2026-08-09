import board.{type Board, type Square, get}
import gleam/list
import gleam/option.{type Option, None, Some}
import piece.{
  type Color, type Piece, type PieceType, Bishop, Black, King, Knight, Pawn,
  Piece, Queen, Rook, White,
}

pub type Move {
  Move(from: Square, to: Square)
}

fn to_moves(from: Square, targets: List(Square)) -> List(Move) {
  list.map(targets, fn(to) { Move(from, to) })
}

//Piece directions and moves
const rook_directions = [#(1, 0), #(-1, 0), #(0, 1), #(0, -1)]

const bishop_directions = [#(1, 1), #(1, -1), #(-1, 1), #(-1, -1)]

const knight_offsets = [
  #(2, 1),
  #(2, -1),
  #(-2, 1),
  #(-2, -1),
  #(1, 2),
  #(1, -2),
  #(-1, 2),
  #(-1, -2),
]

const king_directions = [
  #(1, 0),
  #(1, 1),
  #(0, 1),
  #(-1, 1),
  #(-1, 0),
  #(-1, -1),
  #(0, -1),
  #(1, -1),
]

//Generic walk untill illegal move encountered
pub fn walk(
  board: Board,
  from: Square,
  color: Color,
  direction: #(Int, Int),
  acc: List(Square),
) -> List(Square) {
  let #(dr, dc) = direction
  let #(r, c) = from
  let next = #(r + dr, c + dc)
  case legal_step(board, next, color) {
    [] -> acc
    [square, .._] ->
      case is_empty(board, square) {
        True -> walk(board, square, color, direction, [square, ..acc])
        False -> [square, ..acc]
        // capture
      }
  }
}

fn piece_at(board: Board, square: Square) -> Option(Piece) {
  let #(row, col) = square
  case in_bounds(square), get(board, row, col) {
    True, Ok(piece) -> piece
    True, Error(_) -> None
    False, _ -> None
  }
}

fn is_empty(board: Board, square: Square) -> Bool {
  piece_at(board, square) == None
}

fn is_enemy(board: Board, square: Square, color: Color) -> Bool {
  case piece_at(board, square) {
    Some(piece) -> piece.color != color
    None -> False
  }
}

//A single non-sliding step, legal if target is empty or holds an enemy
fn legal_step(board: Board, target: Square, color: Color) -> List(Square) {
  case in_bounds(target), piece_at(board, target) {
    False, _ -> []
    True, None -> [target]
    True, Some(piece) -> {
      case piece.color == color {
        True -> []
        False -> [target]
      }
    }
  }
}

pub fn in_bounds(pos: #(Int, Int)) -> Bool {
  let #(pos_row, pos_col) = pos
  pos_row >= 0 && pos_row < 8 && pos_col >= 0 && pos_col < 8
}

fn rook_moves(board: Board, from: Square, color: Color) -> List(Move) {
  list.flat_map(rook_directions, fn(dir) { walk(board, from, color, dir, []) })
  |> to_moves(from, _)
}

fn bishop_moves(board: Board, from: Square, color: Color) -> List(Move) {
  list.flat_map(bishop_directions, fn(dir) { walk(board, from, color, dir, []) })
  |> to_moves(from, _)
}

fn queen_moves(board: Board, from: Square, color: Color) -> List(Move) {
  list.append(rook_moves(board, from, color), bishop_moves(board, from, color))
}

fn knight_moves(board: Board, from: Square, color: Color) -> List(Move) {
  let #(row, col) = from
  list.flat_map(knight_offsets, fn(direction) {
    let #(dr, dc) = direction
    legal_step(board, #(row + dr, col + dc), color)
  })
  |> to_moves(from, _)
}

fn king_moves(board: Board, from: Square, color: Color) -> List(Move) {
  let #(row, col) = from
  list.flat_map(king_directions, fn(direction) {
    let #(dr, dc) = direction
    legal_step(board, #(row + dr, col + dc), color)
  })
  |> to_moves(from, _)
}

fn pawn_moves(board: Board, from: Square, color: Color) -> List(Move) {
  let #(row, col) = from
  let forward = case color {
    White -> 1
    Black -> -1
  }
  let start_row = case color {
    White -> 1
    Black -> 6
  }
  let one_step = #(row + forward, col)
  let two_step = #(row + 2 * forward, col)

  let pushes = case is_empty(board, one_step) {
    False -> []
    True ->
      case row == start_row, is_empty(board, two_step) {
        True, True -> [two_step, one_step]
        True, False -> [one_step]
        False, _ -> [one_step]
      }
  }

  let captures =
    list.filter_map(
      [#(row + forward, col - 1), #(row + forward, col + 1)],
      fn(target) {
        case is_enemy(board, target, color) {
          True -> Ok(target)
          False -> Error(Nil)
        }
      },
    )

  list.append(pushes, captures)
  |> to_moves(from, _)
}

pub fn possible_moves(board: Board, square: Square) -> List(Move) {
  let #(row, col) = square
  case get(board, row, col) {
    Ok(Some(Piece(color, piece_type))) -> {
      case piece_type {
        Rook -> rook_moves(board, square, color)
        Bishop -> bishop_moves(board, square, color)
        Queen -> queen_moves(board, square, color)
        Knight -> knight_moves(board, square, color)
        King -> king_moves(board, square, color)
        Pawn -> pawn_moves(board, square, color)
      }
    }
    _ -> []
  }
}

pub fn can_move(
  board: Board,
  from_row: Int,
  from_col: Int,
  to_row: Int,
  to_col: Int,
) -> Bool {
  let from = #(from_row, from_col)
  let to = #(to_row, to_col)
  possible_moves(board, from)
  |> list.any(fn(move) { move.to == to })
}
