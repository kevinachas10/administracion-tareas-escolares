
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/tarea_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Iniciar sesión anónima para proteger los datos
  Future<void> iniciarSesion() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // Obtener el identificador del usuario autenticado
  String get usuarioId {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      throw StateError('No hay un usuario autenticado');
    }

    return usuario.uid;
  }

  // Cada usuario tendrá su propia colección de tareas
  CollectionReference<Map<String, dynamic>> get _tareas {
    return _firestore
        .collection('usuarios')
        .doc(usuarioId)
        .collection('tareas');
  }

  // Consultar tareas en tiempo real
  Stream<List<TareaModel>> obtenerTareas() {
    return _tareas.snapshots().map((snapshot) {
      final tareas = snapshot.docs
          .map((documento) => TareaModel.fromFirestore(documento))
          .toList();

      tareas.sort(
        (a, b) => a.fechaEntrega.compareTo(b.fechaEntrega),
      );

      return tareas;
    });
  }

  // Registrar una nueva tarea
  Future<void> agregarTarea(TareaModel tarea) async {
    if (tarea.titulo.trim().isEmpty ||
        tarea.materia.trim().isEmpty) {
      throw ArgumentError(
        'El título y la materia son obligatorios',
      );
    }

    await _tareas.add(tarea.toMap());
  }

  // Actualizar una tarea existente
  Future<void> actualizarTarea(TareaModel tarea) async {
    if (tarea.id.isEmpty) {
      throw ArgumentError('La tarea no tiene identificador');
    }

    if (tarea.titulo.trim().isEmpty ||
        tarea.materia.trim().isEmpty) {
      throw ArgumentError(
        'El título y la materia son obligatorios',
      );
    }

    await _tareas.doc(tarea.id).update(tarea.toMap());
  }

  // Cambiar el estado de una tarea
  Future<void> cambiarEstado(
    String id,
    bool completada,
  ) async {
    await _tareas.doc(id).update({
      'completada': completada,
    });
  }

  // Eliminar una tarea
  Future<void> eliminarTarea(String id) async {
    await _tareas.doc(id).delete();
  }

  // Obtener una tarea específica
  Future<TareaModel?> obtenerTareaPorId(String id) async {
    final documento = await _tareas.doc(id).get();

    if (!documento.exists) {
      return null;
    }

    return TareaModel.fromFirestore(documento);
  }
}
