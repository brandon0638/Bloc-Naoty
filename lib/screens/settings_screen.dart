import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _biometricLock = false;
  bool _autoLock = false;
  int _autoLockDelay = 5; // minutes
  String _layout = 'grid';
  String _defaultFont = 'Inter';
  final LocalAuthentication _localAuth = LocalAuthentication();

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
      _biometricLock = prefs.getBool('biometric_lock') ?? false;
      _autoLock = prefs.getBool('auto_lock') ?? false;
      _autoLockDelay = prefs.getInt('auto_lock_delay') ?? 5;
      _layout = prefs.getString('layout') ?? 'grid';
      _defaultFont = prefs.getString('default_font') ?? 'Inter';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _darkMode);
    await prefs.setBool('notifications', _notifications);
    await prefs.setBool('biometric_lock', _biometricLock);
    await prefs.setBool('auto_lock', _autoLock);
    await prefs.setInt('auto_lock_delay', _autoLockDelay);
    await prefs.setString('layout', _layout);
    await prefs.setString('default_font', _defaultFont);
    widget.onThemeChanged(_darkMode);
  }

  Future<void> _setupBiometric() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    if (isAvailable) {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Vérifiez votre identité pour activer le verrouillage',
        options: AuthenticationOptions(biometricOnly: true),
      );
      if (isAuthenticated) {
        setState(() => _biometricLock = true);
        await _saveSettings();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biométrie non disponible sur cet appareil')),
      );
    }
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
              // Préférences
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
              Text('Sécurité', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              _buildSettingsCard([
                SwitchListTile(
                  title: Text('Verrouillage biométrique'),
                  subtitle: Text('Utiliser empreinte digitale / Face ID'),
                  value: _biometricLock,
                  onChanged: (value) {
                    if (value && !_biometricLock) {
                      _setupBiometric();
                    } else {
                      setState(() { _biometricLock = value; _saveSettings(); });
                    }
                  },
                  activeColor: Color(0xFF6366F1),
                ),
                if (_biometricLock)
                  SwitchListTile(
                    title: Text('Verrouillage automatique'),
                    subtitle: Text('Verrouiller l\'app après inactivité'),
                    value: _autoLock,
                    onChanged: (value) { setState(() { _autoLock = value; _saveSettings(); }); },
                    activeColor: Color(0xFF6366F1),
                  ),
                if (_biometricLock && _autoLock)
                  ListTile(
                    title: Text('Délai de verrouillage'),
                    subtitle: Text('$_autoLockDelay minutes'),
                    trailing: DropdownButton<int>(
                      value: _autoLockDelay,
                      items: [1, 2, 5, 10, 15, 30].map((delay) => DropdownMenuItem(value: delay, child: Text('$delay min'))).toList(),
                      onChanged: (value) { setState(() { _autoLockDelay = value!; _saveSettings(); }); },
                    ),
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
                  leading: Icon(Icons.backup, color: Color(0xFF6366F1)),
                  title: Text('Exporter les notes'),
                  subtitle: Text('Sauvegarder toutes vos notes en JSON'),
                  onTap: () => _exportNotes(),
                ),
                ListTile(
                  leading: Icon(Icons.restore, color: Color(0xFF6366F1)),
                  title: Text('Importer des notes'),
                  subtitle: Text('Restaurer une sauvegarde'),
                  onTap: () => _importNotes(),
                ),
                ListTile(
                  leading: Icon(Icons.delete_sweep, color: Colors.red),
                  title: Text('Tout supprimer', style: TextStyle(color: Colors.red)),
                  subtitle: Text('Supprimer définitivement toutes les notes'),
                  onTap: () => _confirmDeleteAll(),
                ),
              ]),

              SizedBox(height: 24),
              Text('À propos', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
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
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Merci !'))),
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

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(children: children),
    );
  }

  Future<void> _exportNotes() async {
    // Implémenter export
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export en développement')));
  }

  Future<void> _importNotes() async {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import en développement')));
  }

  void _confirmDeleteAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tout supprimer'),
        content: Text('Cette action est irréversible. Voulez-vous vraiment supprimer toutes vos notes ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}