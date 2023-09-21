import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gsheets/gsheets.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import 'memory.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final preferencesManagers = PreferencesManager();
  AutoScrollController controllers = AutoScrollController();
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.black,
        brightness: Brightness.light,
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Colors.blue, // Set the cursor (pointer) color for light mode
        ), // Set the brightness to light
        // Define other properties for the light theme
      ),
      darkTheme: ThemeData(
        primaryColor: Colors.blue, // Set a different primary color for dark mode
        brightness: Brightness.dark, // Set the brightness to dark
        textSelectionTheme:const TextSelectionThemeData(
          cursorColor: Colors.white, // Set the cursor (pointer) color for light mode
        ),
        // Define other properties for the dark theme
      ),
      themeMode: _themeMode,
      home: Scaffold(
        appBar: AppBar(
          title:GestureDetector(
            onTap: (){
              setState(() {
                _themeMode = (_themeMode == ThemeMode.light) ? ThemeMode.dark : ThemeMode.light;
              });
            },
              child: Column(
                children: const[
                   Text('JLPT Vocabulary'),
                   Padding(
                     padding: EdgeInsets.only(top: 2),
                     child: Text('N5 ~ N2',style:TextStyle(fontSize: 15)),
                   ),
                ],
              )),
          actions: [
            IconButton(onPressed: ()async{
              int bookmark = await getBookmark();
              controllers.scrollToIndex(
                bookmark,
                preferPosition: AutoScrollPosition.begin,
                duration: const Duration(milliseconds: 500),
              );
            }, icon: const Icon(Icons.bookmark))
          ],
        ),
        body: Center(
          child: GoogleSheetsExample((AutoScrollController controller ){
            controllers =controller;
          }),
        ),
      ),
    );
  }
  Future<int> getBookmark()async{
    await preferencesManagers.initPreferences();
    return preferencesManagers.getIntValue("bookmark");
  }
}


class GoogleSheetsExample extends StatefulWidget {
  Function scrollController;
  GoogleSheetsExample(this.scrollController);
  @override
  _GoogleSheetsExampleState createState() => _GoogleSheetsExampleState();
}

class _GoogleSheetsExampleState extends State<GoogleSheetsExample> {


  late GSheets googleSheet;
  late Spreadsheet dataSheet;
  late List<List<String>> rowData =[];
  List<List<String>> filteredData = [];
  final Debouncer _debounce = Debouncer(milliseconds: 500);
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading =false;
  bool hideAll =false;
  AutoScrollController controller =AutoScrollController();
  final preferencesManager = PreferencesManager();


  @override
  void initState() {
    loadJsonData();
    super.initState();
  }

  Future<void> loadJsonData() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/credentials.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      googleSheet = GSheets(jsonData);
      controller = AutoScrollController(
          viewportBoundaryGetter: () =>
              Rect.fromLTRB(0, 0, 0, MediaQuery.of(context).padding.bottom),
          axis: Axis.vertical);
      widget.scrollController(controller);
      loadSheet();
    } catch (error) {
      final snackBar = SnackBar(
        content: Text('Error loading JSON or initializing GSheets: $error'),
        duration: const Duration(seconds: 4), // Set the duration for how long the Snackbar is displayed.
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void loadSheet()async{
    try {
      setState(() {_isLoading=true;});
      dataSheet = await googleSheet.spreadsheet("1Q32MTNpLik6Mniol6tS9gGY_HtmRZDmdmd3zskv6hcI");
      final sheet = dataSheet.sheets[2];

      rowData = await sheet.values.allRows();

      // for (var index = 0; index < rowData.length; index++) {
      //   rowData[index].add(index.toString());
      // }

      filteredData = List.from(rowData);
      setState(() {
        _isLoading =false;
      });

    } catch (e) {
      setState(() {
        _isLoading =false;
      });
    }
  }
  setBookmark(int value)async{
    await preferencesManager.initPreferences();
    await preferencesManager.setIntValue('bookmark', value);
  }

  void performSearch() {
    setState(() {
      // Filter the data based on the search term (check if any value in the row contains the search term)
      filteredData = rowData.where((row) {
        for (var value in row) {
          if (value.toLowerCase().contains(_searchController.text.toLowerCase())) {
            return true; // Return true if any value matches the search term
          }
        }
        return false; // Return false if no values match the search term
        return false; // Return false if no values match the search term
      }).toList();
    });
    controller.scrollToIndex(0,
        duration: const Duration(microseconds: 500),
        preferPosition: AutoScrollPosition.begin);

  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
     return !_isLoading? Column(
       children: [
         Card(
           elevation: 5,
           child: SizedBox(
             height: 50,
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  Expanded(
                   child: Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: TextField(
                       controller: _searchController,
                       decoration:  InputDecoration(
                         contentPadding: const EdgeInsets.only(left: 10),
                         hintText: 'Search',
                         border: const OutlineInputBorder(),
                         focusedBorder: OutlineInputBorder(
                           borderSide: BorderSide(
                             color: theme.brightness == Brightness.light
                                 ? Colors.blue // Use blue for light mode
                                 : Colors.white, // Use the determined focused border color
                           ),
                         ),
                         suffixIcon: _searchController.text.isNotEmpty?
                              Padding(
                                padding: const EdgeInsets.only(left: 8,top: 8,bottom: 8),
                                child: Container(
                                  width:40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.withOpacity(0.3), // Adjust the background color and opacity
                                  ),
                                  child: InkWell(
                                    onTap: (){
                                      _searchController.clear();
                                      performSearch();
                                    },
                                      child: const Icon(Icons.clear,size: 14,)),
                         ),): null,
                       ),
                       onChanged: (value){
                         _debounce.run(() {
                           performSearch();
                         });
                       },
                     ),
                   ),
                 ),
                 Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: ElevatedButton(
                     style: ButtonStyle(backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                           (Set<MaterialState> states) {
                         if (states.contains(MaterialState.disabled)) {
                           return Colors.grey; // Use gray for disabled state
                         }
                         return theme.brightness == Brightness.light
                             ? Colors.blue // Use blue for light mode
                             : Colors.grey.shade700; // Use gray for dark mode
                       },
                     ),),
                     onPressed: () {
                       setState(() {
                         hideAll=!hideAll;
                       });
                     },
                     child: Text(hideAll?"show":'hide'),
                   ),
                 ),
               ],
             ),
           ),
         ),
         Expanded(
           child:filteredData.isNotEmpty? Scrollbar(
             child: ListView.builder(
               controller: controller,
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                final row = filteredData[index];
                return AutoScrollTag(
                  key: ValueKey(index),
                  controller: controller,
                    index: index,
                    child: MyCardWidget(index: index, row: row,hide: hideAll,longPress: (int value){
                      setBookmark(value);
                    },));
              },
    ),
           ):Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 const Icon(
                   Icons.search_off,
                   size: 100,
                   color: Colors.blueGrey,
                 ),
                 const SizedBox(height: 20),
                 const Text(
                   'No Results Found',
                   style: TextStyle(
                     fontSize: 24,
                     fontWeight: FontWeight.bold,
                     color: Colors.blueGrey,
                   ),
                 ),
                 const SizedBox(height: 10),
                 Text(
                   'No results found for "${_searchController.text}".',
                   style: const TextStyle(
                     fontSize: 16,
                     color: Colors.blueGrey,
                   ),
                 ),
                 const SizedBox(height: 20),
                 ElevatedButton(
                   onPressed: () {
                     _searchController.clear();
                     performSearch();
                   },
                   style: ElevatedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                     textStyle: const TextStyle(fontSize: 18),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(30.0),
                     ),
                   ),
                   child: const Text('clear'),
                 ),
               ],
             ),
           ),
         )
       ],
     ):
     Center(
       child: CircularProgressIndicator(color: theme.brightness == Brightness.light
           ? Colors.blue // Use blue for light mode
           : Colors.white,),
     );
  }
}

class Debouncer {
  final int milliseconds;
  late VoidCallback action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    this.action = action; // Update the action field
    _timer = Timer(Duration(milliseconds: milliseconds), () {
      this.action(); // Call the stored action when the timer completes
    });
  }
}

class MyCardWidget extends StatefulWidget {
  final int index;
  final List<dynamic> row;
  bool hide;
  Function longPress;

  MyCardWidget({
    required this.index,
    required this.row,
    required this.hide,
    required this.longPress,
  });

  @override
  _MyCardWidgetState createState() => _MyCardWidgetState();
}

class _MyCardWidgetState extends State<MyCardWidget> {

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      child: ListTile(
        onTap: (){
          setState(() {
            widget.hide=!widget.hide;
          });
        },
        onLongPress: (){
          widget.longPress(widget.index);
        },
        minLeadingWidth: 0,
        minVerticalPadding: 5,
        leading: Text("${widget.index + 1}. "),
        title: Text("${widget.row[1]}   [ ${widget.row[2]} ]"),
        subtitle: widget.hide?null:Text(widget.row[4]),
        trailing: Text(widget.row[3]), // Join the data with commas for display
      ),
    );
  }
}



