import 'package:flutter/material.dart';
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
  final Future<Database> DBase;
  MyApp({required this.DBase});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Xpense'),
        ),
        body: Homepage(DHome: DBase),
      ),
    );
  }
}

class Homepage extends StatefulWidget {
  final Future<Database> DHome;
  const Homepage({required this.DHome});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String opR = '+';
  int Total = 0;
  TextEditingController _itemController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  List<Transaction> TransList = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _initializeTotal();
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        //forTotal

        Container(child: Text(Total.toString())),
        //List
        Expanded(
            child: ListView.builder(
                itemCount: TransList.length,
                itemBuilder: (context, index) {
                  final transList = TransList[index];
                  return Container(
                    child: Column(children: [
                      Text(transList.amount),
                      Text(transList.item),
                      Text(transList.operator),
                      Text('BAl '),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _deleteTransaction(index);
                          });
                        },
                        child: Text('DELETE'),
                      ),
                    ]),
                  );
                })),

        //addItems
        Container(
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              margin: EdgeInsets.all(20),
              child: GestureDetector(
                child: Text(opR, style: TextStyle(fontSize: 30)),
                onTap: () {
                  setState(() {
                    opR == '+' ? opR = '-' : opR = '+';
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                  child: TextField(
                controller: _itemController,
                decoration: InputDecoration(labelText: 'item'),
              )),
            ),
            Expanded(
              child: Container(
                  child: TextField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Amount'),
              )),
            ),
            ElevatedButton(
              onPressed: () async {
                final Database db = await widget.DHome;
                int CBal =
                    int.parse(_amountController.text); //converting text to INT
                int prevBal = await getLastBal(db); //gettingLastBalance
                
                int newBal = prevBal + CBal; //Adding Previous Balance to the Current Balance
                if (_amountController.text.isNotEmpty ||
                    _itemController.text.isNotEmpty) {
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
              },
              child: Text('save'),
            ),
          ]),
        ),
      ],
    );
  }
}

class Transaction {
  final int? id;
  final String operator;
  final String item;
  final String amount;
  final int Bal;
  Transaction(
      {this.id,
      required this.operator,
      required this.item,
      required this.amount,
      required this.Bal});
  Map<String, dynamic> toMap() {
    return {'operator': operator, 'item': item, 'amount': amount, 'Bal': Bal};
  }
}
