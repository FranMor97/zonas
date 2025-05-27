
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';

class ElementType extends Equatable {
  final String id;
  final String name;
  final Color color;
  final IconData icon;
  final bool isWall;
  final Size defaultSize;
  final String? shape;
  final bool isSelectionTool;

  //este campo se utilizará en un futuro para añadir configuraciones a los diferentes elementos de los que dispondremos
  final Map<String, dynamic>? properties;

  const ElementType({
    required this.id,
    required this.name,
    required this.color,
    required this.icon,
    this.isWall = false,
    required this.defaultSize,
    this.shape,
    this.isSelectionTool = false,
    this.properties,
  });

  ElementType copyWith({
    String? id,
    String? name,
    Color? color,
    IconData? icon,
    bool? isWall,
    Size? defaultSize,
    String? shape,
    Map<String, dynamic>? properties,
  }) {
    return ElementType(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isWall: isWall ?? this.isWall,
      defaultSize: defaultSize ?? this.defaultSize,
      shape: shape ?? this.shape,
      properties: properties ?? this.properties,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        color,
        icon,
        isWall,
        defaultSize,
        shape,
        isSelectionTool,
        properties,
      ];
}
