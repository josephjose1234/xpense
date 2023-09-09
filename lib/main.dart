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
        'CREATE TABLE transact(id INTEGER PRIMARY KEY AUTOINCREMENT , operator text, item TEXT,amount TEXT )',
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
  double Total=0.0;
  TextEditingController _itemController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  List<Transaction> TransList = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    someFunction();
  }
  
  Future<void> someFunction() async {
  Total = await sumAmounts();
  // Now, Total holds the sum as a double
  // You can use Total wherever you need the sum
}
  //SUM FUNCTON
Future<double> sumAmounts() async {
  final db = await widget.DHome;
  final result = await db.rawQuery('SELECT SUM(CAST(amount AS REAL)) as total FROM transact');
  
  if (result.isNotEmpty) {
    final total = result.first['total'];
    if (total != null) {
      return total as double; // Ensure 'total' is not null before casting to double
    }
  }
  
  // Handle cases where there are no results or the 'total' is null.
  return 0.0; // You can return a default value or handle it differently based on your requirements.
}


  // READ operation
  Future<void> _loadTransactions() async {
    final db = await widget.DHome;
    final List<Map<String, dynamic>> maps = await db.query('transact');

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
  }

// CREATE operation
  Future<void> _insertTransaction(Transaction transaction) async {
    final db = await widget.DHome;
    await db.insert(
      'transact',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    someFunction();
  }
// DELETE operation
Future<void> _deleteTransaction(int index)async{
  final Database db = await widget.DHome;
  final transToDelete= TransList[index];
  await db.delete(
    'transact',
    where:'id = ?',
    whereArgs: [transToDelete.id],
  );
  _loadTransactions();
  someFunction();
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
                      GestureDetector(
                        onTap:() {
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
                if (_amountController.text.isNotEmpty ||
                    _itemController.text.isNotEmpty) {
                  final newTransaction = Transaction(
                      operator: opR,
                      item: _itemController.text,
                      amount: _amountController.text);
                       await _insertTransaction(newTransaction);
                      setState(() {
                  _loadTransactions();
                  someFunction();
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
  Transaction(
      {this.id,
      required this.operator,
      required this.item,
      required this.amount});
  Map<String, dynamic> toMap() {
    return {'operator': operator, 'item': item, 'amount': amount};
  }
}
