import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoading = false;
  List<dynamic> drivers = [];
  bool showButton = true;

  String year = "";
  int round = 0;

  final TextEditingController _yearController = TextEditingController();
  //final TextEditingController _roundController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'API con GraphQL',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('API con GraphQL'),
        ),
        body: Column(
          children: [
            Visibility(
              visible: showButton,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: _yearController,
                      decoration: const InputDecoration(
                        labelText: 'Año',
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    /* TextField(
                      controller: _roundController,
                      decoration: const InputDecoration(
                        labelText: 'Ronda',
                      ),
                    ), */
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });
                
                        year = _yearController.text;
                        // round = int.parse(_roundController.text);
                
                        final HttpLink httpLink = HttpLink('https://rest-to-graphql-api-f1.vercel.app/graphql');
                
                        final GraphQLClient client = GraphQLClient(
                          link: httpLink,
                          cache: GraphQLCache(),
                        );
                
                        final QueryResult result = await client.query(
                          QueryOptions(
                            document: gql(getF1Query),
                            variables: {
                              'year': year,
                              'round': 1,
                            },
                          ),
                        );
                
                        setState(() {
                          isLoading = false;
                          drivers = result.data!['driversYearAndRound'];
                          showButton = false;
                        });
                      },
                      child: const Text('Continuar'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            if (isLoading)
              const CircularProgressIndicator()
            else
              Expanded(
                child: ListView.builder(
                  itemCount: drivers.length,
                  itemBuilder: (context, index) {
                    final driver = drivers[index];
                    return ListTile(
                      title: Text('Nombre del piloto: ${driver['name']}'),
                      subtitle: Text('Nacionalidad: ${driver['nationality']}'),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const String getF1Query = '''
query GetDrivers(\$year: String!, \$round: Int!) {
  driversYearAndRound(year: \$year, round: \$round) {
    name
    nationality
  }
}
''';
