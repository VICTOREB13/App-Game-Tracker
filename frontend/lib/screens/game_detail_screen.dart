import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../models/game.dart';

class GameDetailScreen extends StatefulWidget {
  final Game game;
  const GameDetailScreen({super.key, required this.game});

  @override
  State<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends State<GameDetailScreen> {
  final supabase = Supabase.instance.client;
  late TextEditingController _titleController;
  late TextEditingController _hoursController;
  late TextEditingController _tagsController;
  late TextEditingController _hltbMainController;
  late TextEditingController _hltbCompController;
  late TextEditingController _coverUrlController;
  
  late String _selectedStatus;
  late String _selectedPlatform;
  late List<String> _selectedGenres;
  DateTime? _firstCompletedAt;
  bool _isSaving = false;
  bool _isUploading = false;

  final List<String> _statuses = ['Por Jugar', 'Jugando', 'Pausado', 'Completado', 'Abandonado'];
  final List<String> _platforms = [
    'PC', 'PlayStation 5', 'PlayStation 4', 'PlayStation 3', 'PlayStation 2', 'PlayStation 1',
    'PSP', 'PS Vita', 'Xbox Series X|S', 'Xbox One', 'Xbox 360', 'Xbox Original',
    'Nintendo Switch', 'Wii U', 'Wii', 'GameCube', 'Nintendo 64', 'SNES', 'NES',
    'Nintendo 3DS', 'Nintendo DS', 'Game Boy Advance', 'Game Boy', 
    'Sega Genesis', 'Sega Dreamcast', 'Mobile', 'Otra'
  ];

  final List<String> _allGenres = [
    'Acción', 'Indie', 'Aventura', 'RPG', 'Estrategia', 'Shooter', 'Casual', 
    'Simulación', 'Puzzle', 'Arcade', 'Plataformas', 'Carreras', 'Deportes', 
    'Lucha', 'Familiar', 'Juegos de Mesa', 'Educativo', 'Card Game'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.game.title);
    _hoursController = TextEditingController(text: widget.game.hoursPlayed?.toString() ?? '0');
    _tagsController = TextEditingController(text: widget.game.tags ?? '');
    _hltbMainController = TextEditingController(text: widget.game.hltbMain?.toString() ?? '0');
    _hltbCompController = TextEditingController(text: widget.game.hltbCompletionist?.toString() ?? '0');
    _coverUrlController = TextEditingController(text: widget.game.coverUrl ?? '');
    
    _selectedStatus = _statuses.contains(widget.game.status) ? widget.game.status! : _statuses[0];
    _selectedPlatform = _platforms.contains(widget.game.platform) ? widget.game.platform! : _platforms[0];
    
    _selectedGenres = widget.game.genre?.split(',').map((e) => e.trim()).where((s) => s.isNotEmpty).toList() ?? [];
    
    // Si la API trajo géneros nuevos (ej. RAWG), los añadimos visualmente a la lista para que aparezcan sus Chips.
    for (var g in _selectedGenres) {
      if (!_allGenres.contains(g)) {
        _allGenres.add(g);
      }
    }
    
    _firstCompletedAt = widget.game.firstCompletedAt;
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Compresión automática al 50%
    );

    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      final bytes = await image.readAsBytes();
      final fileExt = image.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'user_uploads/$fileName';

      await supabase.storage.from('covers').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(contentType: 'image/$fileExt'),
      );

      final String publicUrl = supabase.storage.from('covers').getPublicUrl(filePath);
      
      setState(() {
        _coverUrlController.text = publicUrl;
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('📸 Imagen subida correctamente')));
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error al subir: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _firstCompletedAt ?? DateTime.now(),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );
    if (picked != null && picked != _firstCompletedAt) {
      setState(() => _firstCompletedAt = picked);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final hours = double.tryParse(_hoursController.text) ?? 0.0;
      await supabase.from('games').update({
        'title': _titleController.text,
        'status': _selectedStatus,
        'platform': _selectedPlatform,
        'hours_played': hours,
        'cover_url': _coverUrlController.text,
        'genre': _selectedGenres.join(', '),
        'tags': _tagsController.text,
        'hltb_main': double.tryParse(_hltbMainController.text) ?? 0.0,
        'hltb_completionist': double.tryParse(_hltbCompController.text) ?? 0.0,
        'first_completed_at': _firstCompletedAt?.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.game.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Cambios guardados'), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteGame() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar juego?'),
        content: const Text('Esta acción borrará permanentemente el juego de tu biblioteca.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm) return;
    try {
      await supabase.from('games').delete().eq('id', widget.game.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Error al borrar: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Detalles del Juego'),
        actions: [
          IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: _deleteGame),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Portada y Selector
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: _coverUrlController.text,
                          height: 300,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(height: 300, width: 200, color: Colors.grey[900]),
                          errorWidget: (context, url, e) => Container(height: 300, width: 200, color: Colors.grey[800], child: const Icon(Icons.gamepad, size: 50)),
                        ),
                      ),
                      if (_isUploading) const CircularProgressIndicator(),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _isUploading ? null : _pickAndUploadImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Cambiar Portada (Galería)'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Nombre del Juego', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    items: _statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _selectedStatus = val!),
                    decoration: const InputDecoration(labelText: 'Estado'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPlatform,
                    items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (val) => setState(() => _selectedPlatform = val!),
                    decoration: const InputDecoration(labelText: 'Consola'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _hoursController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Horas Jugadas', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            const Text('Fecha de Primera vez que lo pasaste:', style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Text(
                      _firstCompletedAt == null ? 'Seleccionar fecha' : DateFormat('dd / MM / yyyy').format(_firstCompletedAt!),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('Géneros:', style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _allGenres.map((g) {
                bool isSelected = _selectedGenres.contains(g);
                return FilterChip(
                  label: Text(g, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white70)),
                  selected: isSelected,
                  selectedColor: Colors.blueAccent,
                  onSelected: (val) {
                    setState(() {
                      if (val) _selectedGenres.add(g);
                      else _selectedGenres.remove(g);
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(labelText: 'Etiquetas Personalizadas (Tags)'),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            const Text('Metadatos Inteligentes (HowLongToBeat)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hltbMainController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Horas Historia'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _hltbCompController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Horas 100%'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                child: _isSaving ? const CircularProgressIndicator() : const Text('Guardar Todo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
