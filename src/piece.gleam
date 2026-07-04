pub type Color {
  White
  Black
}

pub type PieceType {
  Pawn
  Queen
  King
  Bishop
  Knight
  Rook
}

pub type Piece {
  Piece(color: Color, piece_type: PieceType)
}

fn to_string(piece_type: PieceType) -> String {
  case piece_type {
    Pawn -> "Pawn"
    Queen -> "Queen"
    King -> "King"
    Bishop -> "Bishop"
    Knight -> "Knight"
    Rook -> "Rook"
  }
}

fn color_prefix(color: Color) -> String {
  case color {
    White -> "w_"
    Black -> "b_"
  }
}

fn piece_path(piece: Piece) -> String {
  let Piece(color, piece_type) = piece

  "assets/ChessAssets/"
  <> color_prefix(color)
  <> to_string(piece_type)
  <> ".png"
}
