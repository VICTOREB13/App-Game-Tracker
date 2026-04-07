import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:html/parser.dart' as html;
import '../models/game.dart';

class SyncService {
  final supabase = Supabase.instance.client;
  String get steamKey => dotenv.env['STEAM_KEY'] ?? '';
  String get rawgKey => dotenv.env['RAWG_KEY'] ?? '';

  // Headers para evitar bloqueos básicos
  final Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
  };

  // --- 1. SINCRONIZAR A TRAVÉS DE EDGE FUNCTIONS ---
  Future<String> syncSteam(String steamInput) async {
    return await _invokeEdgeFunction('sync-steam', steamInput);
  }

  Future<String> syncPSN(String psnId) async {
    return await _invokeEdgeFunction('sync-psn', psnId);
  }

  Future<String> syncXbox(String gamertag) async {
    return await _invokeEdgeFunction('sync-xbox', gamertag);
  }

  Future<String> _invokeEdgeFunction(String action, String providerId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return 'Error: No autenticado';

    try {
      final response = await supabase.functions.invoke('sync-games', body: {
        'action': action,
        'userId': user.id,
        'providerId': providerId
      });

      if (response.status == 200) {
        final logs = (response.data['logs'] as List).join('\n');
        return logs;
      } else {
        return '❌ Error de Servidor: HTTP ${response.status}';
      }
    } catch (e) {
      return '❌ Error Inesperado: $e';
    }
  }
}

extension StringExtension on String {
  String strip() => trim();
}
