import 'package:flutter/material.dart';

class LeftPanel extends StatelessWidget {
  const LeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(60.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // FLOE Logo - Using image asset
          _buildFloeLogo(),
          const SizedBox(height: 8.0),
          
          // Graphics Tablet Illustration - Using image asset
          _buildGraphicsTablet(),
        ],
      ),
    );
  }

  Widget _buildFloeLogo() {
    // Use fixed size that you preferred earlier; tablet will sit just below
    return Image.asset(
      'assets/images/floe_logo.png',
      width: 560.0,
      height: 220.0,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackFloeLogo();
      },
    );
  }

  Widget _buildFallbackFloeLogo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Custom F with integrated pencil design
        Stack(
          children: [
            const Text(
              'F',
              style: TextStyle(
                fontSize: 120.0,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
                fontFamily: 'serif',
                height: 0.9,
              ),
            ),
            // Pencil line integrated into F
            Positioned(
              right: -15.0,
              top: 15.0,
              child: Container(
                width: 2.0,
                height: 40.0,
                color: Colors.orange[600],
                transform: Matrix4.rotationZ(0.3),
              ),
            ),
          ],
        ),
        const Text(
          'L',
          style: TextStyle(
            fontSize: 120.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
            fontFamily: 'serif',
            height: 0.9,
          ),
        ),
        // Orange circle for O
        Container(
          width: 80.0,
          height: 80.0,
          decoration: BoxDecoration(
            color: Colors.orange[600],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 2.0,
              height: 40.0,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1.0),
              ),
              transform: Matrix4.rotationZ(0.3),
            ),
          ),
        ),
        const Text(
          'E',
          style: TextStyle(
            fontSize: 120.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
            fontFamily: 'serif',
            height: 0.9,
          ),
        ),
      ],
    );
  }

  Widget _buildGraphicsTablet() {
    // Place immediately below the logo with tight spacing and fixed size
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Align(
        alignment: Alignment.topCenter,
        child: Image.asset(
          'assets/images/graphics_tablet.png',
          width: 380.0,
          height: 260.0,
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackGraphicsTablet();
          },
        ),
      ),
    );
  }

  Widget _buildFallbackGraphicsTablet() {
    return Container(
      width: 250.0,
      height: 180.0,
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 25.0,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Tablet surface
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2D3748),
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),
          
          // Side buttons (5 buttons as in reference)
          Positioned(
            left: 12.0,
            top: 30.0,
            child: Column(
              children: List.generate(5, (index) => Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                width: 16.0,
                height: 16.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A5568),
                  borderRadius: BorderRadius.circular(3.0),
                ),
              )),
            ),
          ),
          
          // White dot on tablet surface
          const Positioned(
            left: 50.0,
            top: 60.0,
            child: CircleAvatar(
              radius: 8.0,
              backgroundColor: Colors.white,
            ),
          ),
          
          // Blue dots on tablet surface
          Positioned(
            right: 50.0,
            top: 70.0,
            child: Row(
              children: [
                Container(
                  width: 6.0,
                  height: 6.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFF63B3ED),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4.0),
                Container(
                  width: 6.0,
                  height: 6.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFF63B3ED),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4.0),
                Container(
                  width: 6.0,
                  height: 6.0,
                  decoration: const BoxDecoration(
                    color: Color(0xFF63B3ED),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          
          // FLOE logo on tablet
          const Positioned(
            bottom: 12.0,
            left: 12.0,
            child: Text(
              'FLOE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
          
          // Stylus
          Positioned(
            right: 30.0,
            top: 40.0,
            child: Transform.rotate(
              angle: -0.4,
              child: Container(
                width: 80.0,
                height: 10.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF2D3748),
                  borderRadius: BorderRadius.circular(5.0),
                ),
                child: Stack(
                  children: [
                    // Stylus tip
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Container(
                        width: 10.0,
                        height: 10.0,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    // Stylus buttons
                    Positioned(
                      right: 12.0,
                      top: 3.0,
                      child: Row(
                        children: [
                          Container(
                            width: 5.0,
                            height: 5.0,
                            decoration: const BoxDecoration(
                              color: Color(0xFF63B3ED),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 3.0),
                          Container(
                            width: 5.0,
                            height: 5.0,
                            decoration: const BoxDecoration(
                              color: Color(0xFF63B3ED),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}