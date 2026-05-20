library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'i18n/locale_controller.dart';
import 'theme/theme_controller.dart';
import '../presentation/widgets/offline_banner.dart';
import '../features/splash/presentation/app_splash_screen.dart';

class CisnetKidsApp extends StatelessWidget {
  const CisnetKidsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          LocaleController.instance,
          ThemeController.instance,
        ]),
        builder: (context, _) => MaterialApp(
          title: 'TEKISA',
          debugShowCheckedModeBanner: false,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: ThemeController.instance.themeMode,
          locale: LocaleController.instance.locale.languageCode == 'ln'
              ? const Locale('fr')
              : LocaleController.instance.locale,
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            final theme = Theme.of(context);
            final media = MediaQuery.of(context);
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: theme.brightness == Brightness.dark
                      ? const [Color(0xFF0A1220), Color(0xFF111C2F)]
                      : const [Color(0xFFF8FBFF), Color(0xFFEFF4FA)],
                ),
              ),
              child: MediaQuery(
                data: media.copyWith(textScaler: const TextScaler.linear(0.99)),
                child: OfflineAwareShell(
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            );
          },
          home: const AppSplashGate(),
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    const colorScheme = ColorScheme.light(
      primary: Color(0xFF035D8A),
      onPrimary: Colors.white,
      secondary: Color(0xFF6E7F8D),
      onSecondary: Colors.white,
      surface: Color(0xFFF1F5F9),
      onSurface: Color(0xFF1F2933),
      error: Color(0xFFDC2626),
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF4F8FD),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineMedium: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 24,
          height: 1.2,
          color: Color(0xFF111827),
        ),
        titleLarge: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          height: 1.25,
          color: Color(0xFF111827),
        ),
        titleMedium: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          height: 1.3,
          color: Color(0xFF111827),
        ),
        bodyMedium: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
          height: 1.35,
          color: Color(0xFF111827),
        ),
        bodySmall: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
          height: 1.35,
          color: Color(0xFF6B7280),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFFFFFFF).withValues(alpha: 0.92),
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFF373A3C),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF111827),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFF3F8FF),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0.2,
          minimumSize: const Size.fromHeight(44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.78),
          foregroundColor: const Color(0xFF111827),
          elevation: 0.1,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1F2933),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.95),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF035D8A), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.96),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.78),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.16),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF6B7280)),
      dividerColor: const Color(0xFFDCE5EF),
    );
  }

  ThemeData _buildDarkTheme() {
    const colorScheme = ColorScheme.dark(
      primary: Color(0xFF57A6D1),
      onPrimary: Color(0xFF02141F),
      secondary: Color(0xFF9CA3AF),
      onSecondary: Color(0xFF0B1116),
      surface: Color(0xFF1B2A3D),
      onSurface: Color(0xFFE5E7EB),
      error: Color(0xFFF87171),
      onError: Color(0xFF140809),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0B1220),
      textTheme:
          GoogleFonts.interTextTheme(
            ThemeData(brightness: Brightness.dark).textTheme,
          ).copyWith(
            headlineMedium: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 24,
              height: 1.2,
              color: Color(0xFFF3F4F6),
            ),
            titleLarge: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              height: 1.25,
              color: Color(0xFFF3F4F6),
            ),
            titleMedium: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              height: 1.3,
              color: Color(0xFFE5E7EB),
            ),
            bodyMedium: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
              height: 1.35,
              color: Color(0xFFE5E7EB),
            ),
            bodySmall: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 1.35,
              color: Color(0xFF9CA3AF),
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F172A).withValues(alpha: 0.92),
        scrolledUnderElevation: 0,
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFFFFF),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1A2E45).withValues(alpha: 0.94),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: const Color(0xFF02141F),
          elevation: 0,
          minimumSize: const Size.fromHeight(44),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF22354D).withValues(alpha: 0.78),
          foregroundColor: const Color(0xFFFFFFFF),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFFFFFF),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E3148).withValues(alpha: 0.78),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF57A6D1), width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF1B2A3D).withValues(alpha: 0.82),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E3148).withValues(alpha: 0.78),
        indicatorColor: colorScheme.primary.withValues(alpha: 0.18),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF9CA3AF)),
      dividerColor: const Color(0xFF1F2937),
    );
  }
}
