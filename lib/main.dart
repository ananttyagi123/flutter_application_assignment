import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'state/claim_store.dart';
import 'ui/screens/claim_detail_screen.dart';
import 'ui/screens/claim_form_screen.dart';
import 'ui/screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClaimApp());
}

class ClaimApp extends StatelessWidget {
  const ClaimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ClaimStore()..init(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Insurance Claims',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
          useMaterial3: true,
        ),
        routes: {
          DashboardScreen.route: (_) => const DashboardScreen(),
          ClaimFormScreen.route: (_) => const ClaimFormScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == ClaimDetailScreen.route) {
            final claimId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => ClaimDetailScreen(claimId: claimId),
            );
          }
          return null;
        },
        initialRoute: DashboardScreen.route,
      ),
    );
  }
}

