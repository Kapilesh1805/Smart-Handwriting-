import 'package:flutter/material.dart';
import '../widgets/auth_card.dart';
import '../widgets/left_panel.dart';
import '../widgets/backend_connection_indicator.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                // Mobile layout - stacked vertically
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      // Backend Connection Indicator
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: const BackendConnectionIndicator(),
                      ),
                      // Left Panel - Auth Card
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        child: const Center(
                          child: AuthCard(),
                        ),
                      ),
                      // Right Panel - Illustration and Branding
                      const LeftPanel(),
                    ],
                  ),
                );
              } else {
                // Desktop layout - side by side
                return Column(
                  children: [
                    // Backend Connection Indicator
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: const BackendConnectionIndicator(),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          // Left Panel - Auth Card
                          Expanded(
                            flex: 1,
                            child: Container(
                              padding: const EdgeInsets.all(40.0),
                              child: const Center(
                                child: AuthCard(),
                              ),
                            ),
                          ),
                          // Right Panel - Illustration and Branding
                          const Expanded(
                            flex: 1,
                            child: LeftPanel(),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
