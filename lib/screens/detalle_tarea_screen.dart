
import 'package:flutter/material.dart';

import '../models/tarea_model.dart';
import '../services/firebase_service.dart' as app_firebase;

class DetalleTareaScreen extends StatefulWidget {
  final TareaModel tarea;

  const DetalleTareaScreen({
    super.key,
    required this.tarea,
  });

  @override
  State<DetalleTareaScreen> createState() => _DetalleTareaScreenState();
}

class _DetalleTareaScreenState extends State<DetalleTareaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _servicio = app_firebase.FirebaseService();

  late final TextEditingController _tituloController;
  late final TextEditingController _materiaController;
  late final TextEditingController _descripcionController;

  late DateTime _fechaEntrega;
  late String _prioridad;
  late bool _completada;

  bool _editando = false;
  bool _procesando = false;

  @override
  void initState() {
    super.initState();

    _tituloController =
        TextEditingController(text: widget.tarea.titulo);
    _materiaController =
        TextEditingController(text: widget.tarea.materia);
    _descripcionController =
        TextEditingController(text: widget.tarea.descripcion);

    _fechaEntrega = widget.tarea.fechaEntrega;
    _prioridad = widget.tarea.prioridad;
    _completada = widget.tarea.completada;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _materiaController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaEntrega,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (fecha != null && mounted) {
      setState(() => _fechaEntrega = fecha);
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _procesando = true);

    try {
      final tareaActualizada = widget.tarea.copyWith(
        titulo: _tituloController.text.trim(),
        materia: _materiaController.text.trim(),
        descripcion: _descripcionController.text.trim(),
        fechaEntrega: _fechaEntrega,
        prioridad: _prioridad,
        completada: _completada,
      );

      await _servicio.actualizarTarea(tareaActualizada);

      if (!mounted) return;

      Navigator.pop(context, 'actualizada');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _procesando = false);
      }
    }
  }

  Future<void> _eliminarTarea() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta tarea? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _procesando = true);

    try {
      await _servicio.eliminarTarea(widget.tarea.id);

      if (!mounted) return;

      Navigator.pop(context, 'eliminada');
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );

      setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editando ? 'Editar tarea' : 'Detalle de tarea',
        ),
        actions: [
          if (!_editando)
            IconButton(
              tooltip: 'Editar tarea',
              onPressed: _procesando
                  ? null
                  : () => setState(() => _editando = true),
              icon: const Icon(Icons.edit),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _tituloController,
                readOnly: !_editando,
                maxLength: _editando ? 100 : null,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.assignment),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa un título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _materiaController,
                readOnly: !_editando,
                maxLength: _editando ? 80 : null,
                decoration: const InputDecoration(
                  labelText: 'Materia',
                  prefixIcon: Icon(Icons.menu_book),
                ),
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Ingresa una materia';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descripcionController,
                readOnly: !_editando,
                maxLines: 4,
                maxLength: _editando ? 500 : null,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month),
                title: const Text('Fecha de entrega'),
                subtitle: Text(_formatearFecha(_fechaEntrega)),
                trailing: _editando
                    ? const Icon(Icons.edit_calendar)
                    : null,
                onTap: _editando ? _seleccionarFecha : null,
              ),
              const SizedBox(height: 16),

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
                onChanged: _editando
                    ? (valor) {
                        if (valor != null) {
                          setState(() => _prioridad = valor);
                        }
                      }
                    : null,
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Tarea completada'),
                value: _completada,
                onChanged: _editando
                    ? (valor) {
                        setState(() => _completada = valor);
                      }
                    : null,
              ),
              const SizedBox(height: 30),

              if (_editando) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _procesando ? null : _guardarCambios,
                    icon: const Icon(Icons.save),
                    label: Text(
                      _procesando
                          ? 'Guardando...'
                          : 'Guardar cambios',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _procesando
                        ? null
                        : () {
                            _tituloController.text =
                                widget.tarea.titulo;
                            _materiaController.text =
                                widget.tarea.materia;
                            _descripcionController.text =
                                widget.tarea.descripcion;

                            setState(() {
                              _fechaEntrega =
                                  widget.tarea.fechaEntrega;
                              _prioridad = widget.tarea.prioridad;
                              _completada = widget.tarea.completada;
                              _editando = false;
                            });
                          },
                    child: const Text('Cancelar edición'),
                  ),
                ),
              ] else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _procesando ? null : _eliminarTarea,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Eliminar tarea'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
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
