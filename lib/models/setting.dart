class Setting<T> {
  final T current;
  final T defaultValue;
  final bool changed;

  const Setting({
    required this.current,
    required this.defaultValue,
    required this.changed,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Setting<T> &&
        other.current == current &&
        other.defaultValue == defaultValue &&
        other.changed == changed;
  }

  @override
  int get hashCode => Object.hash(current, defaultValue, changed);

  @override
  String toString() =>
      'Setting(current: $current, default: $defaultValue, changed: $changed)';
}
