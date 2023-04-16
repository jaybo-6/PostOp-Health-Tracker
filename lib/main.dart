import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Post-Surgery Health Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const HealthParametersPage(),
    );
  }
}

class HealthParametersPage extends StatelessWidget {
  const HealthParametersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xF2F4F3FF),
      appBar: AppBar(
        title: const Text('Post-Surgery Health Tracker'),
        backgroundColor: const Color(0x22333BFF),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20.0),
            const Text(
              'Log in your health parameters',
              style: TextStyle(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF22333B),
              ),
            ),
            const SizedBox(height: 20.0),
            buildTextField(
              labelText: 'Blood pressure (mmHg)',
              icon: Icons.favorite,
            ),
            const SizedBox(height: 20.0),
            buildTextField(
              labelText: 'Blood oxygen level (SpO2 %)',
              icon: Icons.healing,
            ),
            const SizedBox(height: 20.0),
            buildTextField(
              labelText: 'Blood sugar level (mg/dL)',
              icon: Icons.cake,
            ),
            const SizedBox(height: 20.0),
            buildTextField(
              labelText: 'Walking with step count',
              icon: Icons.directions_walk,
            ),
            const SizedBox(height: 20.0),
            buildTextField(
              labelText: 'Date (MM/DD/YYYY)',
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 20.0),
            buildTextField(
              labelText: 'Duration (minutes)',
              icon: Icons.timer,
            ),
            const SizedBox(height: 40.0),
            ElevatedButton(
              onPressed: () async {
                final bloodPressure =
                    double.parse(_bloodPressureController.text);
                final bloodOxygen = double.parse(_bloodOxygenController.text);
                final bloodSugar = double.parse(_bloodSugarController.text);
                final steps = int.parse(_stepsController.text);
                final duration = int.parse(_durationController.text);

                Map<String, dynamic> row = {
                  DatabaseHelper.columnDate: DateTime.now().toString(),
                  DatabaseHelper.columnBloodPressure: bloodPressure,
                  DatabaseHelper.columnBloodOxygen: bloodOxygen,
                  DatabaseHelper.columnBloodSugar: bloodSugar,
                  DatabaseHelper.columnSteps: steps,
                  DatabaseHelper.columnDuration: duration,
                };

                final id = await instance.insert(row);
                print('inserted row id: $id');
              },
              style: ElevatedButton.styleFrom(
                primary: const Color(0xFF242331),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                ),
              ),
            ),
          ],
        ),
      ),
      ElevatedButton(
        onPressed: () async {
          await generatePdf();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('PDF file generated successfully!')),
          );
        },
        child: Text('Generate PDF'),
      ),
    );
  }

  Widget buildTextField({
    required String labelText,
    required IconData icon,
  }) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: const Color(0xFF242331),
          //  fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFF242331)),
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: const Color(0xFF242331),
          ),
        ),
      ),
    );
  }
}

final _bloodPressureController = TextEditingController();
final _bloodOxygenController = TextEditingController();
final _bloodSugarController = TextEditingController();
final _stepsController = TextEditingController();
final _durationController = TextEditingController();

class DatabaseHelper {
  static final _databaseName = 'health.db';
  static final _databaseVersion = 1;

  static final table = 'health';
  static final columnId = '_id';
  static final columnDate = 'date';
  static final columnBloodPressure = 'blood_pressure';
  static final columnBloodOxygen = 'blood_oxygen';
  static final columnBloodSugar = 'blood_sugar';
  static final columnSteps = 'steps';
  static final columnDuration = 'duration';

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnDate TEXT NOT NULL,
            $columnBloodPressure REAL NOT NULL,
            $columnBloodOxygen REAL NOT NULL,
            $columnBloodSugar REAL NOT NULL,
            $columnSteps INTEGER NOT NULL,
            $columnDuration INTEGER NOT NULL
          )
          ''');
    Future<void> generatePdf() async {
      final data = await queryAllRows();

      final pdf = pw.Document();

      final headers = [
        'Date',
        'Blood Pressure (mmHg)',
        'Blood Oxygen (%)',
        'Blood Sugar (mg/dL)',
        'Steps',
        'Duration (minutes)'
      ];

      final rows = [
        headers,
        ...data.map((row) => [
              row[columnDate],
              row[columnBloodPressure],
              row[columnBloodOxygen],
              row[columnBloodSugar],
              row[columnSteps],
              row[columnDuration]
            ])
      ];

      pdf.addPage(pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (context) => [
                pw.Table.fromTextArray(
                  context: context,
                  data: rows,
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  cellStyle: pw.TextStyle(),
                  headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
                  columnWidths: {
                    0: pw.FixedColumnWidth(100),
                    1: pw.FixedColumnWidth(120),
                    2: pw.FixedColumnWidth(100),
                    3: pw.FixedColumnWidth(100),
                    4: pw.FixedColumnWidth(60),
                    5: pw.FixedColumnWidth(100),
                  },
                )
              ]));

      final bytes = await pdf.save();

      // Save the PDF file to the device
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/health_report.pdf');
      await file.writeAsBytes(bytes);
    }
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table);
  }
}

final instance = DatabaseHelper();
