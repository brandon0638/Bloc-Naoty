import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';
import '../models/note_model.dart';
import '../services/note_service.dart';
import '../screens/note_editor_screen.dart';

class NoteCard extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;
  final NoteService noteService;
  final Function(Note)? onArchive;
  final Function(Note)? onFavorite;

  const NoteCard({
    Key? key,
    required this.note,
    required this.onDelete,
    required this.noteService,
    this.onArchive,
    this.onFavorite,
  }) : super(key: key);

  Future<void> _deleteNote(BuildContext context) async {
    final deletedNote = note;
    await noteService.deleteNote(note.id);
    
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      Vibration.vibrate(duration: 50);
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Note supprimée'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          action: SnackBarAction(
            label: 'ANNULER',
            textColor: Colors.orange,
            onPressed: () async {
              await noteService.addNote(deletedNote);
              onDelete();
              final hasVibrator2 = await Vibration.hasVibrator() ?? false;
              if (hasVibrator2) {
                Vibration.vibrate(duration: 30);
              }
            },
          ),
        ),
      );
    }
    onDelete();
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      onDismissed: (direction) => _deleteNote(context),
      child: GestureDetector(
        onTap: () async {
          final hasVibrator = await Vibration.hasVibrator() ?? false;
          if (hasVibrator) {
            Vibration.vibrate(duration: 10);
          }
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
        child: Hero(
          tag: note.id,
          child: Container(
            decoration: BoxDecoration(
              color: note.imagePath != null ? null : Color(note.backgroundColor),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
              image: note.imagePath != null
                  ? DecorationImage(
                      image: FileImage(File(note.imagePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: Stack(
              children: [
                if (note.imagePath != null)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.black.withOpacity(0.3),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (note.isPinned)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.push_pin, size: 12, color: Colors.blue),
                                  SizedBox(width: 4),
                                  Text('Épinglée', style: TextStyle(fontSize: 10, color: Colors.blue)),
                                ],
                              ),
                            ),
                          if (note.isFavorite)
                            Container(
                              margin: EdgeInsets.only(left: 8),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.favorite, size: 12, color: Colors.red),
                                  SizedBox(width: 4),
                                  Text('Favori', style: TextStyle(fontSize: 10, color: Colors.red)),
                                ],
                              ),
                            ),
                          if (note.isArchived)
                            Container(
                              margin: EdgeInsets.only(left: 8),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.archive, size: 12, color: Colors.grey),
                                  SizedBox(width: 4),
                                  Text('Archivée', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ),
                          if (note.reminderDate != null)
                            Container(
                              margin: EdgeInsets.only(left: 8),
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.notifications, size: 12, color: Colors.orange),
                                  SizedBox(width: 4),
                                  Text('Rappel', style: TextStyle(fontSize: 10, color: Colors.orange)),
                                ],
                              ),
                            ),
                          Spacer(),
                          if (onArchive != null)
                            IconButton(
                              icon: Icon(Icons.archive_outlined, size: 18),
                              onPressed: () => onArchive!(note),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                          if (onFavorite != null)
                            IconButton(
                              icon: Icon(
                                note.isFavorite ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: note.isFavorite ? Colors.red : null,
                              ),
                              onPressed: () => onFavorite!(note),
                              padding: EdgeInsets.zero,
                              constraints: BoxConstraints(),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        note.title,
                        style: note.fontFamily != null
                            ? GoogleFonts.getFont(note.fontFamily!,
                                fontSize: 16, fontWeight: FontWeight.w600, color: Color(note.textColor))
                            : GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600, color: Color(note.textColor)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      Text(
                        note.content,
                        style: TextStyle(
                          fontSize: note.fontSize * 0.75,
                          color: Color(note.textColor).withOpacity(0.7),
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 10, color: Color(note.textColor).withOpacity(0.5)),
                          SizedBox(width: 4),
                          Text(
                            DateFormat('dd/MM/yy HH:mm').format(note.updatedAt),
                            style: TextStyle(fontSize: 9, color: Color(note.textColor).withOpacity(0.5)),
                          ),
                          if (note.tags.isNotEmpty) ...[
                            SizedBox(width: 8),
                            ...note.tags.take(2).map((tag) => Container(
                              margin: EdgeInsets.only(right: 4),
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('#$tag', style: TextStyle(fontSize: 8, color: Colors.blue)),
                            )),
                            if (note.tags.length > 2)
                              Text('+${note.tags.length - 2}', style: TextStyle(fontSize: 8)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}