import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';

// TODO: add dark mode
// TODO: make a colorScheme
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Open or create the database when the app starts.
  final database = openDatabase(
    join(await getDatabasesPath(), 'transact.db'),
    onCreate: (db, version) {
      // Create the 'transact' table if it doesn't exist.
      return db.execute(
        'CREATE TABLE transact(id INTEGER PRIMARY KEY AUTOINCREMENT , operator text, item TEXT,amount INTEGER, DTime TEXT )',
      );
    },
    version: 1,
  );
//   runApp(MyApp(
//     DBase: database,
//   ));
// }
  runApp(
    ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
      builder: (context, _) => MyApp(
        DBase: database,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  MyApp({required this.DBase});

  final Future<Database> DBase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //DebugBanner
      home: SafeArea(
        child: Scaffold(
          body: Homepage(DHome: DBase),
        ),
      ),
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({required this.DHome});

  final Future<Database> DHome;

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  int total = 0;
  List<Transaction> TransList = [];
  String opR = '+';
  Icon OPr = Icon(Icons.add, size: 30, color: Colors.blue);
  TextEditingController _amountController = TextEditingController();
  TextEditingController _itemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

// Balance
// EXtractingBalance
  Future<int> getLastBal(Database db) async {
    final List<Map<String, dynamic>>? results =
        await db.query('transact', columns: ['operator', 'amount']);
    if (results == null) {
      return 0; // or some default value
    }

    // Create two lists to store 'operator' and 'amount'
    List<String> os = [];
    List<int> as = [];
    for (int i = 0; i < results.length; i++) {
      final String operator = results[i]['operator'] as String;
      final int amount = results[i]['amount'] as int;
      // Append the values to their respective lists
      os.add(operator);
      as.add(amount);
    }
    total = 0;
    for (int i = 0; i < os.length; i++) {
      if (os[i] == '+') {
        total = total + as[i];
      } else if (os[i] == '-') {
        total = total - as[i];
      }
    }
    ;
    print(os);
    print(as);
    return total;
  }
// Future<int> getLastBal(Database db) async {
//   int runningTotal = 0;
//   bool hasResults = true;

//   int offset = 0;
//   final int limit = 100; // Adjust this limit based on your data size

//   while (hasResults) {
//     final List<Map<String, dynamic>> results = await db.query('transact',
//         columns: ['operator', 'amount'], limit: limit, offset: offset);

//     if (results.isEmpty) {
//       hasResults = false;
//     } else {
//       for (int i = 0; i < results.length; i++) {
//         final String operator = results[i]['operator'] as String;
//         final int amount = results[i]['amount'] as int;

//         if (operator == '+') {
//           runningTotal += amount;
//         } else if (operator == '-') {
//           runningTotal -= amount;
//         }
//       }

//       offset += limit;
//     }
//   }

//   return runningTotal;
// }
  // READ operation
  Future<void> _loadTransactions() async {
    final db = await widget.DHome; //getting Database
    final List<Map<String, dynamic>> maps = await db.query('transact');
    print(maps.toString());

    setState(() {
      TransList = List.generate(maps.length, (index) {
        return Transaction(
          id: maps[index]['id'],
          operator: maps[index]['operator'],
          item: maps[index]['item'],
          amount: maps[index]['amount'],
          DTime: maps[index]['DTime'],
        );
      });
    });

    total = await getLastBal(db);
    setState(() {});
  }

// CREATE operation
  Future<void> _insertTransaction(Transaction transaction) async {
    final db = await widget.DHome;
    await db.insert(
      'transact',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _loadTransactions();
  }

// DELETE operation
  Future<void> _deleteTransaction(int index) async {
    final Database db = await widget.DHome;
    final transToDelete = TransList[index];
    await db.delete(
      'transact',
      where: 'id = ?',
      whereArgs: [transToDelete.id],
    );
    await _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Set system overlay style based on the selected theme
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        // statusBarBrightness:
        //     themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode
          ? Colors.black
          : Color.fromARGB(255, 214, 214, 217),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // AppBar
          Container(
            margin: EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(
                  Icons.menu,
                  size: 40,
                  color: Colors.blue,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Xpense',
                    style: TextStyle(
                      fontSize: 50,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(
                  Icons.search,
                  size: 40,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
          Container(
            width: double.maxFinite,
            height: 50,
            margin: EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 106, 169, 221).withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '₹ ${total.toString()}',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          //List
          Expanded(
              child: ListView.builder(
                  itemCount: TransList.length,
                  itemBuilder: (context, index) {
                    final transList = TransList[index];
                    return GestureDetector(
                      onLongPress: () {
                        //DeleteDialog
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor:
                                  const Color.fromARGB(255, 63, 62, 62),
                              title: Icon(
                                Icons.delete,
                                size: 50,
                                color: Colors.red,
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                  },
                                  child: Icon(Icons.close_sharp, size: 30),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Delete the transaction here
                                    _deleteTransaction(index);
                                    Navigator.of(context)
                                        .pop(); // Close the dialog
                                  },
                                  child: Icon(Icons.check_rounded, size: 30),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Container(
                        //for TIME AND DATE
                        margin: const EdgeInsets.all(7),
                        height: 80,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 106, 169, 221)
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Container(//Tranactions
                              margin: const EdgeInsets.all(1),
                              padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 106, 169, 221)
                                    .withOpacity(0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      child: Text(
                                        transList.item,
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 24,
                                          // fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            transList.operator,
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 24,
                                              // fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${transList.amount} ₹',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 24,
                                              // fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ]),
                            ),
                            Container(
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.fromLTRB(1, 1, 0, 0),
                              child: Text(
                                transList.DTime.toString(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })),

          //addItems
          Container(
            height: 50,
            margin: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 106, 169, 221).withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    height: 100,
                    width: 40,
                    margin: const EdgeInsets.all(5),
                    child: Center(
                      child: GestureDetector(
                        child: OPr,
                        onTap: () {
                          setState(() {
                            opR == '+'
                                ? {
                                    opR = '-',
                                    OPr = Icon(Icons.remove, color: Colors.blue)
                                  }
                                : {
                                    opR = '+',
                                    OPr = Icon(Icons.add, color: Colors.blue)
                                  };
                          });
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: TextField(
                        controller: _itemController,
                        decoration: InputDecoration(
                          //labelText: 'item',
                          hintText: 'itmes',
                          hintStyle: TextStyle(color: Colors.blue),
                           
                          
                        ),
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '₹₹₹₹',
                          hintStyle: TextStyle(color: Colors.blue),
                          labelStyle: TextStyle(color: Colors.blue),
                        ),
                         style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(10),
                    child: GestureDetector(
                      onTap: () async {
                        if (_amountController.text.isNotEmpty ||
                            _itemController.text.isNotEmpty) {
                          // Get the current date and time as a DateTime object
                          DateTime currentDateTime = DateTime.now();
// Create a DateFormat with the desired format
                          final dateFormat = DateFormat('dd-MM-y HH:mm');
// Format the DateTime object as a string
                          String formattedDateTime =
                              dateFormat.format(currentDateTime);
                          int amtInt = int.parse(
                              _amountController.text); //converting text to INT
                          final newTransaction = Transaction(
                            operator: opR,
                            item: _itemController.text,
                            amount: amtInt,
                            DTime: formattedDateTime,
                            //find previous balance here???
                          );
                          setState(() {
                            _insertTransaction(newTransaction);
                            _loadTransactions();
                            _amountController.clear();
                            _itemController.clear();
                          });
                        }
                      },
                      child: const Icon(Icons.send_sharp, color: Colors.blue),
                    ),
                  ),
                ]),
          ),
        ],
      ),
    );
  }
}

class Transaction {
  Transaction({
    this.id,
    required this.operator,
    required this.item,
    required this.amount,
    required this.DTime,
  });

  final int amount;
  final int? id;
  final String item;
  final String operator;
  final String DTime;

  Map<String, dynamic> toMap() {
    return {
      'operator': operator,
      'item': item,
      'amount': amount,
      'DTime': DTime,
    };
  }
}
//ForUiLookAtFlutter
//When send is pressed -insertTransaction get called and inserts the n it calls loadTransaction then it calls getLastBal Function for calculating CumulativeBalance
//AddDateStampToTheTransactions

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;

  ThemeProvider() {
    // Detect system brightness mode and set the initial theme accordingly
    final brightness = WidgetsBinding.instance.window.platformBrightness;
    _isDarkMode = brightness == Brightness.dark;
  }

  bool get isDarkMode => _isDarkMode;

  ThemeData getThemeData() {
    return _isDarkMode
        ? ThemeData.dark().copyWith(
            scaffoldBackgroundColor:
                Colors.black, // Set dark mode background color
          )
        : ThemeData.light().copyWith(
            scaffoldBackgroundColor:
                Colors.white, // Set light mode background color
          );
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
