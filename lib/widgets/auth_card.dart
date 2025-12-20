import 'package:flutter/material.dart';
import 'login_form.dart';
import 'register_form.dart';

class AuthCard extends StatefulWidget {
  const AuthCard({super.key});

  @override
  State<AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isLogin = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
    _animationController.reset();
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: 400.0,
              constraints: const BoxConstraints(
                maxWidth: 400.0,
                maxHeight: 600.0,
                minHeight: 500.0,
              ),
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    const Text(
                      'Welcome',
                      style: TextStyle(
                        fontSize: 32.0,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      'Sign in to continue',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 30.0),
                    
                    // Form - Made scrollable
                    Flexible(
                      child: SingleChildScrollView(
                        child: _isLogin
                            ? LoginForm(
                                onSignUpTap: _toggleAuthMode,
                              )
                            : RegisterForm(
                                onBackTap: _toggleAuthMode,
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 20.0),
                    
                    // Toggle Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin
                              ? "Don't have account? "
                              : "Already have an account? ",
                          style: const TextStyle(
                            color: Color(0xFF2D3748),
                            fontSize: 14.0,
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleAuthMode,
                          child: Text(
                            _isLogin ? 'Create a new account' : 'Sign In',
                            style: const TextStyle(
                              color: Color(0xFF2D3748),
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
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
        );
      },
    );
  }
}