import 'dart:io' show Platform;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_ui_oauth_oidc/firebase_ui_oauth_oidc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'details_snap.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'l10n/app_localizations.dart';
import 'oidc_eduid.dart';
import 'profile/custom_profile_screen.dart';
import 'settings.dart';
import 'settings_provider.dart';
import 'take_snap.dart';
import 'widgets.dart';

var settingsStateProvider = SettingsState();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await settingsStateProvider.init();

  if (!kIsWeb && !Platform.isWindows) {
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    FirebaseAnalytics.instance;
  }
  FirebaseMessaging.instance;

  // await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  FirebaseUIAuth.configureProviders([
    GoogleProvider(clientId: GOOGLE_CLIENT_ID),
    OidcProvider(providerId: 'oidc.eduid', style: const EduidButtonStyle()),
    EmailAuthProvider(),

    // ... other providers
  ]);

  runApp(MyApp());
}

final _parentKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  MyApp({super.key});

// GoRouter configuration
  final _router = GoRouter(
    navigatorKey: _parentKey,
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    redirect: (context, state) {
      final auth = FirebaseAuth.instance;
      if (state.fullPath != null &&
          state.fullPath!.contains('/forgot-password')) {
        return null;
      }

      if (auth.currentUser == null) {
        return '/login';
      }

      if (!auth.currentUser!.emailVerified && auth.currentUser!.email != null) {
        return '/verify-email';
      }

      return null;
    },
    routes: [
      GoRoute(
          name: 'login',
          path: '/login',
          builder: (context, state) {
            // hack to fix ui link color
            final originalTheme = Theme.of(context);
            return Theme(
              data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context)
                      .colorScheme
                      .copyWith(primary: Colors.blue)),
              child: SignInScreen(
                sideBuilder: (context, constraints) =>
                    Theme(data: originalTheme, child: const Logo()),
                headerBuilder: (context, constraints, shrinkOffset) =>
                    Theme(data: originalTheme, child: const Logo()),
                actions: [
                  ForgotPasswordAction((context, email) {
                    final uri = Uri(
                      path: '/forgot-password',
                      queryParameters: <String, String?>{
                        'email': email,
                      },
                    );
                    // push required because ui auth does pop()
                    context.push(uri.toString());
                  }),
                  AuthStateChangeAction<SignedIn>((context, state) {
                    if (!state.user!.emailVerified) {
                      context.go('/verify-email');
                    } else {
                      context.go('/');
                    }
                  }),
                ],
                subtitleBuilder: (context, action) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      action == AuthAction.signIn
                          ? 'Welcome to Firebase UI! Please sign in to continue.'
                          : 'Welcome to Firebase UI! Please create an account to continue',
                    ),
                  );
                },
                footerBuilder: (context, action) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        action == AuthAction.signIn
                            ? 'By signing in, you agree to our terms and conditions.'
                            : 'By registering, you agree to our terms and conditions.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
      GoRoute(
          name: 'verify-email',
          path: '/verify-email',
          builder: (context, state) {
            return EmailVerificationScreen(
              actions: [
                EmailVerifiedAction(() {
                  context.go('/profile');
                }),
                AuthCancelledAction((context) {
                  FirebaseUIAuth.signOut(context: context);
                  context.go('/');
                }),
              ],
            );
          }),
      GoRoute(
        name: 'forgot-password',
        path: '/forgot-password',
        builder: (context, state) {
          final arguments = state.uri.queryParameters;
          return ForgotPasswordScreen(
            email: arguments['email'],
            headerMaxExtent: 200,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ScaffoldBottomNavigationBar(
              navigationShell: navigationShell,
            );
          },
          branches: <StatefulShellBranch>[
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  name: 'home',
                  path: '/',
                  builder: (context, state) {
                    return const MyHomePage(title: 'Snap!');
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  name: 'take-snap',
                  path: '/snap',
                  builder: (context, state) {
                    return const TakeSnapScreen();
                  },
                ),
              ],
            ),
            StatefulShellBranch(
              routes: <RouteBase>[
                GoRoute(
                  name: 'profile',
                  path: '/profile',
                  builder: (context, state) {
                    return CustomProfileScreen(
                      appBar: AppBar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        title: Text(AppLocalizations.of(context)!.account,
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onPrimary)),
                      ),
                      actions: [
                        SignedOutAction((context) {
                          context.go('/');
                        }),
                      ],
                      children: [
                        // spacing trick
                        const SizedBox(height: 20),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () {
                            if (kIsWeb) {
                              context.go('/settings');
                            } else {
                              context.push('/settings');
                            }
                          },
                          child: Text(
                            AppLocalizations.of(context)!.settings,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        )
                      ],
                    );
                  },
                ),
              ],
            ),
          ]),
      GoRoute(
          name: 'snap-detail',
          path: '/snap/:id',
          // fix bug where the navbar is not hidden
          parentNavigatorKey: _parentKey,
          builder: (context, state) {
            return DetailSnapScreen(
                id: state.pathParameters['id']!, data: state.extra);
          }),
      GoRoute(
          name: 'settings',
          path: '/settings',
          parentNavigatorKey: _parentKey,
          builder: (context, state) {
            return const SettingsScreen();
          }),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final darkScheme = ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 7, 31, 50),
            brightness: Brightness.dark)
        .copyWith(
            primary: const Color.fromARGB(255, 7, 31, 50),
            onPrimary: const Color.fromARGB(255, 196, 196, 196));

    return ChangeNotifierProvider(
      create: (context) => settingsStateProvider,
      // need to use builder to get a context which is below the provider
      child: Builder(builder: (context) {
        final settings = context.watch<SettingsState>();
        return MaterialApp.router(
          title: 'Snap!',
          locale: settings.locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FirebaseUILocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('fr'),
          ],
          theme: ThemeData(
            fontFamily: GoogleFonts.barlow().fontFamily,
            colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue, brightness: Brightness.light),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            fontFamily: GoogleFonts.barlow().fontFamily,
            colorScheme: darkScheme,
            // fix auth ui in dark mode
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: darkScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: darkScheme.onPrimary,
                ),
              ),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              labelStyle: const TextStyle(color: Colors.white),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: ButtonStyle(
                padding: WidgetStateProperty.all<EdgeInsets>(
                  const EdgeInsets.all(16),
                ),
                shape: WidgetStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                backgroundColor:
                    WidgetStateProperty.all<Color>(darkScheme.primary),
                foregroundColor:
                    WidgetStateProperty.all<Color>(darkScheme.onPrimary),
              ),
            ),
            useMaterial3: true,
          ),
          themeMode: settings.themeMode,
          routerConfig: _router,
        );
      }),
    );
  }
}

class ScaffoldBottomNavigationBar extends StatelessWidget {
  const ScaffoldBottomNavigationBar({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final navBar = BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Snap!'),
        BottomNavigationBarItem(
            icon: const Icon(Icons.camera_alt),
            label: AppLocalizations.of(context)!.take),
        BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.account),
      ],
      currentIndex: navigationShell.currentIndex,
      onTap: (tappedIndex) {
        navigationShell.goBranch(tappedIndex);
      },
    );

    final navRail = NavigationRail(
      destinations: [
        const NavigationRailDestination(
            icon: Icon(Icons.home), label: Text('Snap!')),
        NavigationRailDestination(
            icon: const Icon(Icons.camera_alt),
            label: Text(AppLocalizations.of(context)!.take)),
        NavigationRailDestination(
            icon: const Icon(Icons.person),
            label: Text(AppLocalizations.of(context)!.account)),
      ],
      labelType: NavigationRailLabelType.all,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        navigationShell.goBranch(index);
      },
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 800) {
        return Scaffold(body: navigationShell, bottomNavigationBar: navBar);
      } else {
        return SafeArea(
          child: Scaffold(
              body: Row(
            children: [
              navRail,
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: navigationShell),
            ],
          )),
        );
      }
    });
  }
}
