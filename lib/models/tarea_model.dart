
import 'package:cloud_firestore/cloud_firestore.dart';

class TareaModel {
  final String id;
  final String titulo;
  final String materia;
  final String descripcion;
  final DateTime fechaEntrega;
  final String prioridad;
  final bool completada;
  final DateTime fechaCreacion;

  TareaModel({
    required this.id,
    required this.titulo,
    required this.materia,
    required this.descripcion,
    required this.fechaEntrega,
    required this.prioridad,
    required this.completada,
    required this.fechaCreacion,
  });

  // Convertir los datos de Firebase a un objeto TareaModel
  factory TareaModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> documento,
  ) {
    final datos = documento.data()!;

    return TareaModel(
      id: documento.id,
      titulo: datos['titulo'] ?? '',
      materia: datos['materia'] ?? '',
      descripcion: datos['descripcion'] ?? '',
      fechaEntrega: (datos['fechaEntrega'] as Timestamp).toDate(),
      prioridad: datos['prioridad'] ?? 'Media',
      completada: datos['completada'] ?? false,
      fechaCreacion:
          (datos['fechaCreacion'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  // Convertir el objeto a un mapa para guardarlo en Firebase
  Map<String, dynamic> toMap() {
    return {
      'titulo': titulo,
      'materia': materia,
      'descripcion': descripcion,
      'fechaEntrega': Timestamp.fromDate(fechaEntrega),
      'prioridad': prioridad,
      'completada': completada,
      'fechaCreacion': Timestamp.fromDate(fechaCreacion),
    };
  }

  // Crear una copia de la tarea con valores modificados
  TareaModel copyWith({
    String? id,
    String? titulo,
    String? materia,
    String? descripcion,
    DateTime? fechaEntrega,
    String? prioridad,
    bool? completada,
    DateTime? fechaCreacion,
  }) {
    return TareaModel(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      materia: materia ?? this.materia,
      descripcion: descripcion ?? this.descripcion,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      prioridad: prioridad ?? this.prioridad,
      completada: completada ?? this.completada,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
    );
  }
}
