import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool isDarkMode;

  const SettingsScreen({
    Key? key,
    required this.onThemeChanged,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  String _sortBy = 'date';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
      _notifications = prefs.getBool('notifications') ?? true;
      _sortBy = prefs.getString('sort_by') ?? 'date';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setBool('notifications', _notifications);
    await prefs.setString('sort_by', _sortBy);
    widget.onThemeChanged(_darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Paramètres',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          Container(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Préférences générales',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(
                          'Mode sombre',
                          style: GoogleFonts.inter(),
                        ),
                        subtitle: Text(
                          'Activer le thème sombre',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        value: _darkMode,
                        onChanged: (value) {
                          setState(() {
                            _darkMode = value;
                            _saveSettings();
                          });
                        },
                        activeColor: Color(0xFF6366F1),
                      ),
                      Divider(height: 1),
                      SwitchListTile(
                        title: Text(
                          'Notifications',
                          style: GoogleFonts.inter(),
                        ),
                        subtitle: Text(
                          'Recevoir des rappels (bientôt disponible)',
                          style: GoogleFonts.inter(fontSize: 12),
                        ),
                        value: _notifications,
                        onChanged: (value) {
                          setState(() {
                            _notifications = value;
                            _saveSettings();
                          });
                        },
                        activeColor: Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Organisation',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      RadioListTile(
                        title: Text('Trier par date'),
                        value: 'date',
                        groupValue: _sortBy,
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value as String;
                            _saveSettings();
                          });
                        },
                        activeColor: Color(0xFF6366F1),
                      ),
                      RadioListTile(
                        title: Text('Trier par titre'),
                        value: 'title',
                        groupValue: _sortBy,
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value as String;
                            _saveSettings();
                          });
                        },
                        activeColor: Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'À propos',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.info_outline, color: Color(0xFF6366F1)),
                        title: Text('Version', style: GoogleFonts.inter()),
                        subtitle: Text('1.0.0', style: GoogleFonts.inter()),
                      ),
                      ListTile(
                        leading: Icon(Icons.star_outline, color: Color(0xFF6366F1)),
                        title: Text('Évaluer l\'application', style: GoogleFonts.inter()),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Merci pour votre soutien !')),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.share, color: Color(0xFF6366F1)),
                        title: Text('Partager', style: GoogleFonts.inter()),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Fonctionnalité à venir')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}