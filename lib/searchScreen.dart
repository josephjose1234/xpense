import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart' as sqflite;
import 'dataModel.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'theme.dart';
import 'package:intl/intl.dart';


class SearchScreen extends StatefulWidget {
  SearchScreen({required this.DSearch});

  final Future<Database> DSearch;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  double TotaL = 0;
  List<Transactions> TransList = [];

  TextEditingController _searchController = TextEditingController();

  Future<List<Transactions>> _searchTransaction(String searchTerm) async {
    final Database db = await widget.DSearch;
    final List<Transactions> searchResults = [];

    // Define your SQL query to search for transactions based on the "items" column
    final String query = '''
    SELECT * FROM transact
    WHERE item LIKE ?
  ''';

    // Execute the query and pass the search term as a parameter
    final List<Map<String, dynamic>> results =
        await db.rawQuery(query, ['%$searchTerm%']);

    // Process the results and populate the searchResults list
    for (final Map<String, dynamic> row in results) {
      final transaction = Transactions(
        id: row['id'],
        operator: row['operator'],
        item: row['item'],
        amount: row['amount'],
        DTime: row['DTime'],
      );
      searchResults.add(transaction);
    }

    setState(() {
      TransList = searchResults; // Update TransList with search results
    });
    // Calculate the sum of amounts
    double sum = 0.0;
    for (final transaction in searchResults) {
      sum += transaction.amount;
    }
    setState(() {
      TotaL = sum;
    });

    print('Sum of amounts: $sum');
    return searchResults;
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
    return SafeArea(
      child: Scaffold(
        backgroundColor: themeProvider.isDarkMode
            ? Colors.black
            : Color.fromARGB(255, 214, 214, 217),
        body: CustomScrollView(
          slivers: <Widget>[
            // AppBar
            SliverAppBar(
              backgroundColor:
                  themeProvider.isDarkMode ? Colors.black : Colors.white,
              expandedHeight: 150.0,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Container(
                  width: double.maxFinite,
                  height: double.maxFinite,
                  alignment: Alignment.bottomCenter,
                  color: themeProvider.isDarkMode
                      ? Color.fromARGB(255, 30, 27, 27)
                      : Color.fromARGB(255, 247, 219, 219),
                  child: Text(
                    '₹ ${TotaL.toString()}',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                centerTitle: true,
              ),
            ),
            SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.only(left: 20),
                    child: Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            //List
            SliverList(
              delegate: SliverChildBuilderDelegate(
                childCount: TransList.length,
                (BuildContext context, int index) {
                  final transList = TransList[index];
                  return Container(
                    //for TIME AND DATE
                    margin: const EdgeInsets.all(7),
                    height: 80,
                    decoration: BoxDecoration(
                      color:
                          Color.fromARGB(255, 106, 169, 221).withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Container(
                          //Tranactions
                          margin: const EdgeInsets.all(1),
                          padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
                          height: 50,
                          decoration: BoxDecoration(
                            // color: Color.fromARGB(255, 106, 169, 221)
                            //  .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  mainAxisAlignment: MainAxisAlignment.end,
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
                            ],
                          ),
                        ),
                        Container(
                          alignment: Alignment.bottomRight,
                          padding: EdgeInsets.fromLTRB(0, 1, 5, 0),
                          child: Text(
                            transList.DTime.toString(),
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: Container(
          height: 50,
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 106, 169, 221).withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              //labelText: 'item',
              hintText: 'itmes',
              hintStyle: TextStyle(color: Colors.blue),
            ),
            style: TextStyle(color: Colors.blue),
            onChanged: (text) {
              _searchTransaction(text);
            },
          ),
        ),
      ),
    );
  }
}
