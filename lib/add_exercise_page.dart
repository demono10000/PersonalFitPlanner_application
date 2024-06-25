
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddExercisePage extends StatefulWidget {
  const AddExercisePage({super.key});

  @override
  _AddExercisePageState createState() => _AddExercisePageState();
}

class _AddExercisePageState extends State<AddExercisePage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String description = '';
  bool isTimed = false;
  File? _image;

  Future<void> addExercise() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      var request = http.MultipartRequest('POST', Uri.parse('${Config.apiUrl}/exercises/create/'));
      request.headers['Authorization'] = 'Bearer $accessToken';

      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['is_timed'] = isTimed.toString();

      if (_image != null) {
        request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
      }

      var response = await request.send();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise added successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add exercise')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Exercise'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) {
                  setState(() {
                    name = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the name';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onChanged: (value) {
                  setState(() {
                    description = value;
                  });
                },
              ),
              SwitchListTile(
                title: const Text('Is Timed'),
                value: isTimed,
                onChanged: (value) {
                  setState(() {
                    isTimed = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Pick Image'),
              ),
              if (_image != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.file(
                    _image!,
                    height: 200,
                  ),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: addExercise,
                child: const Text('Add Exercise'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
