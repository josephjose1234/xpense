import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
// UPDATE TRANSACTION FEATURE
//X1X!X!X!!

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = openDatabase(
    join(await getDatabasesPath(), 'transact.db'),
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE transact(id INTEGER PRIMARY KEY AUTOINCREMENT , operator text, item TEXT,amount TEXT ,Bal INTEGER)',
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
  int Total = 0;
  List<Transaction> TransList = [];
  String opR = '+';
  Icon OPr = Icon(Icons.add, size: 30);
  TextEditingController _amountController = TextEditingController();
  TextEditingController _itemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _initializeTotal();
  }

// Balance
// getting the last balnce from the database
  Future<int> getLastBal(Database db) async {
    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT Bal FROM transact ORDER BY id DESC LIMIT 1',
    );

    if (result.isNotEmpty) {
      return result.first['Bal'] as int;
    } else {
      // Handle the case when the table is empty
      return 0; // Or another default value that makes sense for your use case
    }
  }

  balFunction() async {
    // assinging the balnce as TOTAl
    final db = await widget.DHome;
    Total = await getLastBal(db);
    return Total;
  }

  Future<void> _initializeTotal() async {
    final db = await widget.DHome;
    Total = await getLastBal(db);
    // Total = await balFunction();
    setState(() {});
  }

  // READ operation
  Future<void> _loadTransactions() async {
    final db = await widget.DHome;
    final List<Map<String, dynamic>> maps = await db.query('transact');
    print(maps.toString());
    
    setState(() {
      TransList = List.generate(maps.length, (index) {
        return Transaction(
            id: maps[index]['id'],
            operator: maps[index]['operator'],
            item: maps[index]['item'],
            amount: maps[index]['amount'],
            Bal: maps[index]['Bal']);
      });
    });
  }

// CREATE operation
  Future<void> _insertTransaction(Transaction transaction) async {
    final db = await widget.DHome;
    await db.insert(
      'transact',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    _loadTransactions();
    balFunction();
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
              '₹ ${Total.toString()}',
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
                    onLongPress: () {
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
                  decoration: InputDecoration(labelText: '₹₹₹₹'),
                ),
              ),
            ),
            Container(
              margin: EdgeInsets.all(10),
              child: GestureDetector(
                onTap: () async {
                  final Database db = await widget.DHome;
                  int CBal = int.parse(
                      _amountController.text); //converting text to INT
                  int prevBal = await getLastBal(db); //gettingLastBalance
                  // int newBal = prevBal + CBal; //Adding Previous Balance to the Current Balance
                  if (_amountController.text.isNotEmpty ||
                      _itemController.text.isNotEmpty) {
                    if (opR == '+') {
                      int newBal = prevBal + CBal;
                      final newTransaction = Transaction(
                        operator: opR,
                        item: _itemController.text,
                        amount: _amountController.text,
                        Bal: newBal, //find previous balance here???
                      );
                      await _insertTransaction(newTransaction);
                      await _initializeTotal();
                      setState(() {
                        _loadTransactions();
                        _amountController.clear();
                        _itemController.clear();
                      });
                    } else if (opR == '-') {
                      int newBal = prevBal - CBal;
                      final newTransaction = Transaction(
                        operator: opR,
                        item: _itemController.text,
                        amount: _amountController.text,
                        Bal: newBal, //find previous balance here???
                      );
                      await _insertTransaction(newTransaction);
                      await _initializeTotal();
                      setState(() {
                        _loadTransactions();
                        _amountController.clear();
                        _itemController.clear();
                      });
                    }
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
      required this.Bal});

  final int Bal;
  final String amount;
  final int? id;
  final String item;
  final String operator;

  Map<String, dynamic> toMap() {
    return {'operator': operator, 'item': item, 'amount': amount, 'Bal': Bal};
  }
}
