import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';

class NoteService {
  static const String _notesKey = 'notes';
  final SharedPreferences _prefs;

  NoteService(this._prefs);

  Future<List<Note>> getNotes() async {
    final String? notesString = _prefs.getString(_notesKey);
    if (notesString == null) return [];
    
    final List<dynamic> notesMap = json.decode(notesString);
    return notesMap.map((note) => Note.fromJson(note)).toList();
  }

  Future<void> saveNotes(List<Note> notes) async {
    final String notesString = json.encode(notes.map((note) => note.toJson()).toList());
    await _prefs.setString(_notesKey, notesString);
  }

  Future<void> addNote(Note note) async {
    final notes = await getNotes();
    notes.add(note);
    await saveNotes(notes);
  }

  Future<void> updateNote(Note updatedNote) async {
    final notes = await getNotes();
    final index = notes.indexWhere((note) => note.id == updatedNote.id);
    if (index != -1) {
      notes[index] = updatedNote;
      await saveNotes(notes);
    }
  }

  Future<void> deleteNote(String id) async {
    final notes = await getNotes();
    notes.removeWhere((note) => note.id == id);
    await saveNotes(notes);
  }
}