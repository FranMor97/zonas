import 'package:equatable/equatable.dart';
import 'package:table_game/models/board_components/element_type.dart';


//tile se refiere a cada celda del tablero esta es la parte mas importante de este ya que es el que nos definirá la parte visual de este
class Tile extends Equatable{
  final int x;
  final int y;
  final ElementType? type;
  final String? elementId;
  final Map<String, dynamic>? properties;

  const Tile({
    required this.x,
    required this.y,
    this.type,
    this.properties,
    this.elementId,
  });

  Tile copyWith({
    int? x,
    int? y,
    ElementType? type,
    String? elementId,
    Map<String, dynamic>? properties,}){
    return Tile(
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
      elementId: elementId ?? this.elementId,
      properties: properties ?? this.properties,
    );
  }

  Tile empty(){
    return Tile(
      x: x,
      y: y,);
  }

  bool get isEmpty => type == null;

  bool get isNotEmpty => !isEmpty;

  bool get isWall => type?.isWall ?? false;

  bool get isElement => !isWall && type != null;

  @override
  List<Object?> get props => [x, y, type, properties];
}