import 'package:angel_framework/angel_framework.dart';
import 'package:http_parser/http_parser.dart';

/// Returns a simple [RequestHandler] that renders the GraphiQL visual interface for GraphQL.
///
/// By default, the interface expects your backend to be mounted at `/graphql`; this is configurable
/// via [graphQLEndpoint].
RequestHandler graphiQL(
    {String graphQLEndpoint = '/graphql', String subscriptionsEndpoint}) {
  return (req, res) {
    res
      ..contentType = MediaType('text', 'html')
      ..write(renderGraphiql(
          graphqlEndpoint: graphQLEndpoint,
          subscriptionsEndpoint: subscriptionsEndpoint))
      ..close();
  };
}

String renderGraphiql(
    {String graphqlEndpoint = '/graphql', String subscriptionsEndpoint}) {
  var subscriptionsScripts = '',
      subscriptionsFetcher = '',
      fetcherName = 'graphQLFetcher';

  if (subscriptionsEndpoint != null) {
    fetcherName = 'subscriptionsFetcher';
    subscriptionsScripts = '''
  <script src="//unpkg.com/subscriptions-transport-ws@0.8.3/browser/client.js"></script>
  <script src="//unpkg.com/graphiql-subscriptions-fetcher@0.0.2/browser/client.js"></script>
  ''';
    subscriptionsFetcher = '''
  let subscriptionsClient = window.SubscriptionsTransportWs.SubscriptionClient('$subscriptionsEndpoint', {
    reconnect: true
  });
  let $fetcherName = window.GraphiQLSubscriptionsFetcher.graphQLFetcher(subscriptionsClient, graphQLFetcher);
  ''';
  }

  return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Angel GraphQL</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/graphiql/0.11.11/graphiql.min.css">
    <style>
        html, body {
            margin: 0;
            padding: 0;
        }
        html, body, #app {
            height: 100%;
        }
    </style>
</head>
<body>
<div id="app"></div>
<script src="https://cdnjs.cloudflare.com/ajax/libs/react/16.2.0/umd/react.production.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/react-dom/16.2.0/umd/react-dom.production.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/fetch/2.0.3/fetch.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/graphiql/0.11.11/graphiql.js"></script>
$subscriptionsScripts
<script>
    window.onload = function() {
        function graphQLFetcher(graphQLParams) {
            return fetch('$graphqlEndpoint', {
                method: 'post',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(graphQLParams)
            }).then(function(response) {
                return response.json();
            });
        }
        $subscriptionsFetcher
        ReactDOM.render(
            React.createElement(
                GraphiQL,
                {fetcher: $fetcherName}
            ),
            document.getElementById('app')
        );
    };
</script>
</body>
</html>
'''
      .trim();
}
