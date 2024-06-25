import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseDetailPage extends StatefulWidget {
  final int exerciseId;

  const ExerciseDetailPage({super.key, required this.exerciseId});

  @override
  _ExerciseDetailPageState createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  Map exercise = {};
  bool isEditing = false;
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  File? _image;

  @override
  void initState() {
    super.initState();
    fetchExerciseDetail();
  }

  Future<void> fetchExerciseDetail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.get(
      Uri.parse('${Config.apiUrl}/exercises/${widget.exerciseId}/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        exercise = jsonDecode(response.body);
        nameController.text = exercise['name'];
        descriptionController.text = exercise['description'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch exercise details')),
      );
    }
  }

  Future<void> updateExercise() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    List<int>? imageBytes;
    if (_image != null) {
      imageBytes = _image!.readAsBytesSync();
    }

    final response = await http.put(
      Uri.parse('${Config.apiUrl}/exercises/${widget.exerciseId}/update/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'name': nameController.text,
        'description': descriptionController.text,
        'image': imageBytes != null ? base64Encode(imageBytes) : null,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        exercise = jsonDecode(response.body);
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update exercise')),
      );
    }
  }

  Future<void> deleteExercise() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/exercises/${widget.exerciseId}/delete/'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exercise deleted successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete exercise')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Details'),
        actions: exercise['is_owner'] == true
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              setState(() {
                isEditing = true;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: deleteExercise,
          ),
        ]
            : null,
      ),
      body: exercise.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: isEditing
            ? Column(
          children: <Widget>[
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            if (_image != null)
              Image.file(
                _image!,
                height: 200,
                width: 200,
              ),
            ElevatedButton(
              onPressed: () async {
                final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
                setState(() {
                  if (pickedFile != null) {
                    _image = File(pickedFile.path);
                  }
                });
              },
              child: const Text('Pick Image'),
            ),
            ElevatedButton(
              onPressed: updateExercise,
              child: const Text('Save'),
            ),
          ],
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              exercise['name'] ?? 'No name',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(exercise['description'] ?? 'No description'),
            const SizedBox(height: 10),
            if (exercise['image'] != null)
              Image.memory(
                base64Decode(exercise['image']),
                height: 200,
                width: 200,
              ),
            const SizedBox(height: 10),
            Text('Timed: ${exercise['is_timed'] ? "Yes" : "No"}'),
          ],
        ),
      ),
    );
  }
}