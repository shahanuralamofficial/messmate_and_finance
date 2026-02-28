import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';
import '../providers/finance_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class AddEditNoteScreen extends StatefulWidget {
  final Note? note;

  const AddEditNoteScreen({super.key, this.note});

  @override
  State<AddEditNoteScreen> createState() => _AddEditNoteScreenState();
}

class _AddEditNoteScreenState extends State<AddEditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    if (!_formKey.currentState!.validate()) return;

    final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user!.uid;

    if (widget.note == null) {
      final newNote = Note(
        id: const Uuid().v4(),
        userId: userId,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      financeProvider.addNote(newNote);
    } else {
      final updatedNote = widget.note!.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        updatedAt: DateTime.now(),
      );
      financeProvider.updateNote(updatedNote);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isBangla = Provider.of<SettingsProvider>(context).locale.languageCode == 'bn';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null 
          ? (isBangla ? 'নতুন নোট' : 'New Note') 
          : (isBangla ? 'নোট সম্পাদনা' : 'Edit Note')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: isBangla ? 'শিরোনাম' : 'Title',
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? (isBangla ? 'শিরোনাম দিন' : 'Enter a title') : null,
              ),
              const SizedBox(height: 20), // Added gap here
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    labelText: isBangla ? 'বিস্তারিত' : 'Content',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: null,
                  expands: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
