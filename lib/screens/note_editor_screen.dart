import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
  int _backgroundColor = 0xFFFFFFFF;
  int _textColor = 0xFF000000;
  bool _isPinned = false;

  final List<int> _backgroundColors = [
    0xFFFFFFFF, // Blanc
    0xFFFFF3E0, // Crème
    0xFFE8F5E9, // Vert clair
    0xFFE3F2FD, // Bleu clair
    0xFFFCE4EC, // Rose clair
    0xFFF3E5F5, // Violet clair
    0xFFFFEBEE, // Rouge clair
    0xFFFFF9C4, // Jaune clair
    0xFFE0F7FA, // Cyan clair
    0xFFF1F8E9, // Vert très clair
  ];

  final Map<int, int> _recommendedTextColors = {
    0xFFFFFFFF: 0xFF000000,
    0xFFFFF3E0: 0xFF4E342E,
    0xFFE8F5E9: 0xFF1B5E20,
    0xFFE3F2FD: 0xFF0D47A1,
    0xFFFCE4EC: 0xFF880E4F,
    0xFFF3E5F5: 0xFF4A148C,
    0xFFFFEBEE: 0xFFB71C1C,
    0xFFFFF9C4: 0xFFF57F17,
    0xFFE0F7FA: 0xFF006064,
    0xFFF1F8E9: 0xFF33691E,
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _backgroundColor = widget.note?.backgroundColor ?? 0xFFFFFFFF;
    _textColor = widget.note?.textColor ?? _getRecommendedTextColor(_backgroundColor);
    _isPinned = widget.note?.isPinned ?? false;
  }

  int _getRecommendedTextColor(int bgColor) {
    return _recommendedTextColors[bgColor] ?? 0xFF000000;
  }

  Future<void> _saveNote() async {
    if (_titleController.text.isEmpty && _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Veuillez ajouter du contenu'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final note = Note(
      id: widget.note?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.isEmpty ? 'Sans titre' : _titleController.text,
      content: _contentController.text,
      createdAt: widget.note?.createdAt ?? now,
      updatedAt: now,
      backgroundColor: _backgroundColor,
      textColor: _textColor,
      isPinned: _isPinned,
    );

    if (widget.note?.id != null) {
      await widget.noteService.updateNote(note);
    } else {
      await widget.noteService.addNote(note);
    }

    Navigator.pop(context, true);
  }

  void _showColorPicker() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Personnaliser la note',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text('Couleur de fond', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _backgroundColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _backgroundColor = color;
                        _textColor = _getRecommendedTextColor(color);
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: Color(color),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _backgroundColor == color ? Color(0xFF6366F1) : Colors.grey.shade300,
                          width: _backgroundColor == color ? 3 : 1,
                        ),
                        boxShadow: _backgroundColor == color
                            ? [BoxShadow(color: Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8)]
                            : null,
                      ),
                      child: _backgroundColor == color
                          ? Icon(Icons.check, size: 20, color: _getRecommendedTextColor(color) == 0xFFFFFFFF ? Colors.white : Colors.black54)
                          : null,
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
                  Colors.black,
                  Colors.red,
                  Colors.blue,
                  Colors.green,
                  Colors.purple,
                  Colors.orange,
                  Colors.pink,
                  Colors.teal,
                  Colors.white,
                ].map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _textColor = color.value;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _textColor == color.value ? Color(0xFF6366F1) : Colors.grey.shade300,
                          width: _textColor == color.value ? 3 : 1,
                        ),
                        boxShadow: _textColor == color.value
                            ? [BoxShadow(color: Color(0xFF6366F1).withOpacity(0.3), blurRadius: 8)]
                            : null,
                      ),
                      child: _textColor == color.value
                          ? Icon(Icons.check, size: 20, color: color == Colors.white ? Colors.black : Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(_backgroundColor),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
        leading: Container(
          margin: EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: Color(_textColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Color(_textColor)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Color(_textColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.push_pin, 
                color: _isPinned ? Colors.blue : Color(_textColor).withOpacity(0.6)),
              onPressed: () {
                setState(() {
                  _isPinned = !_isPinned;
                });
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Color(_textColor).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.color_lens, color: Color(_textColor)),
              onPressed: _showColorPicker,
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(Icons.save, color: Colors.green),
              onPressed: _saveNote,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(_textColor),
                height: 1.3,
              ),
              decoration: InputDecoration(
                hintText: 'Titre...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(_textColor).withOpacity(0.4),
                ),
                border: InputBorder.none,
              ),
            ),
            SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Color(_textColor),
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'Écrivez votre note ici...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 15,
                    color: Color(_textColor).withOpacity(0.4),
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Color(_textColor).withOpacity(0.5),
                  ),
                  SizedBox(width: 6),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Color(_textColor).withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}