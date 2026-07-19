import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notion_service.dart';
import 'setup_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _notion = NotionService.instance;
  final _rawgKeyController = TextEditingController();
  bool _isConnected = false;
  String _dbId = '';
  int _cacheSize = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isConnected = _notion.isConfigured;
      _dbId = _notion.gamesDbId;
      _rawgKeyController.text = prefs.getString('rawg_key') ?? '';
    });
  }

  Future<void> _saveRawgKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('rawg_key', _rawgKeyController.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('RAWG Key guardada',
              style: GoogleFonts.inter(color: const Color(0xFF0A0E1A))),
          backgroundColor: const Color(0xFF00F0FF),
        ),
      );
    }
  }

  void _clearCache() {
    _notion.clearCache();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Caché limpiado',
              style: GoogleFonts.inter(color: const Color(0xFF0A0E1A))),
          backgroundColor: const Color(0xFF00F0FF),
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141927),
        title: Text('¿Desconectar?',
            style: GoogleFonts.spaceGrotesk(color: const Color(0xFFF0F2F5))),
        content: Text(
          'Se borrarán las credenciales de Notion guardadas.',
          style: GoogleFonts.inter(color: const Color(0xFF6B7394)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancelar', style: GoogleFonts.inter(color: const Color(0xFF6B7394))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Desconectar',
                style: GoogleFonts.inter(color: const Color(0xFFFF2D78))),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notion_token');
    await prefs.remove('notion_games_db_id');
    _notion.clearCache();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SetupScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _editConnection() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SetupScreen()),
    );
    if (result == true) {
      _loadSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configuración', style: GoogleFonts.spaceGrotesk()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Connection status
          _buildSectionHeader('Conexión Notion'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141927),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isConnected
                    ? const Color(0xFF00F0FF).withOpacity(0.3)
                    : const Color(0xFFFF2D78).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isConnected
                            ? const Color(0xFF00F0FF)
                            : const Color(0xFFFF2D78),
                        boxShadow: [
                          BoxShadow(
                            color: (_isConnected
                                    ? const Color(0xFF00F0FF)
                                    : const Color(0xFFFF2D78))
                                .withOpacity(0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _isConnected ? 'Conectado' : 'Desconectado',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isConnected
                            ? const Color(0xFF00F0FF)
                            : const Color(0xFFFF2D78),
                      ),
                    ),
                  ],
                ),
                if (_isConnected) ...[
                  const SizedBox(height: 8),
                  Text(
                    'DB: ${_dbId.length > 16 ? '${_dbId.substring(0, 16)}...' : _dbId}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFF6B7394)),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _editConnection,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF1C2237)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Editar',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFF0F2F5))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _disconnect,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                              color: Color(0xFFFF2D78), width: 0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Desconectar',
                            style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFFF2D78))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // RAWG API Key
          _buildSectionHeader('Búsqueda de Juegos (RAWG)'),
          const SizedBox(height: 12),
          TextField(
            controller: _rawgKeyController,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFFF0F2F5)),
            decoration: InputDecoration(
              labelText: 'RAWG API Key',
              hintText: 'Tu clave de rawg.io',
              prefixIcon:
                  const Icon(Icons.vpn_key_rounded, color: Color(0xFF6B7394)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save_rounded, color: Color(0xFF00F0FF)),
                onPressed: _saveRawgKey,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Necesaria para buscar juegos en RAWG. Obtén una en rawg.io/apidocs',
            style:
                GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6B7394)),
          ),
          const SizedBox(height: 32),

          // Cache
          _buildSectionHeader('Caché'),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _clearCache,
              icon: const Icon(Icons.cleaning_services_rounded,
                  size: 18, color: Color(0xFFFFBE0B)),
              label: Text('Limpiar caché',
                  style: GoogleFonts.inter(
                      fontSize: 13, color: const Color(0xFFF0F2F5))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF1C2237)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // App info
          Center(
            child: Column(
              children: [
                Text(
                  'Game Tracker v2.0',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    color: const Color(0xFF6B7394),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Powered by Notion API',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF3A4060)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF00F0FF),
        letterSpacing: 0.5,
      ),
    );
  }
}
