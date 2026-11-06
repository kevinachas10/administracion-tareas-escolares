
import 'package:flutter/material.dart';

import '../models/tarea_model.dart';
import '../services/firebase_service.dart' as app_firebase;
import 'formulario_tarea_screen.dart';
import 'detalle_tarea_screen.dart';

class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key});

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  final app_firebase.FirebaseService _firebaseService =
      app_firebase.FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      // Barra superior
      appBar: AppBar(
        title: const Text('Mis tareas escolares'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),

      // Obtener las tareas desde Firebase
      body: StreamBuilder<List<TareaModel>>(
        stream: _firebaseService.obtenerTareas(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Error al cargar las tareas: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final tareas = snapshot.data!;

          // Calcular resumen de tareas
          final pendientes =
              tareas.where((tarea) => !tarea.completada).length;

          final completadas =
              tareas.where((tarea) => tarea.completada).length;

          return Column(
            children: [
              // Tarjeta de resumen
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen de tareas',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                      children: [
                        _resumen(
                          'Total',
                          tareas.length,
                          Colors.blue,
                        ),
                        _resumen(
                          'Pendientes',
                          pendientes,
                          Colors.orange,
                        ),
                        _resumen(
                          'Completadas',
                          completadas,
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de tareas
              Expanded(
                child: tareas.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.assignment_outlined,
                                size: 80,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Todavía no tienes tareas registradas',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Presiona + para agregar tu primera tarea',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                        itemCount: tareas.length,
                        itemBuilder: (context, index) {
                          final tarea = tareas[index];

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              // Marcar tarea como completada
                              leading: Checkbox(
                                value: tarea.completada,
                                onChanged: (valor) async {
                                  if (valor == null) return;

                                  try {
                                    await _firebaseService.cambiarEstado(
                                      tarea.id,
                                      valor,
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'No se pudo actualizar: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),

                              // Título de la tarea
                              title: Text(
                                tarea.titulo,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: tarea.completada
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),

                              // Información de la tarea
                              subtitle: Text(
                                '${tarea.materia}\n'
                                'Prioridad: ${tarea.prioridad}',
                              ),

                              isThreeLine: true,

                              trailing: const Icon(
                                Icons.chevron_right,
                              ),

                              // Abrir detalles de la tarea
                              onTap: () async {
                                final resultado =
                                    await Navigator.push<String>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetalleTareaScreen(
                                      tarea: tarea,
                                    ),
                                  ),
                                );

                                if (!context.mounted) return;

                                if (resultado == 'actualizada' ||
                                    resultado == 'eliminada') {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        resultado == 'actualizada'
                                            ? 'Tarea actualizada correctamente'
                                            : 'Tarea eliminada correctamente',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),

      // Botón para agregar nuevas tareas
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const FormularioTareaScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  // Widget para mostrar los contadores
  Widget _resumen(
    String titulo,
    int cantidad,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          '$cantidad',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
