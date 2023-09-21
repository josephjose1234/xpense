import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// UPDATE TRANSACTION FEATURE
//X1X!X!X!!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Open or create the database when the app starts.
  final database = openDatabase(
    join(await getDatabasesPath(), 'transact.db'),
    onCreate: (db, version) {
       // Create the 'transact' table if it doesn't exist.
      return db.execute(
        'CREATE TABLE transact(id INTEGER PRIMARY KEY AUTOINCREMENT , operator text, item TEXT,amount INTEGER )',
      );
    },
    version: 1,
  );
  runApp(MyApp(
    DBase: database,
  ));
}

class MyApp extends StatelessWidget {
  MyApp({required this.DBase});

  final Future<Database> DBase;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       debugShowCheckedModeBanner: false,//DebugBanner
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
  Icon OPr = Icon(Icons.add, size: 30);
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
 total=0;
for (int i = 0; i < os.length; i++) {
      if (os[i] == '+') {
        total = total + as[i];
      } else if (os[i] == '-') {
        total = total - as[i];
      }
    };
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
            );
      });
    });
     
     total=await getLastBal(db);
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
   await  _loadTransactions();
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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
      ),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // AppBar
        Container(
          margin: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.menu,
                size: 40,
                color: Colors.blue,
              ),
              Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Xpense',
                  style: TextStyle(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
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
            color: Color.fromRGBO(0, 0, 255, 0.25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '₹ ${total.toString()}',
              style: TextStyle(
                color: Colors.white,
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
                    onLongPress: () {//DeleteDialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
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
                                  child: Icon(Icons.close_sharp, size: 30)),
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
                      margin: EdgeInsets.all(5),
                      padding: EdgeInsets.fromLTRB(25, 5, 5, 5),
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color.fromRGBO(0, 0, 255, 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              child: Text(
                                transList.item,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    transList.operator,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${transList.amount} ₹',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]),
                    ),
                  );
                })),

        //addItems
        Container(
          height: 50,
          margin: EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Color.fromRGBO(0, 0, 255, 0.25),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              height: 100,
              width: 40,
              margin: EdgeInsets.all(5),
              child: Center(
                child: GestureDetector(
                  child: OPr,
                  onTap: () {
                    setState(() {
                      opR == '+'
                          ? {opR = '-', OPr = Icon(Icons.remove)}
                          : {opR = '+', OPr = Icon(Icons.add)};
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: Container(
                child: TextField(
                  controller: _itemController,
                  decoration: InputDecoration(labelText: 'item'),
                ),
              ),
            ),
            Expanded(
              child: Container(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: '₹₹₹₹'),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: GestureDetector(
                onTap: () async {
                  if (_amountController.text.isNotEmpty ||
                      _itemController.text.isNotEmpty) {
                    int amtInt = int.parse(
                        _amountController.text); //converting text to INT
                    final newTransaction = Transaction(
                      operator: opR,
                      item: _itemController.text,
                      amount: amtInt,
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
                child: Icon(Icons.send_sharp, color: Colors.green),
              ),
            ),
          ]),
        ),
      ],
    );
  }
}

class Transaction {
  Transaction(
      {this.id,
      required this.operator,
      required this.item,
      required this.amount,
      });

  
  final int amount;
  final int? id;
  final String item;
  final String operator;

  Map<String, dynamic> toMap() {
    return {'operator': operator, 'item': item, 'amount': amount, };
  }
}
//ForUiLookAtFlutter
//When send is pressed -insertTransaction get called and inserts the n it calls loadTransaction then it calls getLastBal Function for calculating CumulativeBalance