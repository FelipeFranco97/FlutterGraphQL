import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
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

  String selectedYear = '1950';
  int round = 0;

  List<String> years = [for (var i = 1950; i <= 2023; i += 1) '$i'];

  late Future<Database> database;

  @override
  void initState() {
    super.initState();
    initDatabase();
  }

  Future<void> initDatabase() async {
    database = openDatabase(
      join(await getDatabasesPath(), 'drivers_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE drivers(year TEXT, name TEXT, nationality TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<void> insertDriver(Map<String, dynamic> driver) async {
    final Database db = await database;

    await db.insert(
      'drivers',
      driver,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getDrivers() async {
    final Database db = await database;
    return await db.query('drivers');
  }

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
                    DropdownButton<String>(
                      value: selectedYear,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedYear = newValue!;
                        });
                      },
                      items: years.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          isLoading = true;
                        });

                        final HttpLink httpLink = HttpLink(
                            'https://rest-to-graphql-api-f1.vercel.app/graphql');

                        final GraphQLClient client = GraphQLClient(
                          link: httpLink,
                          cache: GraphQLCache(),
                        );

                        final QueryResult result = await client.query(
                          QueryOptions(
                            document: gql(getF1Query),
                            variables: {
                              'year': selectedYear,
                              'round': 1,
                            },
                          ),
                        );

                        setState(() {
                          isLoading = false;
                          drivers = result.data!['driversYearAndRound'];
                          showButton = false;

                          for (var driver in drivers) {
                            insertDriver({
                              'year': selectedYear,
                              'name': driver['name'],
                              'nationality': driver['nationality'],
                            });
                          }
                        });
                      },
                      child: const Text('Continuar'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final driversFromDb = await getDrivers();

                        if (mounted) {
                          showDialog(
                            // ignore: use_build_context_synchronously
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Información DB'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  height:
                                      MediaQuery.of(context).size.height * 0.7,
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 1,
                                      mainAxisSpacing: 3,
                                      crossAxisSpacing: 3,
                                      childAspectRatio:
                                          5,
                                    ),
                                    itemCount: driversFromDb.length,
                                    itemBuilder: (context, index) {
                                      final driver = driversFromDb[index];
                                      return Row(
                                        children: [
                                          Expanded(
                                            child:
                                                Text('${driver['year']}'),
                                          ),
                                          Expanded(
                                            child: Text(
                                                '${driver['name']}'),
                                          ),
                                          Expanded(
                                            child: Text(
                                                '${driver['nationality']}'),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    child: const Text('Cerrar'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      },
                      child: const Text('Consulta'),
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
            if (!showButton)
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showButton = true;
                    drivers.clear();
                  });
                },
                child: const Text('Regresar para elegir otro año'),
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
