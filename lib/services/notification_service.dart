import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> inicializar() async {
    try {
      // Pede permissão — na web abre o popup do navegador
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('⚠️ Notificações negadas pelo usuário');
        return;
      }

      debugPrint('✅ Permissão: ${settings.authorizationStatus}');

      // Na web precisa passar a chave VAPID
      String? token;
      if (kIsWeb) {
        token = await _messaging.getToken(
          vapidKey: '', // <- USAR CHAVE VAPID DO FIREBASE CONSOLE
        );
      } else {
        token = await _messaging.getToken();
      }

      if (token == null) {
        debugPrint('❌ Token FCM nulo');
        return;
      }

      debugPrint('✅ FCM Token: $token');
      await _salvarToken(token);

      // Atualiza token quando renovado
      _messaging.onTokenRefresh.listen(_salvarToken);

      // Notificação com app em primeiro plano
      FirebaseMessaging.onMessage.listen((message) {
        debugPrint('📬 Mensagem recebida: ${message.notification?.title}');
        // Na web o browser já mostra a notificação pelo Service Worker
        // No mobile mostramos manualmente
        if (!kIsWeb) {
          _mostrarNotificacaoLocal(message);
        }
      });

    } catch (e) {
      debugPrint('❌ Erro no NotificationService: $e');
    }
  }

  Future<void> _salvarToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .update({'fcmToken': token});

    debugPrint('✅ Token salvo no Firestore');
  }

  void _mostrarNotificacaoLocal(RemoteMessage message) {
    // Implementar com flutter_local_notifications para mobile
    debugPrint('📬 ${message.notification?.title}: ${message.notification?.body}');
  }
}