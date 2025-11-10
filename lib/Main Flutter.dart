import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Festivo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A5EFF),
              Color(0xFF2D3ECC),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Decorative elements
              _buildDecorativeElements(context),
              
              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Profile avatar
                      Image(image: AssetImage('Assets\Logo\LogoAlfa.jpg'), width: 120, height: 120),
                      
                      const SizedBox(height: 60),
                      
                      // Login title
                      const Text(
                        'Login:',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Google login button
                      _buildLoginButton(
                        icon: Icons.search,
                        text: 'Login com Google',
                        onPressed: () {},
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Email login button
                      _buildLoginButton(
                        icon: Icons.email_outlined,
                        text: 'Login com E-mail',
                        onPressed: () {},
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Register title
                      const Text(
                        'Cadastre-se:',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Register button
                      _buildLoginButton(
                        icon: Icons.email_outlined,
                        text: 'Cadastre-se com E-mail',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withAlpha(230), // 0.9 opacity
          foregroundColor: Colors.black87,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeElements(BuildContext context) {
    return Stack(
      children: [
        // Top left decorations
        Positioned(
          top: 20,
          left: 20,
          child: SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                _buildBalloon(Colors.cyan, -10, -5),
                _buildBalloon(Colors.yellow, 15, -10),
                _buildBalloon(Colors.pink, 5, 15),
              ],
            ),
          ),
        ),
        
        // Top right decorations
        Positioned(
          top: 30,
          right: 20,
          child: SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              children: [
                _buildConfetti(Colors.pink, 0, 0),
                _buildConfetti(Colors.cyan, 15, 5),
                _buildConfetti(Colors.yellow, -5, 10),
              ],
            ),
          ),
        ),
        
        // Bottom left character
        Positioned(
          bottom: 40,
          left: 30,
          child: _buildCharacter(Colors.orange, Colors.blue),
        ),
        
        // Bottom right character
        Positioned(
          bottom: 40,
          right: 30,
          child: _buildCharacter(Colors.yellow, Colors.orange),
        ),
        
        // Right side party hat
        Positioned(
          right: 10,
          top: MediaQuery.of(context).size.height * 0.4,
          child: Transform.rotate(
            angle: 0.3,
            child: _buildPartyHat(),
          ),
        ),
        
        // Scattered dots
        ..._buildScatteredDots(),
      ],
    );
  }

  Widget _buildBalloon(Color color, double dx, double dy) {
    return Positioned(
      left: 15 + dx,
      top: 15 + dy,
      child: Container(
        width: 20,
        height: 25,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildConfetti(Color color, double dx, double dy) {
    return Positioned(
      left: 20 + dx,
      top: 20 + dy,
      child: Transform.rotate(
        angle: 0.5,
        child: Container(
          width: 8,
          height: 15,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ), 
      ),
    );
  }

  Widget _buildCharacter(Color shirtColor, Color pantsColor) {
    return SizedBox(
      width: 50,
      height: 70,
      child: Column(
        children: [
          // Head
          Container(
            width: 25,
            height: 25,
            decoration: const BoxDecoration(
              color: Color(0xFFFFDBAE),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 2),
          // Body
          Container(
            width: 30,
            height: 25,
            decoration: BoxDecoration(
              color: shirtColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 2),
          // Legs
          Container(
            width: 25,
            height: 16,
            decoration: BoxDecoration(
              color: pantsColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartyHat() {
    return SizedBox(
      width: 40,
      height: 50,
      child: CustomPaint(
        painter: PartyHatPainter(),
      ),
    );
  }

  List<Widget> _buildScatteredDots() {
    return [
      Positioned(top: 100, left: 50, child: _buildDot(Colors.yellow, 4)),
      Positioned(top: 150, right: 80, child: _buildDot(Colors.pink, 3)),
      Positioned(top: 200, left: 80, child: _buildDot(Colors.cyan, 5)),
      Positioned(bottom: 200, right: 60, child: _buildDot(Colors.green, 4)),
      Positioned(bottom: 150, left: 100, child: _buildDot(Colors.orange, 3)),
      Positioned(top: 250, right: 40, child: _buildDot(Colors.purple, 4)),
    ];
  }

  Widget _buildDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class PartyHatPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Add stripes
    final stripePaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.8, size.height * 0.6),
      stripePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.8),
      Offset(size.width * 0.7, size.height * 0.8),
      stripePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
