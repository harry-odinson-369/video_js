extension ListExtension<T> on List<T> {
  bool isExist(bool Function(T e) check) {
    for (var i in this) {
      if (check(i)) return true;
    }
    return false;
  }
}