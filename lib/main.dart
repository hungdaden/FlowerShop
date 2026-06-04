import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/services/app_providers.dart';
import 'core/theme/app_theme.dart';

void main() async {
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CollectionProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
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
