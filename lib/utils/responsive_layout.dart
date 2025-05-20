import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  static const mobileWidthBreak = 500.0;
  static const tabletWidthBreak = 905.0;

  const ResponsiveLayout({
    super.key,
    this.mobile,
    this.tablet,
    required this.desktop,
  });

  final Widget? mobile;
  final Widget? tablet;
  final Widget desktop;



  Widget get _tablet => tablet ?? desktop;

  Widget get _desktop => desktop;

  Widget get _mobile => mobile ?? _tablet;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    //final screenHeight = screenSize.height;

    if (screenWidth > tabletWidthBreak) {
      return desktop;
    }
    if (screenWidth > mobileWidthBreak) {
      return _tablet;
    }
    return _mobile;
  }
}
