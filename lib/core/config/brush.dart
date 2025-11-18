enum BrushStyle {
  thin(2.0, 'Thin'),
  medium(4.0, 'Medium'),
  thick(8.0, 'Thick'),
  xtraThick(12.0, 'Extra Thick'),
  dotted(3.0, 'Dotted');

  const BrushStyle(this.width, this.name);
  final double width;
  final String name;
}
