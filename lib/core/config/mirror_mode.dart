enum MirrorMode {
  none,
  vertical,
  horizontal,
  both;

  bool get hasVertical => this == vertical || this == both;
  bool get hasHorizontal => this == horizontal || this == both;
  bool get isActive => this != none;
}
