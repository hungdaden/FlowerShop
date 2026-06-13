import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'core/router/app_router.dart';
import 'core/services/app_providers.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using the options provided by the user
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyD8aedS6XAJ6--CoMWqWsh2eadVA5tCTW0",
      authDomain: "flowershop-bd3f5.firebaseapp.com",
      projectId: "flowershop-bd3f5",
      storageBucket: "flowershop-bd3f5.firebasestorage.app",
      messagingSenderId: "430075295854",
      appId: "1:430075295854:web:663c140df79ee6b5150e7f",
      measurementId: "G-HKR2P34HLJ",
    ),
  );

  // Retrieve or generate persistent conversation ID for guest users
  final prefs = await SharedPreferences.getInstance();
  String? conversationId = prefs.getString('user_conversation_id');
  if (conversationId == null) {
    conversationId = 'chat_${const Uuid().v4()}';
    await prefs.setString('user_conversation_id', conversationId);
  }

  // Initialize FCM: silently refresh token if permission already granted,
  // and start listening for token changes to keep Firestore in sync.
  final notificationService = NotificationService();
  notificationService.silentTokenRefresh(conversationId);
  notificationService.listenForTokenRefresh(conversationId);

  runApp(MyApp(conversationId: conversationId));
}

class MyApp extends StatelessWidget {
  final String conversationId;
  const MyApp({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CollectionProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider(conversationId)),
        ChangeNotifierProvider(create: (_) => NotificationProvider(conversationId)),
      ],
      child: MaterialApp.router(
        title: 'Flower Shop - Premium Flower Shop',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
