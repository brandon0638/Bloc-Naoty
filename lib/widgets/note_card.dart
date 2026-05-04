import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/note_model.dart';
import '../services/note_service.dart';
import '../screens/note_editor_screen.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;
  final NoteService noteService;

  const NoteCard({
    Key? key,
    required this.note,
    required this.onDelete,
    required this.noteService,
  }) : super(key: key);

  Future<void> _deleteNote(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Supprimer la note'),
          content: Text('Voulez-vous vraiment supprimer cette note ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                await noteService.deleteNote(note.id);
                Navigator.pop(context);
                onDelete();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('Supprimer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteEditorScreen(
              note: note,
              noteService: noteService,
            ),
          ),
        );
        if (result == true) {
          onDelete();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Color(note.backgroundColor),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.black.withOpacity(0.05),
            width: 0.5,
          ),
        ),
        child: Stack(
          children: [
            // Gradient overlay pour plus de profondeur
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.isPinned)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.push_pin, size: 12, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'Épinglée',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 8),
                  Text(
                    note.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(note.textColor),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6),
                  Text(
                    note.content,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Color(note.textColor).withOpacity(0.7),
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 10,
                        color: Color(note.textColor).withOpacity(0.5),
                      ),
                      SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yy HH:mm').format(note.updatedAt),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Color(note.textColor).withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Color(note.textColor).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.delete_outline, size: 16,
                            color: Color(note.textColor).withOpacity(0.5)),
                          onPressed: () => _deleteNote(context),
                          constraints: BoxConstraints(minWidth: 28, minHeight: 28),
                          padding: EdgeInsets.zero,
                          splashRadius: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}