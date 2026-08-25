import 'dart:math';

/// Hands out items from [items] in random order, guaranteeing every item is
/// used once before any item repeats, and that the last item of one cycle
/// never immediately repeats as the first item of the next cycle.
class ShuffleBag<T> {
  ShuffleBag(this._items) : assert(_items.isNotEmpty);

  final List<T> _items;
  final _random = Random();
  List<T> _bag = [];
  T? _lastDrawn;

  T next() {
    if (_bag.isEmpty) {
      _bag = List<T>.from(_items)..shuffle(_random);
      if (_bag.length > 1 && _bag.last == _lastDrawn) {
        final swapIndex = _random.nextInt(_bag.length - 1);
        final tmp = _bag.last;
        _bag[_bag.length - 1] = _bag[swapIndex];
        _bag[swapIndex] = tmp;
      }
    }
    final item = _bag.removeLast();
    _lastDrawn = item;
    return item;
  }
}
