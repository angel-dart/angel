/// Efficiently paginates collections of items in an object-oriented manner.
class Paginator<T> {
  final Map<int, PaginationResult<T>> _cache = {};
  PaginationResult<T> _current;
  int _page = 0;

  /// The collection of items to be paginated.
  final Iterable<T> _items;

  /// The maximum number of items to be shown per page.
  final int itemsPerPage;

  /// If `true` (default), then the results of paginations will be saved by page number.
  ///
  /// For example, you would only have to paginate page 1 once. Future calls would return a cached version.
  final bool useCache;

  Paginator(this._items, {this.itemsPerPage: 5, this.useCache: true});

  /// Returns `true` if there are more items at lesser page indices than the current one.
  bool get canGoBack => _page > 0;

  /// Returns `true` if there are more items at greater page indices than the current one.
  bool get canGoForward => _page < _lastPage();

  /// The current page index.
  int get index => _page;

  /// Returns the greatest possible page number for this collection, given the number of [itemsPerPage].
  int get lastPageNumber => _lastPage();

  /// The current page number. This is not the same as [index].
  ///
  /// This getter will return user-friendly numbers. The lowest value it will ever return is `1`.
  int get pageNumber => _page < 1 ? 1 : (_page + 1);

  /// Fetches the current page. This will be cached until [back] or [next] is called.
  ///
  /// If [useCache] is `true` (default), then computations will be cached even after the page changes.
  PaginationResult<T> get current {
    if (_current != null)
      return _current;
    else
      return _current = _getPage();
  }

  PaginationResult<T> _computePage() {
    var len = _items.length;
    var it = _items.skip(_page * (itemsPerPage ?? 5));
    var offset = len - it.length;
    it = it.take(itemsPerPage);
    var last = _lastPage();
    // print('cur: $_page, last: $last');
    return new _PaginationResultImpl(it,
        currentPage: _page + 1,
        previousPage: _page <= 0 ? -1 : _page,
        nextPage: _page >= last - 1 ? -1 : _page + 2,
        startIndex: it.isEmpty ? -1 : offset,
        endIndex: offset + it.length - 1,
        itemsPerPage:
            itemsPerPage < _items.length ? itemsPerPage : _items.length,
        total: len);
  }

  PaginationResult<T> _getPage() {
    if (useCache != false)
      return _cache.putIfAbsent(_page, () => _computePage());
    else
      return _computePage();
  }

  int _lastPage() {
    var n = (_items.length / itemsPerPage).round();
    // print('items: ${_items.length}');
    // print('per page: $itemsPerPage');
    // print('quotient: $n');
    var remainder = _items.length - (n * itemsPerPage);
    // print('remainder: $remainder');
    return (remainder <= 0) ? n : n + 1;
  }

  /// Attempts to go the specified page. If it fails, then it will remain on the current page.
  ///
  /// Keep in mind - this just not be a zero-based index, but a one-based page number. The lowest
  /// allowed value is `1`.
  void goToPage(int page) {
    if (page > 0 && page <= _lastPage()) {
      _page = page - 1;
      _current = null;
    }
  }

  /// Moves the paginator back one page, if possible.
  void back() {
    if (_page > 0) {
      _page--;
      _current = null;
    }
  }

  /// Advances the paginator one page, if possible.
  void next() {
    if (_page < _lastPage()) {
      _page++;
      _current = null;
    }
  }
}

/// Stores the result of a pagination.
abstract class PaginationResult<T> {
  factory PaginationResult.fromMap(Map<String, dynamic> map) =>
      new _PaginationResultImpl((map['data'] as Iterable).cast<T>(),
          currentPage: map['current_page'],
          endIndex: map['end_index'],
          itemsPerPage: map['items_per_page'],
          nextPage: map['next_page'],
          previousPage: map['previous_page'],
          startIndex: map['start_index'],
          total: map['total']);

  List<T> get data;

  int get currentPage;

  int get previousPage;

  int get nextPage;

  int get itemsPerPage;

  int get total;

  int get startIndex;

  int get endIndex;

  Map<String, dynamic> toJson();
}

class _PaginationResultImpl<T> implements PaginationResult<T> {
  final Iterable<T> _data;
  Iterable<T> _cachedData;

  @override
  final int currentPage;

  _PaginationResultImpl(this._data,
      {this.currentPage,
      this.endIndex,
      this.itemsPerPage,
      this.nextPage,
      this.previousPage,
      this.startIndex,
      this.total});

  @override
  List<T> get data => _cachedData ?? (_cachedData = new List<T>.from(_data));

  @override
  final int endIndex;

  @override
  final int itemsPerPage;

  @override
  final int nextPage;

  @override
  final int previousPage;

  @override
  final int startIndex;

  @override
  final int total;

  @override
  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'items_per_page': itemsPerPage,
      'previous_page': previousPage,
      'current_page': currentPage,
      'next_page': nextPage,
      'start_index': startIndex,
      'end_index': endIndex,
      'data': data
    };
  }
}
