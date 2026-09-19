import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> inicializar() async {
    // Pede permissão ao usuário
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Configura notificações locais (Android)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    // Salva o token FCM do dispositivo no Firestore
    await _salvarToken();

    // Atualiza o token quando ele for renovado
    _messaging.onTokenRefresh.listen(_atualizarToken);

    // Notificação recebida com app em primeiro plano
    FirebaseMessaging.onMessage.listen(_mostrarNotificacaoLocal);

    // Notificação clicada com app em segundo plano
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificacaoAberta);
  }

  Future<void> _salvarToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final token = await _messaging.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .update({'fcmToken': token});

    debugPrint('✅ FCM Token salvo: $token');
  }

  Future<void> _atualizarToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .update({'fcmToken': token});
  }

  Future<void> _mostrarNotificacaoLocal(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'atividades_channel',
      'Atividades',
      channelDescription: 'Notificações de novas atividades',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFF8B0000),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  void _onNotificacaoAberta(RemoteMessage message) {
    // TODO: navegar para a tela da atividade
    debugPrint('Notificação aberta: ${message.data}');
  }
}