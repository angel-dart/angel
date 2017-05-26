import 'package:angel_framework/angel_framework.dart';
import 'angel_paginate.dart';
export 'angel_paginate.dart';

/// Paginates the results of service events.
///
/// Users can add a `page` to the query to display a certain page, i.e. `http://foo.com/api/todos?page=5`.
///
/// Users can also add a `$limit` to the query to display more or less items than specified in [itemsPerPage] (default: `5`).
/// If [maxItemsPerPage] is set, then even if the query contains a `$limit` parameter, it will be limited to the maximum.
HookedServiceEventListener paginate<T>(
    {int itemsPerPage, int maxItemsPerPage}) {
  return (HookedServiceEvent e) {
    if (e.isBefore) throw new UnsupportedError(
        '`package:angel_paginate` can only be run as an after hook.');
    if (e.result is! Iterable) return;

    int page = 0,
        nItems = itemsPerPage;

    if (e.params.containsKey('query') && e.params['query'] is Map) {
      var query = e.params['query'] as Map;

      if (query.containsKey('page')) {
        try {
          page = int.parse(query['page']?.toString());
        } catch (e) {
          // Fail silently...
        }
      }

      if (query.containsKey(r'$limit')) {
        try {
          var lim = int.parse(query[r'$limit']?.toString());
          if (lim > 0 && (maxItemsPerPage == null || lim <= maxItemsPerPage))
            nItems = lim;
        } catch (e) {
          // Fail silently...
        }
      }
    }


    var paginator = new Paginator(
        e.result, itemsPerPage: nItems)
      ..goToPage(page);
    e.result = paginator.current;
  };
}