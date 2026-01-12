enum CellState { hidden, revealed, flagged }

class Cell {
  final int row;
  final int col;
  bool hasMine;
  int adjacentMines;
  CellState state;

  Cell({
    required this.row,
    required this.col,
    this.hasMine = false,
    this.adjacentMines = 0,
    this.state = CellState.hidden,
  });

  bool get isRevealed => state == CellState.revealed;
  bool get isFlagged => state == CellState.flagged;
  bool get isHidden => state == CellState.hidden;

  Cell copyWith({
    int? row,
    int? col,
    bool? hasMine,
    int? adjacentMines,
    CellState? state,
  }) {
    return Cell(
      row: row ?? this.row,
      col: col ?? this.col,
      hasMine: hasMine ?? this.hasMine,
      adjacentMines: adjacentMines ?? this.adjacentMines,
      state: state ?? this.state,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
      'hasMine': hasMine,
      'adjacentMines': adjacentMines,
      'state': state.index,
    };
  }

  factory Cell.fromJson(Map<String, dynamic> json) {
    return Cell(
      row: json['row'] as int,
      col: json['col'] as int,
      hasMine: json['hasMine'] as bool,
      adjacentMines: json['adjacentMines'] as int,
      state: CellState.values[json['state'] as int],
    );
  }
}
