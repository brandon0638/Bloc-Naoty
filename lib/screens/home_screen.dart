import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note_model.dart';
import '../services/note_service.dart';
import '../widgets/note_card.dart';
import 'note_editor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const HomeScreen({
    Key? key,
    required this.onThemeChanged,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  late NoteService _noteService;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    final prefs = await SharedPreferences.getInstance();
    _noteService = NoteService(prefs);
    await _loadNotes();
  }

  Future<void> _loadNotes() async {
    final notes = await _noteService.getNotes();
    setState(() {
      _notes = notes..sort((a, b) {
        if (a.isPinned != b.isPinned) {
          return b.isPinned ? 1 : -1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });
      _filteredNotes = _notes;
    });
  }

  void _filterNotes(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredNotes = _notes;
      } else {
        _filteredNotes = _notes.where((note) =>
          note.title.toLowerCase().contains(query.toLowerCase()) ||
          note.content.toLowerCase().contains(query.toLowerCase())
        ).toList();
      }
    });
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: TextField(
                  autofocus: true,
                  style: GoogleFonts.inter(),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une note...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    hintStyle: GoogleFonts.inter(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[500]
                          : Colors.grey[500],
                    ),
                  ),
                  onChanged: _filterNotes,
                ),
              )
            : Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        height: 32,
                        width: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.note, size: 24, color: Colors.white);
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Naoty',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ).createShader(Rect.fromLTWH(0, 0, 120, 50)),
                    ),
                  ),
                ],
              ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 4),
            child: IconButton(
              icon: Icon(_isSearching ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = !_isSearching;
                  if (!_isSearching) {
                    _filterNotes('');
                  }
                });
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      onThemeChanged: widget.onThemeChanged,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                ).then((_) => _loadNotes());
              },
            ),
          ),
        ],
      ),
      body: _filteredNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[800]
                          : Colors.grey[100],
                    ),
                    child: Icon(
                      Icons.notes_rounded,
                      size: 60,
                      color: Colors.grey[400],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Aucune note pour le moment',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Appuyez sur + pour créer votre première note',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotes,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive: 2 colonnes sur mobile, 3 sur tablette
                  int crossAxisCount = constraints.maxWidth < 600 ? 2 : 3;
                  double aspectRatio = constraints.maxWidth < 600 ? 0.75 : 0.8;
                  
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      padding: EdgeInsets.only(top: 8, bottom: 80),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: _filteredNotes.length,
                      itemBuilder: (context, index) {
                        return AnimationConfiguration.staggeredGrid(
                          position: index,
                          duration: Duration(milliseconds: 500),
                          columnCount: crossAxisCount,
                          child: ScaleAnimation(
                            child: FadeInAnimation(
                              child: NoteCard(
                                note: _filteredNotes[index],
                                onDelete: () => _loadNotes(),
                                noteService: _noteService,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteEditorScreen(
                  noteService: _noteService,
                ),
              ),
            );
            if (result == true) {
              await _loadNotes();
            }
          },
          child: Icon(Icons.add, size: 28),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
    );
  }
}