import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileBody;
  final Widget desktopBody;

  const ResponsiveLayout({
    super.key,
    required this.mobileBody,
    required this.desktopBody,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Se a largura for menor que 800px, usa o layout Mobile
        if (constraints.maxWidth < 800) {
          return mobileBody;
        } else {
          // Caso contrário, usa o layout Desktop
          return desktopBody;
        }
      },
    );
  }
}