import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/di/injection_container.dart' as di;
import 'core/constants/app_colors.dart';
import 'core/constants/app_strings.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/pages/sign_in_page.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/goodbye_page.dart';
import 'features/auth/presentation/pages/xp_success_page.dart';
import 'features/navigation/main_navigation.dart';
import 'config/local_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Set up local configuration for RAG testing BEFORE dependency injection
  // See config/local_config.dart for setup instructions
  await LocalConfig.setup();
  
  await di.init();
  
  runApp(const CritChatApp());
}

class CritChatApp extends StatelessWidget {
  const CritChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primaryColor),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.primaryColor),
        ),
      ),
      home: BlocProvider(
        create: (context) => di.sl<AuthBloc>()..add(const AuthStarted()),
        child: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthLoading) {
          return const LoadingScreen();
        } else if (state is AuthAuthenticated) {
          if (state.needsOnboarding) {
            return BlocProvider.value(
              value: context.read<AuthBloc>(),
              child: const OnboardingPage(),
            );
          } else {
            return BlocProvider.value(
              value: context.read<AuthBloc>(),
              child: const MainNavigation(),
            );
          }
        } else if (state is AuthOnboardingSuccess) {
          return BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: XpSuccessPage(
              xpAmount: state.xpAmount,
              message: state.message,
            ),
          );
        } else if (state is AuthSigningOut) {
          return BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const GoodbyePage(),
          );
        } else if (state is AuthUnauthenticated) {
          return BlocProvider.value(
            value: context.read<AuthBloc>(),
            child: const SignInPage(),
          );
        } else if (state is AuthError) {
          return ErrorScreen(message: state.message);
        }

        return BlocProvider.value(
          value: context.read<AuthBloc>(),
          child: const SignInPage(),
        );
      },
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.appName,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.errorColor,
              ),
              const SizedBox(height: 20),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthStarted());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
