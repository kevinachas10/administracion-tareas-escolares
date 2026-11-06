
import 'package:flutter/material.dart';

import '../models/tarea_model.dart';
import '../services/firebase_service.dart' as app_firebase;

class FormularioTareaScreen extends StatefulWidget {
  const FormularioTareaScreen({super.key});

  @override
  State<FormularioTareaScreen> createState() =>
      _FormularioTareaScreenState();
}

class _FormularioTareaScreenState
    extends State<FormularioTareaScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _materiaController = TextEditingController();
  final _descripcionController = TextEditingController();

  final _firebaseService = app_firebase.FirebaseService();

  DateTime? _fechaEntrega;
  String _prioridad = 'Media';
  bool _guardando = false;

  @override
  void dispose() {
    _tituloController.dispose();
    _materiaController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFecha() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega ?? ahora,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'MX'),
    );

    if (fecha != null && mounted) {
      setState(() {
        _fechaEntrega = fecha;
      });
    }
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Future<void> _guardarTarea() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_fechaEntrega == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una fecha de entrega'),
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    try {
      final tarea = TareaModel(
        id: '',
        titulo: _tituloController.text.trim(),
        materia: _materiaController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        fechaEntrega: _fechaEntrega!,
        prioridad: _prioridad,
        completada: false,
        fechaCreacion: DateTime.now(),
      );

      await _firebaseService.agregarTarea(tarea);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tarea guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la tarea: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _guardando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva tarea'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Registrar tarea escolar',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Completa los datos de tu tarea.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 25),

              // Título
              TextFormField(
                controller: _tituloController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Título de la tarea',
                  hintText: 'Ej. Investigación de seguridad',
                  prefixIcon: Icon(Icons.assignment),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa el título de la tarea';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Materia
              TextFormField(
                controller: _materiaController,
                maxLength: 80,
                decoration: const InputDecoration(
                  labelText: 'Materia',
                  hintText: 'Ej. Desarrollo de software',
                  prefixIcon: Icon(Icons.menu_book),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa el nombre de la materia';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Descripción
              TextFormField(
                controller: _descripcionController,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Describe lo que debes realizar...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 15),

              // Fecha de entrega
              InkWell(
                onTap: _guardando ? null : _seleccionarFecha,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de entrega',
                    prefixIcon: Icon(Icons.calendar_month),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _fechaEntrega == null
                        ? 'Seleccionar fecha'
                        : _formatearFecha(_fechaEntrega!),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Prioridad
             DropdownButtonFormField<String>(
  initialValue: _prioridad,
                decoration: const InputDecoration(
                  labelText: 'Prioridad',
                  prefixIcon: Icon(Icons.flag),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Baja',
                    child: Text('Baja'),
                  ),
                  DropdownMenuItem(
                    value: 'Media',
                    child: Text('Media'),
                  ),
                  DropdownMenuItem(
                    value: 'Alta',
                    child: Text('Alta'),
                  ),
                ],
                onChanged: _guardando
                    ? null
                    : (valor) {
                        if (valor != null) {
                          setState(() {
                            _prioridad = valor;
                          });
                        }
                      },
              ),
              const SizedBox(height: 35),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _guardando ? null : _guardarTarea,
                  icon: _guardando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _guardando
                        ? 'Guardando...'
                        : 'Guardar tarea',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
