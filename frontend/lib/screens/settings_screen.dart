import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final supabase = Supabase.instance.client;
  
  final TextEditingController _steamController = TextEditingController();
  final TextEditingController _psnController = TextEditingController();
  final TextEditingController _xboxController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSyncing = false;
  final List<String> _syncLogs = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final data = await supabase.from('profiles').select().eq('id', user.id).maybeSingle();
      
      if (mounted) {
        setState(() {
          _steamController.text = data?['steam_id'] ?? '';
          _psnController.text = data?['psn_id'] ?? '';
          _xboxController.text = data?['xbox_id'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('profiles').update({
        'steam_id': _steamController.text.trim(),
        'psn_id': _psnController.text.trim(),
        'xbox_id': _xboxController.text.trim(),
      }).eq('id', user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  Future<void> _triggerSync() async {
    await _saveProfile();
    setState(() {
      _isSyncing = true;
      _syncLogs.clear();
      _syncLogs.add('🚀 Iniciando sincronización robusta...');
    });

    try {
      final syncService = SyncService();
      
      // 1. Steam
      if (_steamController.text.isNotEmpty) {
        setState(() => _syncLogs.add('📡 Conectando con Steam...'));
        final res = await syncService.syncSteam(_steamController.text.trim());
        setState(() => _syncLogs.add(res));
      }

      // 2. PlayStation
      if (_psnController.text.isNotEmpty) {
        setState(() => _syncLogs.add('🎮 Consultando PSNProfiles...'));
        final res = await syncService.syncPSN(_psnController.text.trim());
        setState(() => _syncLogs.add(res));
      }

      // 3. Xbox
      if (_xboxController.text.isNotEmpty) {
        setState(() => _syncLogs.add('💚 Consultando TrueAchievements...'));
        final res = await syncService.syncXbox(_xboxController.text.trim());
        setState(() => _syncLogs.add(res));
      }

      setState(() {
        _syncLogs.add('✨ Sincronización Finalizada.');
        _isSyncing = false;
      });
      
      await supabase.from('profiles').update({'last_sync_at': DateTime.now().toIso8601String()}).eq('id', supabase.auth.currentUser!.id);

    } catch (e) {
      setState(() {
        _syncLogs.add('❌ Error crítico: $e');
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Vincular Cuentas'), backgroundColor: Colors.transparent),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Cuentas de Juego', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              const SizedBox(height: 8),
              const Text('Asegúrate de que tus perfiles sean Públicos para poder importar los datos.', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(height: 24),
              
              _buildField('Steam ID o Nombre de Usuario', _steamController, Icons.star, hint: 'Ej: 7656... o victoreb13'),
              _buildField('PlayStation Online ID', _psnController, Icons.play_circle_fill, hint: 'Ej: Victor_E_B_13'),
              _buildField('Xbox GamerTag', _xboxController, Icons.videogame_asset, hint: 'Ej: VictorEB13'),
              
              const SizedBox(height: 32),
              
              if (_isSyncing) ...[
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 16),
              ],
              
              if (_syncLogs.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _syncLogs.map((log) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(log, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              if (!_isSyncing)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: _triggerSync,
                    icon: const Icon(Icons.sync, color: Colors.white),
                    label: const Text('SINCRONIZAR TODO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                ),
            ],
          ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white12)),
        ),
      ),
    );
  }
}
