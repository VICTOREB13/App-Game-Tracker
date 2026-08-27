import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notion_service.dart';
import '../services/theme_manager.dart';
import 'dashboard.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  final _tokenController = TextEditingController();
  final _dbIdController = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;
  bool _tokenValid = false;
  bool _dbValid = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Pre-fill if already configured
    final notion = NotionService.instance;
    if (notion.token.isNotEmpty) _tokenController.text = notion.token;
    if (notion.gamesDbId.isNotEmpty) _dbIdController.text = notion.gamesDbId;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tokenController.dispose();
    _dbIdController.dispose();
    super.dispose();
  }

  Future<void> _validateAndConnect() async {
    final token = _tokenController.text.trim();
    final dbId = _dbIdController.text.trim();

    if (token.isEmpty || dbId.isEmpty) {
      setState(() => _errorMessage = 'Ambos campos son obligatorios');
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _tokenValid = false;
      _dbValid = false;
    });

    // Configure temporarily to test
    NotionService.instance.configure(token: token, gamesDbId: dbId);

    // Step 1: Validate token
    final tokenOk = await NotionService.instance.validateConnection();
    if (!tokenOk) {
      setState(() {
        _isValidating = false;
        _errorMessage =
            'Token inválido. Verifica que copiaste el Internal Integration Token correctamente.';
      });
      return;
    }

    setState(() => _tokenValid = true);

    // Step 2: Validate database access
    final dbOk = await NotionService.instance.validateDatabase(dbId);
    if (!dbOk) {
      setState(() {
        _isValidating = false;
        _errorMessage =
            'No se pudo acceder a la base de datos. Asegúrate de compartirla con tu integración.';
      });
      return;
    }

    setState(() => _dbValid = true);

    // Save credentials
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notion_token', token);
    await prefs.setString('notion_games_db_id', dbId);

    // Success — navigate to dashboard or pop back if editing
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: canGoBack
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppColors.textPrimary(context)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'Editar Conexión',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary(context),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFDC2626).withOpacity(0.4),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'VE',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Victor ',
                          style: GoogleFonts.outfit(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary(context),
                          ),
                        ),
                        TextSpan(
                          text: 'Engineer',
                          style: GoogleFonts.outfit(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Entertainment Tracker • Notion Integration',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary(context),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Selector de Apariencia & Tema (Oscuro / Claro / Sistema)
                  AnimatedBuilder(
                    animation: ThemeManager.instance,
                    builder: (context, _) {
                      final current = ThemeManager.instance.themeMode;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border(context)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.palette_outlined,
                                  size: 16,
                                  color: Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Apariencia & Tema',
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary(context),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _buildThemeOption(
                                  label: 'Oscuro',
                                  icon: Icons.dark_mode_rounded,
                                  isSelected: current == ThemeMode.dark,
                                  onTap: () => ThemeManager.instance
                                      .setThemeMode(ThemeMode.dark),
                                ),
                                const SizedBox(width: 10),
                                _buildThemeOption(
                                  label: 'Claro',
                                  icon: Icons.light_mode_rounded,
                                  isSelected: current == ThemeMode.light,
                                  onTap: () => ThemeManager.instance
                                      .setThemeMode(ThemeMode.light),
                                ),
                                const SizedBox(width: 10),
                                _buildThemeOption(
                                  label: 'Sistema',
                                  icon: Icons.brightness_auto_rounded,
                                  isSelected: current == ThemeMode.system,
                                  onTap: () => ThemeManager.instance
                                      .setThemeMode(ThemeMode.system),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Token field
                  _buildValidatedField(
                    controller: _tokenController,
                    label: 'Integration Token',
                    hint: 'ntn_...',
                    icon: Icons.key_rounded,
                    isValid: _tokenValid,
                    isValidating: _isValidating && !_tokenValid,
                  ),
                  const SizedBox(height: 18),

                  // Database ID field
                  _buildValidatedField(
                    controller: _dbIdController,
                    label: 'Games Database ID',
                    hint: '29094bde-8dc7-8151-...',
                    icon: Icons.storage_rounded,
                    isValid: _dbValid,
                    isValidating: _isValidating && _tokenValid && !_dbValid,
                  ),
                  const SizedBox(height: 12),

                  // Helper text
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface(context),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border(context)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: AppColors.textSecondary(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El Database ID se encuentra en la URL de tu base de datos en Notion. Asegúrate de compartir la DB con tu integración.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary(context),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFDC2626).withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 18, color: Color(0xFFDC2626)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Connect button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isValidating ? null : _validateAndConnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFFDC2626).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isValidating
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  canGoBack
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.link_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  canGoBack
                                      ? 'Guardar y Actualizar'
                                      : 'Conectar Base de Datos',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFDC2626)
                : AppColors.surfaceSubtle(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFDC2626)
                  : AppColors.border(context),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : AppColors.textSecondary(context),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? Colors.white
                      : AppColors.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValidatedField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isValid,
    required bool isValidating,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.textPrimary(context),
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textSecondary(context)),
        suffixIcon: isValidating
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFDC2626),
                  ),
                ),
              )
            : isValid
                ? const Icon(Icons.check_circle, color: Color(0xFF10B981))
                : null,
      ),
    );
  }
}
