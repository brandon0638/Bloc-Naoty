import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import '../models/note_model.dart';
import '../services/note_service.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const HomeScreen({Key? key, required this.onThemeChanged, required this.isDarkMode}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  List<Note> _notes = [];
  List<Note> _archivedNotes = [];
  List<Note> _filteredNotes = [];
  late NoteService _noteService;
  bool _isSearching = false;
  String _searchQuery = '';
  int _selectedTab = 0;
  late TabController _tabController;
  List<Folder> _folders = [];
  String? _selectedFolderId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initService();
  }

  Future<void> _initService() async {
    final prefs = await SharedPreferences.getInstance();
    _noteService = NoteService(prefs);
    await _loadNotes();
    await _loadFolders();
    await _cleanDuplicateNotes(); // Nettoyer les doublons
  }

  // Fonction pour nettoyer les notes en double
  Future<void> _cleanDuplicateNotes() async {
    final notes = await _noteService.getNotes();
    
    // Grouper par contenu pour trouver les doublons
    final Map<String, List<Note>> groupedByContent = {};
    for (var note in notes) {
      // Créer une clé unique basée sur le titre et le contenu
      final key = '${note.title}|${note.content}';
      if (!groupedByContent.containsKey(key)) {
        groupedByContent[key] = [];
      }
      groupedByContent[key]!.add(note);
    }
    
    bool hasDuplicates = false;
    
    // Supprimer les doublons (garder la plus récente)
    for (var group in groupedByContent.values) {
      if (group.length > 1) {
        hasDuplicates = true;
        // Trier par date de modification (la plus récente d'abord)
        group.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        // Garder la première, supprimer les autres
        for (var i = 1; i < group.length; i++) {
          await _noteService.deleteNote(group[i].id);
          print('Note supprimée: ${group[i].title}');
        }
      }
    }
    
    if (hasDuplicates) {
      print('✅ Nettoyage des doublons terminé');
      await _loadNotes(); // Recharger les notes
    }
  }

  Future<void> _loadFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final foldersJson = prefs.getStringList('folders') ?? [];
    _folders = foldersJson.map((json) => Folder.fromJson(jsonDecode(json) as Map<String, dynamic>)).toList();
    setState(() {});
  }

  Future<void> _saveFolders() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('folders', _folders.map((f) => jsonEncode(f.toJson())).toList());
  }

  Future<void> _loadNotes() async {
    final notes = await _noteService.getNotes();
    setState(() {
      _notes = notes.where((n) => !n.isArchived && (_selectedFolderId == null || n.folderId == _selectedFolderId)).toList();
      _notes.sort((a, b) {
        if (a.isPinned != b.isPinned) return b.isPinned ? 1 : -1;
        if (a.isFavorite != b.isFavorite) return b.isFavorite ? 1 : -1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      
      _archivedNotes = notes.where((n) => n.isArchived).toList();
      _archivedNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      _applyFilter();
    });
  }

  void _applyFilter() {
    List<Note> source;
    if (_selectedTab == 0) source = _notes;
    else if (_selectedTab == 1) source = _archivedNotes;
    else source = _notes.where((n) => n.isFavorite).toList();
    
    if (_searchQuery.isEmpty) {
      _filteredNotes = source;
    } else {
      _filteredNotes = source.where((note) =>
        note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        note.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        note.tags.any((tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()))
      ).toList();
    }
    setState(() {});
  }

  void _filterNotes(String query) {
    _searchQuery = query;
    _applyFilter();
  }

  Future<void> _archiveNote(Note note) async {
    final updatedNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
      backgroundColor: note.backgroundColor,
      textColor: note.textColor,
      isPinned: false,
      isArchived: !note.isArchived,
      isFavorite: note.isFavorite,
      tags: note.tags,
      folderId: note.folderId,
      imagePath: note.imagePath,
      attachments: note.attachments,
      reminderDate: note.reminderDate,
      isLocked: note.isLocked,
      fontFamily: note.fontFamily,
      fontSize: note.fontSize,
    );
    await _noteService.updateNote(updatedNote);
    await _loadNotes();
    
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      Vibration.vibrate(duration: 30);
    }
  }

  Future<void> _toggleFavorite(Note note) async {
    final updatedNote = Note(
      id: note.id,
      title: note.title,
      content: note.content,
      createdAt: note.createdAt,
      updatedAt: DateTime.now(),
      backgroundColor: note.backgroundColor,
      textColor: note.textColor,
      isPinned: note.isPinned,
      isArchived: note.isArchived,
      isFavorite: !note.isFavorite,
      tags: note.tags,
      folderId: note.folderId,
      imagePath: note.imagePath,
      attachments: note.attachments,
      reminderDate: note.reminderDate,
      isLocked: note.isLocked,
      fontFamily: note.fontFamily,
      fontSize: note.fontSize,
    );
    await _noteService.updateNote(updatedNote);
    await _loadNotes();
    
    final hasVibrator = await Vibration.hasVibrator() ?? false;
    if (hasVibrator) {
      Vibration.vibrate(duration: 20);
    }
  }

  void _createFolder() async {
    final nameController = TextEditingController();
    int selectedColor = 0xFF6366F1;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nouveau dossier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(hintText: 'Nom du dossier'),
            ),
            SizedBox(height: 16),
            Text('Couleur'),
            SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Colors.blue, Colors.red, Colors.green, Colors.orange,
                Colors.purple, Colors.pink, Colors.teal, Colors.indigo,
              ].map((color) => GestureDetector(
                onTap: () => selectedColor = color.value,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: selectedColor == color.value ? Colors.white : Colors.transparent, width: 2),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              final newFolder = Folder(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: nameController.text,
                color: selectedColor,
              );
              _folders.add(newFolder);
              await _saveFolders();
              setState(() {});
              Navigator.pop(context);
            },
            child: Text('Créer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
        title: _isSearching
            ? Container(
                height: 45,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  autofocus: true,
                  style: GoogleFonts.inter(),
                  decoration: InputDecoration(
                    hintText: 'Rechercher...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: _filterNotes,
                ),
              )
            : Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset('assets/images/logo.jpg', height: 32, width: 32,
                        errorBuilder: (_, __, ___) => Icon(Icons.note, color: Colors.white)),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Naoty', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold,
                    foreground: Paint()..shader = LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ).createShader(Rect.fromLTWH(0, 0, 120, 50)),
                  )),
                ],
              ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.folder_outlined),
            onSelected: (value) {
              if (value == 'create') _createFolder();
              else setState(() => _selectedFolderId = value == 'all' ? null : value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'create', child: Row(
                children: [Icon(Icons.create_new_folder), SizedBox(width: 8), Text('Nouveau dossier')],
              )),
              PopupMenuDivider(),
              PopupMenuItem(value: 'all', child: Text('Toutes les notes')),
              ..._folders.map((f) => PopupMenuItem(value: f.id, child: Row(
                children: [Icon(Icons.folder, color: Color(f.color)), SizedBox(width: 8), Text(f.name)],
              ))),
            ],
          ),
          IconButton(icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) _filterNotes('');
            }),
          ),
          IconButton(icon: Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(
              onThemeChanged: widget.onThemeChanged, isDarkMode: widget.isDarkMode,
            ))).then((_) => _loadNotes()),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            _selectedTab = index;
            _applyFilter();
          },
          tabs: [
            Tab(icon: Icon(Icons.note), text: 'Notes'),
            Tab(icon: Icon(Icons.archive), text: 'Archives'),
            Tab(icon: Icon(Icons.favorite), text: 'Favoris'),
          ],
        ),
      ),
      body: _filteredNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notes_rounded, size: 80, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('Aucune note', style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Text('Appuyez sur + pour créer', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            )
          : AnimationLimiter(
              child: GridView.builder(
                padding: EdgeInsets.all(12),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemCount: _filteredNotes.length,
                itemBuilder: (context, index) {
                  return AnimationConfiguration.staggeredGrid(
                    position: index,
                    duration: Duration(milliseconds: 500),
                    columnCount: 2,
                    child: ScaleAnimation(
                      child: FadeInAnimation(
                        child: NoteCard(
                          note: _filteredNotes[index],
                          onDelete: _loadNotes,
                          noteService: _noteService,
                          onArchive: _archiveNote,
                          onFavorite: _toggleFavorite,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0xFF6366F1).withOpacity(0.4), blurRadius: 20, offset: Offset(0, 8))],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final hasVibrator = await Vibration.hasVibrator() ?? false;
            if (hasVibrator) Vibration.vibrate(duration: 20);
            final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => NoteEditorScreen(noteService: _noteService)));
            if (result == true) await _loadNotes();
          },
          child: Icon(Icons.add, size: 28),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }
}