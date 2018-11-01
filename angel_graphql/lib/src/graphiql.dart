import 'package:angel_framework/angel_framework.dart';
import 'package:http_parser/http_parser.dart';

/// Returns a simple [RequestHandler] that renders the GraphiQL visual interface for GraphQL.
///
/// By default, the interface expects your backend to be mounted at `/graphql`; this is configurable
/// via [graphQLEndpoint].
RequestHandler graphiQL({String graphQLEndpoint: '/graphql'}) {
  return (req, res) {
    res
      ..contentType = new MediaType('text', 'html')
      ..write(renderGraphiql(graphqlEndpoint: graphQLEndpoint))
      ..close();
  };
}

String renderGraphiql({String graphqlEndpoint: '/graphql'}) {
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
        ReactDOM.render(
            React.createElement(
                GraphiQL,
                {fetcher: graphQLFetcher}
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
