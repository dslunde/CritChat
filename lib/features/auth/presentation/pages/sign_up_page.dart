import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../forms/email_input.dart';
import '../forms/password_input.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_button.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  EmailInput _email = const EmailInput.pure();
  PasswordInput _password = const PasswordInput.pure();
  PasswordInput _confirmPassword = const PasswordInput.pure();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    setState(() {
      _email = EmailInput.dirty(_emailController.text);
    });
  }

  void _onPasswordChanged() {
    setState(() {
      _password = PasswordInput.dirty(_passwordController.text);
    });
  }

  void _onConfirmPasswordChanged() {
    setState(() {
      _confirmPassword = PasswordInput.dirty(_confirmPasswordController.text);
    });
  }

  void _onSignUpPressed() {
    setState(() {
      _email = EmailInput.dirty(_emailController.text);
      _password = PasswordInput.dirty(_passwordController.text);
      _confirmPassword = PasswordInput.dirty(_confirmPasswordController.text);
    });

    if (Formz.validate([_email, _password, _confirmPassword]) &&
        _passwordController.text == _confirmPasswordController.text) {
      context.read<AuthBloc>().add(
        AuthSignUpRequested(
          email: _emailController.text,
          password: _passwordController.text,
        ),
      );
    } else if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryColor),
      ),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.errorColor,
                ),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Welcome Text
                  Text(
                    AppStrings.createAccount,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Email Field
                  AuthTextField(
                    controller: _emailController,
                    labelText: AppStrings.email,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _email.displayError?.message,
                    onChanged: (_) => _onEmailChanged(),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  AuthTextField(
                    controller: _passwordController,
                    labelText: AppStrings.password,
                    obscureText: true,
                    errorText: _password.displayError?.message,
                    onChanged: (_) => _onPasswordChanged(),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  AuthTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    obscureText: true,
                    errorText: _confirmPassword.displayError?.message,
                    onChanged: (_) => _onConfirmPasswordChanged(),
                  ),
                  const SizedBox(height: 32),

                  // Sign Up Button
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return AuthButton(
                        text: AppStrings.signUp,
                        onPressed: _onSignUpPressed,
                        isLoading: state is AuthLoading,
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        AppStrings.alreadyHaveAccount,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          AppStrings.signIn,
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
