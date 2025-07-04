import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final bool showText;
  final double size;
  final Color? color;

  const AppLogo({
    super.key,
    this.showText = false,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoColor = color ?? theme.colorScheme.primary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Web3 Content Management logo
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // Outer nodes
              Positioned(
                left: 0,
                top: 0,
                child: Icon(
                  Icons.circle_outlined,
                  size: size * 0.4,
                  color: logoColor,
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Icon(
                  Icons.circle_outlined,
                  size: size * 0.4,
                  color: logoColor,
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: Icon(
                  Icons.circle_outlined,
                  size: size * 0.4,
                  color: logoColor,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Icon(
                  Icons.circle_outlined,
                  size: size * 0.4,
                  color: logoColor,
                ),
              ),
              // Connection lines
              CustomPaint(
                size: Size(size, size),
                painter: NetworkLinesPainter(color: logoColor),
              ),
              // Center node with "3"
              Center(
                child: Container(
                  width: size * 0.5,
                  height: size * 0.5,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: logoColor,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '3',
                      style: TextStyle(
                        color: logoColor,
                        fontSize: size * 0.3,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            'W3CM',
            style: TextStyle(
              color: logoColor,
              fontSize: size * 0.8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

class NetworkLinesPainter extends CustomPainter {
  final Color color;

  NetworkLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final nodeRadius = size.width * 0.2;

    // Draw lines from center to corners
    canvas.drawLine(
      Offset(nodeRadius, nodeRadius), // Top-left
      Offset(centerX, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - nodeRadius, nodeRadius), // Top-right
      Offset(centerX, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(nodeRadius, size.height - nodeRadius), // Bottom-left
      Offset(centerX, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - nodeRadius, size.height - nodeRadius), // Bottom-right
      Offset(centerX, centerY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
