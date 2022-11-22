import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../saveAndLoad.dart';
//import '../appDesign.dart';

// load groove page
LoadGroovePage loadGroovePage = new LoadGroovePage();

// Stateful version of loadGroovePage page
class LoadGroovePage extends StatefulWidget {
  @override
  _LoadGroovePageState createState() => _LoadGroovePageState();
}

class _LoadGroovePageState extends State<LoadGroovePage> {
  Future<List>? _grooveList;

  @override
  initState() {
    super.initState();
    _grooveList = grooveStorage.listOfSavedGrooves();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Feet - Load Groove'.tr),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(6),
        child: Column(
          children: <Widget>[
            Text(
              'Saved grooves: '.tr,
              style: Theme.of(context).textTheme.caption,
            ),
            Flexible(
                child: FutureBuilder(
                    future: _grooveList,
                    builder: (context, snapshot) {
                      if (_grooveList == null) {
                        // no saved grooves found
                        return Text('No saved grooves found.'.tr);
                      } else {
                        return ListView.builder(
                            itemCount: grooveStorage.grooveFileNames.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ListTile(
                                  title: Text(
                                      grooveStorage.grooveFileNames[index]),
                                  trailing: Icon(Icons.file_upload),
                                  onTap: () {
                                    // load the selected groove
                                    var name =
                                        grooveStorage.grooveFileNames[index];
                                    grooveStorage.readGroove(name);
                                    Get.snackbar('Load status'.tr,
                                        'Loaded groove '.tr + name,
                                        snackPosition: SnackPosition.BOTTOM);
                                    // go back to previous screen
                                    Get.back(closeOverlays: true);
                                    /*
                                    if (groove.type == GrooveType.percussion) {
                                      Get.offAll(groovePage);
                                    } else if (groove.type == GrooveType.bass) {
                                      Get.offAll(bassPage);
                                    }
                                    */
                                  });
                            });
                      }
                    })),
          ],
        ),
      ),
    );
  } // Widget
} // class
