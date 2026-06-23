class ComponentLayout {
  final double width;
  final double height;

  const ComponentLayout({required this.width, required this.height});

  double get aspectRatio => width / height;
}
