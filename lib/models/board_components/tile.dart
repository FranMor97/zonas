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
    this.properties = const {},
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

  Tile asPartOfElement({
    required ElementType elementType,
    required String elementId,
    required int originX,
    required int originY,
    int rotation = 0,
    Map<String, dynamic>? additionalProperties,
    bool merged = false,
    String? mergedGroupId,
  }) {
    final int elementX = x - originX;
    final int elementY = y - originY;

    final bool isOrigin = (x == originX && y == originY);

    final Map<String, dynamic> newProperties = {
      'rotation': rotation,
      'isOrigin': isOrigin,
      'elementX': elementX,
      'elementY': elementY,
      'originX': originX,
      'originY': originY,
      // Añadir propiedades de fusión si es necesario
      if (merged) 'isMerged': true,
      if (mergedGroupId != null) 'mergedGroupId': mergedGroupId,
      ...additionalProperties ?? {},
    };

    return Tile(
      x: x,
      y: y,
      type: elementType,
      elementId: elementId,
      properties: newProperties,
    );
  }


  bool get isEmpty => type == null;

  bool get isNotEmpty => !isEmpty;

  bool get isWall => type?.isWall ?? false;

  bool get isElement => !isWall && type != null;

  int get rotation => getProperty<int>('rotation', 0);

  bool get isOrigin => getProperty<bool>('isOrigin', false);

  int get elementX => getProperty<int>('elementX', 0);

  int get elementY => getProperty<int>('elementY', 0);

  bool get isMerged => getProperty<bool>('isMerged', false);

  String? get mergedGroupId => getProperty<String>('mergedGroupId','');


  bool isMergedWith(Tile other) {
    if (!isMerged || other.mergedGroupId == null) return false;
    return mergedGroupId == other.mergedGroupId;
  }

  T getProperty<T>(String key, T defaultValue) {
    final value = properties?[key];
    if (value is T) {
      return value;
    }
    return defaultValue;
  }

  @override
  List<Object?> get props => [x, y, type, properties];



}