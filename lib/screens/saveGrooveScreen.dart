import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../saveAndLoad.dart';
import '../appDesign.dart';

// save groove page
SaveGroovePage saveGroovePage = new SaveGroovePage();

// Stateful version of saveGroovePage page
class SaveGroovePage extends StatefulWidget {
  @override
  _SaveGroovePageState createState() => _SaveGroovePageState();
}

class _SaveGroovePageState extends State<SaveGroovePage> {
  final TextEditingController _filenameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  initState() {
    super.initState();
    _filenameController.addListener(() {
      final String text = _filenameController.text.toLowerCase();
      _filenameController.value = _filenameController.value.copyWith(
        text: text,
        selection:
            TextSelection(baseOffset: text.length, extentOffset: text.length),
        composing: TextRange.empty,
      );
    });
    _descriptionController.addListener(() {
      final String text = _descriptionController.text;
      _descriptionController.value = _descriptionController.value.copyWith(
        text: text,
        selection:
            TextSelection(baseOffset: text.length, extentOffset: text.length),
        composing: TextRange.empty,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Feet - Save Groove'.tr),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(6),
        child: ListView(children: <Widget>[
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
              Widget>[
            Text(
              'Enter groove name: '.tr,
              style: Theme.of(context).textTheme.caption,
            ),
            TextFormField(
              controller: _filenameController,
              textCapitalization: TextCapitalization.none,
              inputFormatters: [
                new FilteringTextInputFormatter(RegExp("[a-z0-9_]"),
                    allow: true)
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  Get.snackbar(
                      'Missing or invalid file name:'.tr,
                      'Please enter a file name with only letters, numbers and underscores.'
                          .tr,
                      snackPosition: SnackPosition.BOTTOM);
                  return 'Please enter a file name';
                } else {
                  return null;
                }
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            Text(
              'Enter a description of the groove: '.tr,
              style: Theme.of(context).textTheme.caption,
            ),
            TextFormField(
              controller: _descriptionController,
              inputFormatters: [
                new FilteringTextInputFormatter(RegExp(","), allow: false)
              ],
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(
                            AppColors.myButtonColor),
                      ),
                child: Text('Save groove'.tr,
                  style: AppTheme.appTheme.textTheme.caption,),
                onPressed: () {
                  grooveStorage.writeGroove(
                      _filenameController.text, _descriptionController.text);
                  Get.snackbar('Status:'.tr, 'groove saved'.tr,
                      snackPosition: SnackPosition.BOTTOM);
                  // go back to previous screen
                  Get.back(closeOverlays: true);
                  }),
            ),
          ]),
        ]),
      ),
    );
  } // Widget
} // class