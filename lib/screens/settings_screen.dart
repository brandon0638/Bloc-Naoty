import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/note_service.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const SettingsScreen({Key? key, required this.onThemeChanged, required this.isDarkMode}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  String _layout = 'grid';
  String _defaultFont = 'Inter';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.notification.request();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _notifications = prefs.getBool('notifications') ?? true;
      _layout = prefs.getString('layout') ?? 'grid';
      _defaultFont = prefs.getString('default_font') ?? 'Inter';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setBool('notifications', _notifications);
    await prefs.setString('layout', _layout);
    await prefs.setString('default_font', _defaultFont);
    widget.onThemeChanged(_darkMode);
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paramètres', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          Container(padding: EdgeInsets.all(24), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Préférences', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              _buildSettingsCard([
                SwitchListTile(
                  title: Text('Mode sombre'),
                  subtitle: Text('Activer le thème sombre'),
                  value: _darkMode,
                  onChanged: (value) { setState(() { _darkMode = value; _saveSettings(); }); },
                  activeColor: Color(0xFF6366F1),
                ),
                SwitchListTile(
                  title: Text('Notifications'),
                  subtitle: Text('Recevoir des rappels et notifications'),
                  value: _notifications,
                  onChanged: (value) { setState(() { _notifications = value; _saveSettings(); }); },
                  activeColor: Color(0xFF6366F1),
                ),
              ]),

              SizedBox(height: 24),
              Text('Apparence', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              _buildSettingsCard([
                ListTile(
                  title: Text('Layout des notes'),
                  subtitle: Text('Affichage en grille ou en liste'),
                  trailing: SegmentedButton<String>(
                    segments: [
                      ButtonSegment(value: 'grid', icon: Icon(Icons.grid_view), label: Text('Grille')),
                      ButtonSegment(value: 'list', icon: Icon(Icons.list), label: Text('Liste')),
                    ],
                    selected: {_layout},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() { _layout = selection.first; _saveSettings(); });
                    },
                  ),
                ),
                ListTile(
                  title: Text('Police par défaut'),
                  trailing: DropdownButton<String>(
                    value: _defaultFont,
                    items: ['Inter', 'Poppins', 'Roboto', 'Lato', 'Montserrat'].map((font) => DropdownMenuItem(value: font, child: Text(font))).toList(),
                    onChanged: (value) { setState(() { _defaultFont = value!; _saveSettings(); }); },
                  ),
                ),
              ]),

              SizedBox(height: 24),
              Text('Données', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              _buildSettingsCard([
                ListTile(
                  leading: Icon(Icons.info_outline, color: Color(0xFF6366F1)),
                  title: Text('Version'),
                  subtitle: Text('1.0.0'),
                ),
                ListTile(
                  leading: Icon(Icons.star_outline, color: Color(0xFF6366F1)),
                  title: Text('Évaluer l\'application'),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Merci pour votre soutien !'))),
                ),
                ListTile(
                  leading: Icon(Icons.share, color: Color(0xFF6366F1)),
                  title: Text('Partager'),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fonctionnalité à venir'))),
                ),
              ]),
            ],
          )),
        ],
      ),
    );
  }
}