import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vibration/vibration.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
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
  late quill.QuillController _quillController;
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
  String? _fontFamily;
  double _fontSize = 16.0;
  
  bool _isRecording = false;
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Sauvegarde automatique
  Timer? _autoSaveTimer;
  bool _hasChanges = false;

  final List<int> _backgroundColors = [
    0xFFFFFFFF, 0xFFFFF3E0, 0xFFE8F5E9, 0xFFE3F2FD, 0xFFFCE4EC,
    0xFFF3E5F5, 0xFFFFEBEE, 0xFFFFF9C4, 0xFFE0F7FA, 0xFFF1F8E9,
  ];

  @override
  void initState() {
    super.initState();
    _noteService = widget.noteService;
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    
    // Initialiser l'éditeur riche
    _quillController = quill.QuillController(
      document: widget.note?.content != null 
          ? quill.Document.fromJson(jsonDecode(widget.note!.content))
          : quill.Document(),
      selection: const TextSelection.collapsed(offset: 0),
    );
    
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
    _fontFamily = widget.note?.fontFamily;
    _fontSize = widget.note?.fontSize ?? 16.0;
    
    // Démarrer le timer de sauvegarde auto
    _startAutoSaveTimer();
    
    // Ajouter listener pour détecter les changements
    _titleController.addListener(() => _onContentChanged());
    _quillController.addListener(() => _onContentChanged());
  }
  
  void _onContentChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
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
    await _saveNote(isAutoSave: true);
    setState(() => _hasChanges = false);
    
    // Feedback haptique
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 20);
    }
    
    // Indicateur visuel de sauvegarde
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.save, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text('Sauvegarde automatique...'),
          ],
        ),
        duration: Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveNote({bool isAutoSave = false}) async {
    if (_titleController.text.isEmpty && _quillController.document.isEmpty()) {
      return;
    }

    final now = DateTime.now();
    final note = Note(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.isEmpty ? 'Sans titre' : _titleController.text,
      content: jsonEncode(_quillController.document.toJson()),
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
      fontFamily: _fontFamily,
      fontSize: _fontSize,
    );

    if (widget.note?.id != null) {
      await _noteService.updateNote(note);
    } else {
      await _noteService.addNote(note);
    }

    if (!isAutoSave) {
      Navigator.pop(context, true);
    }
  }

  // Popup pour choisir la source de l'image
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

  // Enregistrement vocal
  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        if (path != null) {
          _attachments.add(path);
          _onContentChanged();
        }
      });
    } else {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        final path = '${(await getTemporaryDirectory()).path}/recording_${DateTime.now()}.m4a';
        await _recorder.start(RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    }
  }

  // Ajouter fichier
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    
    if (result != null) {
      setState(() {
        _attachments.add(result.files.single.path!);
        _onContentChanged();
      });
    }
  }

  // Choisir police
  void _showFontPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Police et taille'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<String>(
              value: _fontFamily,
              hint: Text('Choisir police'),
              items: ['Poppins', 'Inter', 'Roboto', 'Lato', 'Montserrat'].map((font) {
                return DropdownMenuItem(value: font, child: Text(font));
              }).toList(),
              onChanged: (value) {
                setState(() => _fontFamily = value);
                _onContentChanged();
              },
            ),
            Slider(
              value: _fontSize,
              min: 12,
              max: 30,
              label: _fontSize.round().toString(),
              onChanged: (value) {
                setState(() => _fontSize = value);
                _onContentChanged();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Sélection date rappel
  Future<void> _selectReminderDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reminderDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderDate ?? DateTime.now()),
      );
      if (time != null) {
        setState(() {
          _reminderDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
        _onContentChanged();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _imagePath != null 
          ? null 
          : Color(_backgroundColor),
      body: Container(
        decoration: _imagePath != null
            ? BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(_imagePath!)),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: Stack(
          children: [
            Column(
              children: [
                // Barre d'outils enrichie
                Container(
                  padding: EdgeInsets.only(top: 40, left: 16, right: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        onPressed: () => _saveNote(isAutoSave: false),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(_textColor),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Titre...',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.favorite, 
                          color: _isFavorite ? Colors.red : Colors.grey),
                        onPressed: () {
                          setState(() => _isFavorite = !_isFavorite);
                          _onContentChanged();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.push_pin,
                          color: _isPinned ? Colors.blue : Colors.grey),
                        onPressed: () {
                          setState(() => _isPinned = !_isPinned);
                          _onContentChanged();
                        },
                      ),
                    ],
                  ),
                ),
                
                // Barre d'outils formatage
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Gras
                      IconButton(
                        icon: Icon(Icons.format_bold, size: 20),
                        onPressed: () {
                          final index = _quillController.selection.baseOffset;
                          _quillController.formatText(index, 0, 
                            quill.Attribute.bold, true);
                        },
                      ),
                      // Italique
                      IconButton(
                        icon: Icon(Icons.format_italic, size: 20),
                        onPressed: () {
                          _quillController.formatSelection(
                            quill.Attribute.italic, true);
                        },
                      ),
                      // Souligné
                      IconButton(
                        icon: Icon(Icons.format_underline, size: 20),
                        onPressed: () {
                          _quillController.formatSelection(
                            quill.Attribute.underline, true);
                        },
                      ),
                      // Liste à puces
                      IconButton(
                        icon: Icon(Icons.format_list_bulleted, size: 20),
                        onPressed: () {
                          _quillController.formatSelection(
                            quill.Attribute.bulletList, true);
                        },
                      ),
                      // Liste numérotée
                      IconButton(
                        icon: Icon(Icons.format_list_numbered, size: 20),
                        onPressed: () {
                          _quillController.formatSelection(
                            quill.Attribute.numberedList, true);
                        },
                      ),
                      // Checkbox
                      IconButton(
                        icon: Icon(Icons.check_box_outlined, size: 20),
                        onPressed: () {
                          _quillController.formatSelection(
                            quill.Attribute.checkboxList, true);
                        },
                      ),
                      Spacer(),
                      // Image
                      IconButton(
                        icon: Icon(Icons.image, size: 20),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                      // Camera
                      IconButton(
                        icon: Icon(Icons.camera_alt, size: 20),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                      // Audio
                      IconButton(
                        icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 20),
                        onPressed: _toggleRecording,
                        color: _isRecording ? Colors.red : null,
                      ),
                      // Fichier
                      IconButton(
                        icon: Icon(Icons.attach_file, size: 20),
                        onPressed: _pickFile,
                      ),
                      // Police
                      IconButton(
                        icon: Icon(Icons.text_fields, size: 20),
                        onPressed: _showFontPicker,
                      ),
                    ],
                  ),
                ),
                
                // Éditeur enrichi
                Expanded(
                  child: quill.QuillEditor(
                    controller: _quillController,
                    scrollController: ScrollController(),
                    configurations: quill.QuillEditorConfigurations(
                      autoFocus: true,
                      expands: true,
                      padding: EdgeInsets.all(16),
                      customStyles: quill.DefaultStyles(
                        quill.DefaultTextBlockStyle(
                          TextStyle(
                            fontFamily: _fontFamily,
                            fontSize: _fontSize,
                            color: Color(_textColor),
                          ),
                          horizontalSpacing: 0,
                          verticalSpacing: 8,
                          verticalAlignment: quill.VerticalAlignment.center,
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Barre d'info
                Container(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 12, color: Color(_textColor).withOpacity(0.5)),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                        style: TextStyle(fontSize: 10, color: Color(_textColor).withOpacity(0.5)),
                      ),
                      if (_reminderDate != null) ...[
                        SizedBox(width: 12),
                        Icon(Icons.notifications, size: 12, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(_reminderDate!),
                          style: TextStyle(fontSize: 10, color: Colors.orange),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            // Indicateur de sauvegarde
            if (_hasChanges)
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                      SizedBox(width: 8),
                      Text('Sauvegarde...', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
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
    _quillController.dispose();
    _recorder.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}