import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/note_model.dart';
import '../services/note_service.dart';

class NoteEditorScreen extends StatefulWidget {
  final Note? note;
  final NoteService noteService;

  const NoteEditorScreen({Key? key, this.note, required this.noteService}) : super(key: key);

  @override
  _NoteEditorScreenState createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late NoteService _noteService;
  
  int _backgroundColor = 0xFFFFFFFF;
  int _textColor = 0xFF000000;
  bool _isPinned = false;
  bool _isFavorite = false;
  List<String> _tags = [];
  String? _folderId;
  String? _imagePath;
  List<String> _attachments = [];
  DateTime? _reminderDate;
  bool _isLocked = false;
  String _currentTag = '';
  
  bool _hasChanges = false;
  Timer? _autoSaveTimer;
  String? _savedContent;
  String? _savedTitle;
  
  // IMPORTANT: Garder l'ID de la note en cours d'édition
  String? _currentNoteId;
  bool _isNewNote = true;

  final List<int> _backgroundColors = [
    0xFFFFFFFF, 0xFFFFF3E0, 0xFFE8F5E9, 0xFFE3F2FD, 0xFFFCE4EC,
    0xFFF3E5F5, 0xFFFFEBEE, 0xFFFFF9C4, 0xFFE0F7FA, 0xFFF1F8E9,
  ];

  @override
  void initState() {
    super.initState();
    _noteService = widget.noteService;
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    
    _savedTitle = widget.note?.title ?? '';
    _savedContent = widget.note?.content ?? '';
    
    _backgroundColor = widget.note?.backgroundColor ?? 0xFFFFFFFF;
    _textColor = widget.note?.textColor ?? 0xFF000000;
    _isPinned = widget.note?.isPinned ?? false;
    _isFavorite = widget.note?.isFavorite ?? false;
    _tags = widget.note?.tags ?? [];
    _folderId = widget.note?.folderId;
    _imagePath = widget.note?.imagePath;
    _attachments = widget.note?.attachments ?? [];
    _reminderDate = widget.note?.reminderDate != null 
        ? DateTime.parse(widget.note!.reminderDate!) 
        : null;
    _isLocked = widget.note?.isLocked ?? false;
    
    // Important: Stocker l'ID si la note existe déjà
    if (widget.note?.id != null) {
      _currentNoteId = widget.note!.id;
      _isNewNote = false;
    }
    
    _startAutoSaveTimer();
    
    _titleController.addListener(_onContentChanged);
    _contentController.addListener(_onContentChanged);
  }
  
  void _onContentChanged() {
    final currentTitle = _titleController.text;
    final currentContent = _contentController.text;
    
    if (currentTitle != _savedTitle || currentContent != _savedContent) {
      if (!_hasChanges) {
        setState(() => _hasChanges = true);
      }
    } else {
      if (_hasChanges) {
        setState(() => _hasChanges = false);
      }
    }
  }
  
  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (_hasChanges && mounted) {
        _autoSave();
      }
    });
  }
  
  Future<void> _autoSave() async {
    final currentTitle = _titleController.text;
    final currentContent = _contentController.text;
    
    // Si rien n'a changé, ne rien faire
    if (currentTitle == _savedTitle && currentContent == _savedContent) {
      setState(() => _hasChanges = false);
      return;
    }
    
    // Si la note est vide, ne pas sauvegarder
    if (currentTitle.isEmpty && currentContent.isEmpty) {
      return;
    }
    
    await _performSave(isAutoSave: true);
    
    _savedTitle = currentTitle;
    _savedContent = currentContent;
    
    setState(() => _hasChanges = false);
    
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      Vibration.vibrate(duration: 20);
    }
  }

  Future<void> _performSave({bool isAutoSave = false}) async {
    final now = DateTime.now();
    final title = _titleController.text.isEmpty ? 'Sans titre' : _titleController.text;
    final content = _contentController.text;
    
    // Si c'est une nouvelle note et qu'elle est vide, ne pas sauvegarder
    if (_isNewNote && title == 'Sans titre' && content.isEmpty) {
      return;
    }
    
    String noteId;
    bool isExistingNote = false;
    
    // Déterminer si on doit créer ou mettre à jour
    if (_currentNoteId != null) {
      // Note existante, on met à jour
      noteId = _currentNoteId!;
      isExistingNote = true;
    } else {
      // Nouvelle note, on crée un ID
      noteId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentNoteId = noteId;
      _isNewNote = false;
    }
    
    final note = Note(
      id: noteId,
      title: title,
      content: content,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      backgroundColor: _backgroundColor,
      textColor: _textColor,
      isPinned: _isPinned,
      isArchived: widget.note?.isArchived ?? false,
      isFavorite: _isFavorite,
      tags: _tags,
      folderId: _folderId,
      imagePath: _imagePath,
      attachments: _attachments,
      reminderDate: _reminderDate?.toIso8601String(),
      isLocked: _isLocked,
      fontFamily: null,
      fontSize: 16.0,
    );

    if (isExistingNote) {
      await _noteService.updateNote(note);
    } else {
      await _noteService.addNote(note);
    }

    if (!isAutoSave && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _saveNote({bool isAutoSave = false}) async {
    await _performSave(isAutoSave: isAutoSave);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
      _onContentChanged();
    }
  }

  Future<void> _addTag() async {
    if (_currentTag.trim().isEmpty) return;
    setState(() {
      _tags.add(_currentTag.trim());
      _currentTag = '';
    });
    _onContentChanged();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
    _onContentChanged();
  }

  Future<void> _selectReminderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderDate ?? DateTime.now()),
      );
      if (time != null && mounted) {
        setState(() {
          _reminderDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
        _onContentChanged();
      }
    }
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              SizedBox(height: 20),
              Text('Personnaliser', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Text('Couleur de fond', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _backgroundColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _backgroundColor = color);
                      Navigator.pop(context);
                      _onContentChanged();
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Color(color),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _backgroundColor == color ? Color(0xFF6366F1) : Colors.grey.shade300, width: _backgroundColor == color ? 3 : 1),
                      ),
                      child: _backgroundColor == color ? Icon(Icons.check, size: 20) : null,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
              Text('Couleur du texte', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  Colors.black, Colors.red, Colors.blue, Colors.green,
                  Colors.purple, Colors.orange, Colors.pink, Colors.teal, Colors.white,
                ].map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() => _textColor = color.value);
                      Navigator.pop(context);
                      _onContentChanged();
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _textColor == color.value ? Color(0xFF6366F1) : Colors.grey.shade300, width: _textColor == color.value ? 3 : 1),
                      ),
                      child: _textColor == color.value ? Icon(Icons.check, size: 20, color: color == Colors.white ? Colors.black : Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _imagePath != null ? null : Color(_backgroundColor),
      body: Container(
        decoration: _imagePath != null ? BoxDecoration(image: DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover)) : null,
        child: Column(
          children: [
            // AppBar
            Container(
              padding: EdgeInsets.only(top: 40, left: 16, right: 16),
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.arrow_back), onPressed: () => _saveNote(isAutoSave: false)),
                  Expanded(child: TextField(
                    controller: _titleController,
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Color(_textColor)),
                    decoration: InputDecoration(hintText: 'Titre...', border: InputBorder.none),
                  )),
                  IconButton(icon: Icon(Icons.favorite, color: _isFavorite ? Colors.red : Colors.grey),
                    onPressed: () { setState(() => _isFavorite = !_isFavorite); _onContentChanged(); }),
                  IconButton(icon: Icon(Icons.push_pin, color: _isPinned ? Colors.blue : Colors.grey),
                    onPressed: () { setState(() => _isPinned = !_isPinned); _onContentChanged(); }),
                ],
              ),
            ),
            // Tags
            if (_tags.isNotEmpty)
              Container(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _tags.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8),
                  itemBuilder: (context, index) => Chip(
                    label: Text('#${_tags[index]}', style: TextStyle(fontSize: 12)),
                    onDeleted: () => _removeTag(_tags[index]),
                    deleteIcon: Icon(Icons.close, size: 14),
                    backgroundColor: Colors.blue.withOpacity(0.1),
                  ),
                ),
              ),
            // Ajout tag
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => _currentTag = value,
                      onSubmitted: (_) => _addTag(),
                      decoration: InputDecoration(
                        hintText: 'Ajouter un tag...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  IconButton(icon: Icon(Icons.add), onPressed: _addTag),
                ],
              ),
            ),
            // Barre d'outils
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(icon: Icon(Icons.color_lens), onPressed: _showColorPicker),
                  IconButton(icon: Icon(Icons.image), onPressed: () => _pickImage(ImageSource.gallery)),
                  IconButton(icon: Icon(Icons.camera_alt), onPressed: () => _pickImage(ImageSource.camera)),
                  IconButton(icon: Icon(Icons.notifications), onPressed: _selectReminderDate, color: _reminderDate != null ? Colors.orange : null),
                  Spacer(),
                  if (_hasChanges)
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ),
            // Éditeur
            Expanded(child: TextField(
              controller: _contentController,
              maxLines: null,
              expands: true,
              style: GoogleFonts.inter(fontSize: 16, color: Color(_textColor)),
              decoration: InputDecoration(
                hintText: 'Écrivez votre note ici...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
            )),
            // Footer
            Container(
              padding: EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.access_time, size: 12, color: Color(_textColor).withOpacity(0.5)),
                  SizedBox(width: 4),
                  Text(DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()), style: TextStyle(fontSize: 10, color: Color(_textColor).withOpacity(0.5))),
                  if (_reminderDate != null) ...[
                    SizedBox(width: 12),
                    Icon(Icons.notifications, size: 12, color: Colors.orange),
                    SizedBox(width: 4),
                    Text(DateFormat('dd/MM/yyyy HH:mm').format(_reminderDate!), style: TextStyle(fontSize: 10, color: Colors.orange)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}