import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StudyPlanPage extends StatefulWidget {
  const StudyPlanPage({super.key});

  @override
  _StudyPlanPageState createState() => _StudyPlanPageState();
}

class _StudyPlanPageState extends State<StudyPlanPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> tasks = [];

  final List<String> _priorities = ['Basse', 'Moyenne', 'Haute'];
  final List<String> _subjects = [
    'Mathématiques',
    'Physique',
    'Chimie',
    'Français',
    'Anglais',
    'Histoire-Géographie'
  ];

  final TextEditingController _newTaskController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedPriority = 'Moyenne';
  String _selectedSubject = 'Mathématiques';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final user = _auth.currentUser;
    if (user == null) return;

    _firestore
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .orderBy('dueDate')
        .snapshots()
        .listen((querySnapshot) {
      setState(() {
        tasks = querySnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'task': data['task'] ?? '',
            'status': data['status'] ?? 'À faire',
            'dueDate': (data['dueDate'] as Timestamp).toDate(),
            'priority': data['priority'] ?? 'Moyenne',
            'subject': data['subject'] ?? 'Mathématiques',
            'completed': data['completed'] ?? false,
          };
        }).toList();
      });
    });
  }

  Future<void> _addNewTask() async {
    final user = _auth.currentUser;
    if (user == null || _newTaskController.text.isEmpty) return;

    try {
      await _firestore.collection('users').doc(user.uid).collection('tasks').add({
        'task': _newTaskController.text,
        'status': 'À faire',
        'dueDate': _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
        'priority': _selectedPriority,
        'subject': _selectedSubject,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _newTaskController.clear();
      _selectedDate = null;
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _updateTask(String taskId, Map<String, dynamic> updates) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(taskId)
          .update(updates);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _editTaskDialog(int index) {
    final task = tasks[index];
    _newTaskController.text = task['task'];
    _selectedPriority = task['priority'];
    _selectedSubject = task['subject'];
    _selectedDate = task['dueDate'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Modifier la tâche'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _newTaskController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedSubject,
                      items: _subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject,
                          child: Text(subject),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedSubject = value!),
                      decoration: const InputDecoration(labelText: 'Matière'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      items: _priorities.map((priority) {
                        return DropdownMenuItem(
                          value: priority,
                          child: Text(priority),
                        );
                      }).toList(),
                      onChanged: (value) => setState(() => _selectedPriority = value!),
                      decoration: const InputDecoration(labelText: 'Priorité'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedDate == null
                                ? 'Pas de date définie'
                                : 'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    _updateTask(task['id'], {
                      'task': _newTaskController.text,
                      'priority': _selectedPriority,
                      'subject': _selectedSubject,
                      'dueDate': _selectedDate,
                    });
                    _newTaskController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Sauvegarder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTaskCard(int index) {
    final task = tasks[index];
    final dueDate = task['dueDate'] as DateTime;
    final isOverdue = !task['completed'] && dueDate.isBefore(DateTime.now());

    return Card(
      color: task['completed'] ? Colors.green[50] : null,
      child: ListTile(
        leading: _buildSubjectIcon(task['subject']),
        title: Text(task['task']),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Matière: ${task['subject']}'),
            Text('Priorité: ${task['priority']}'),
            Text(
              'Date: ${DateFormat('dd/MM/yyyy').format(dueDate)}',
              style: TextStyle(
                color: isOverdue ? Colors.red : null,
                fontWeight: isOverdue ? FontWeight.bold : null,
              ),
            ),
            Text('Statut: ${task['status']}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (choice) {
            if (choice == 'edit') {
              _editTaskDialog(index);
            } else if (choice == 'status') {
              final newStatus = task['status'] == 'Terminé' ? 'À faire' : 
                              task['status'] == 'En cours' ? 'Terminé' : 'En cours';
              _updateTask(task['id'], {
                'status': newStatus,
                'completed': newStatus == 'Terminé',
              });
            } else if (choice == 'delete') {
              _deleteTask(task['id']);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Éditer')),
            const PopupMenuItem(value: 'status', child: Text('Changer statut')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectIcon(String subject) {
    IconData icon;
    switch (subject) {
      case 'Mathématiques':
        icon = Icons.calculate;
        break;
      case 'Physique':
        icon = Icons.science;
        break;
      case 'Chimie':
        icon = Icons.emoji_objects;
        break;
      case 'Français':
        icon = Icons.menu_book;
        break;
      case 'Anglais':
        icon = Icons.language;
        break;
      case 'Histoire-Géographie':
        icon = Icons.public;
        break;
      default:
        icon = Icons.subject;
    }
    return Icon(icon, color: Colors.blue);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan d\'étude'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _newTaskController.clear();
              _selectedDate = null;
              _selectedPriority = 'Moyenne';
              _selectedSubject = 'Mathématiques';
              showDialog(
                context: context,
                builder: (context) => _buildAddTaskDialog(),
              );
            },
          ),
        ],
      ),
      body: tasks.isEmpty
          ? const Center(child: Text('Aucune tâche. Ajoutez-en une!'))
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: tasks.length,
              itemBuilder: (context, index) => _buildTaskCard(index),
            ),
    );
  }

  Widget _buildAddTaskDialog() {
    return AlertDialog(
      title: const Text('Nouvelle tâche'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _newTaskController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedSubject,
              items: _subjects.map((subject) {
                return DropdownMenuItem(
                  value: subject,
                  child: Text(subject),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedSubject = value!),
              decoration: const InputDecoration(labelText: 'Matière'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPriority,
              items: _priorities.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(priority),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedPriority = value!),
              decoration: const InputDecoration(labelText: 'Priorité'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Pas de date définie'
                        : 'Date: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () {
            _addNewTask();
            Navigator.pop(context);
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}