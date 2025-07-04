import 'package:flutter/material.dart';

void main() {
  runApp(const IconGeneratorApp());
}

class IconGeneratorApp extends StatelessWidget {
  const IconGeneratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Icon Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const IconGeneratorScreen(),
    );
  }
}

class IconGeneratorScreen extends StatelessWidget {
  const IconGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Icon Preview'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'App Icon Preview',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CustomPaint(
                painter: AppIconPainter(),
                size: const Size(200, 200),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'To generate the actual icon files, run:\n'
              'flutter pub run flutter_launcher_icons',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class AppIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()
      ..color = const Color(0xFF3498DB) // Blue background
      ..style = PaintingStyle.fill;
    
    // Draw circular background
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      backgroundPaint,
    );
    
    // Draw coin shape
    final Paint coinPaint = Paint()
      ..color = const Color(0xFFFFD700) // Gold color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.4,
      coinPaint,
    );
    
    // Draw coin edge
    final Paint coinEdgePaint = Paint()
      ..color = const Color(0xFFDAA520) // Darker gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03;
    
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.4,
      coinEdgePaint,
    );
    
    // Draw graduation cap
    final Paint capPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    // Cap base
    final double capSize = size.width * 0.25;
    final double capTop = size.height * 0.25;
    final double capLeft = size.width * 0.6;
    
    canvas.drawRect(
      Rect.fromLTWH(capLeft - capSize/2, capTop, capSize, capSize * 0.2),
      capPaint,
    );
    
    // Cap top
    final Path capPath = Path();
    capPath.moveTo(capLeft, capTop);
    capPath.lineTo(capLeft - capSize/2, capTop);
    capPath.lineTo(capLeft, capTop - capSize * 0.3);
    capPath.lineTo(capLeft + capSize/2, capTop);
    capPath.close();
    canvas.drawPath(capPath, capPaint);
    
    // Tassel
    final Paint tasselPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02;
    
    canvas.drawLine(
      Offset(capLeft, capTop - capSize * 0.2),
      Offset(capLeft + capSize * 0.3, capTop + capSize * 0.2),
      tasselPaint,
    );
    
    // Draw certificate
    final Paint certPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final Paint certStrokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.01;
    
    final double certWidth = size.width * 0.3;
    final double certHeight = size.width * 0.25;
    final double certLeft = size.width * 0.3;
    final double certTop = size.height * 0.6;
    
    // Certificate background
    canvas.drawRect(
      Rect.fromLTWH(certLeft, certTop, certWidth, certHeight),
      certPaint,
    );
    
    // Certificate border
    canvas.drawRect(
      Rect.fromLTWH(certLeft, certTop, certWidth, certHeight),
      certStrokePaint,
    );
    
    // Certificate lines
    final Paint linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = size.width * 0.005;
    
    for (int i = 1; i <= 3; i++) {
      canvas.drawLine(
        Offset(certLeft + certWidth * 0.1, certTop + certHeight * i * 0.2),
        Offset(certLeft + certWidth * 0.9, certTop + certHeight * i * 0.2),
        linePaint,
      );
    }
    
    // Certificate seal
    final Paint sealPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(certLeft + certWidth * 0.8, certTop + certHeight * 0.8),
      certWidth * 0.1,
      sealPaint,
    );
    
    // Draw "W3" text
    final textStyle = TextStyle(
      color: Colors.black,
      fontSize: size.width * 0.15,
      fontWeight: FontWeight.bold,
    );
    final textSpan = TextSpan(
      text: 'W3',
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height / 2 - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
