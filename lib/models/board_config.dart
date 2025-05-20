import 'package:equatable/equatable.dart';

class BoardConfig extends Equatable {
  final int columns;
  final int rows;
  final double tileSize;
  final String name;

  const BoardConfig({
    this.columns = 10,
    this.rows = 10,
    this.tileSize = 40.0,
    this.name = 'New Zone',
  });

  BoardConfig copyWith({
    int? columns,
    int? rows,
    double? tileSize,
    String? name,
  }) {
    return BoardConfig(
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      tileSize: tileSize ?? this.tileSize,
      name: name ?? this.name,
    );
  }

  @override
  List<Object> get props => [columns, rows, tileSize, name];

}
