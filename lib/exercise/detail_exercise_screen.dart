import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DetailExerciseScreen extends StatefulWidget {
  final int exerciseId;

  const DetailExerciseScreen({super.key, required this.exerciseId});

  @override
  _DetailExerciseScreenState createState() => _DetailExerciseScreenState();
}

class _DetailExerciseScreenState extends State<DetailExerciseScreen> {
  Map<String, dynamic> exercise = {};
  bool isEditing = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  File? _image;
  Uint8List? imageBytes;
  bool isTimed = false;

  @override
  void initState() {
    super.initState();
    fetchExerciseDetail();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
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
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      setState(() {
        exercise = data;
        nameController.text = exercise['name'] ?? '';
        descriptionController.text = exercise['description'] ?? '';
        isTimed = exercise['is_timed'] ?? false;
      });

      if (exercise['image'] != null) {
        fetchExerciseImage();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nie udało się pobrać szczegółów ćwiczenia')),
      );
    }
  }

  Future<void> fetchExerciseImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final imageUrl = Uri.parse('${Config.apiUrl}/${exercise['image']}');
    final imageResponse = await http.get(
      imageUrl,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (imageResponse.statusCode == 200) {
      setState(() {
        imageBytes = imageResponse.bodyBytes;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie udało się pobrać obrazu')),
      );
    }
  }

  Future<void> updateExercise() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    var uri = Uri.parse('${Config.apiUrl}/exercises/${widget.exerciseId}');
    var request = http.MultipartRequest('PUT', uri)
      ..headers['Authorization'] = 'Bearer $accessToken';

    request.fields['name'] = nameController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['is_timed'] = isTimed.toString();

    if (_image != null) {
      var imageStream = http.ByteStream(_image!.openRead());
      var imageLength = await _image!.length();

      request.files.add(
        http.MultipartFile(
          'image',
          imageStream,
          imageLength,
          filename: _image!.path.split('/').last,
        ),
      );
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      setState(() {
        exercise = jsonDecode(responseBody);
        isEditing = false;
        isTimed = exercise['is_timed'] ?? false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Poprawnie zaktualizowano ćwiczenie'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nie udało się zaktualizować ćwiczenia'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> confirmDeleteExercise() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potwierdzenie usunięcia'),
        content: const Text('Czy na pewno chcesz usunąć to ćwiczenie?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Anuluj'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Usuń'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      deleteExercise();
    }
  }

  Future<void> deleteExercise() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    final response = await http.delete(
      Uri.parse('${Config.apiUrl}/exercises/${widget.exerciseId}'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 204) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pomyślnie usunięto ćwiczenie'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nie udało się usunąć ćwiczenia'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
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
        title: const Text('Szczegóły ćwiczenia'),
        actions: exercise['is_owner'] == true
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    setState(() {
                      isEditing = true;
                    });
                  },
                  tooltip: 'Edytuj',
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: confirmDeleteExercise,
                  tooltip: 'Usuń',
                ),
              ]
            : null,
      ),
      body: exercise.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: isEditing
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: imageBytes != null
                                ? Image.memory(
                                    imageBytes!,
                                    height: 200.h,
                                    width: double.infinity,
                                    fit: BoxFit.fitHeight,
                                  )
                                : _image != null
                                    ? Image.file(
                                        _image!,
                                        height: 200.h,
                                        width: double.infinity,
                                        fit: BoxFit.fitHeight,
                                      )
                                    : Container(
                                        height: 200.h,
                                        width: double.infinity,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image,
                                            size: 50, color: Colors.white),
                                      ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Nazwa',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        TextField(
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Opis',
                            prefixIcon: const Icon(Icons.description),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          maxLines: 3,
                        ),
                        SizedBox(height: 16.h),
                        SwitchListTile(
                          title: const Text('Czasowe'),
                          value: isTimed,
                          onChanged: (value) {
                            setState(() {
                              isTimed = value;
                            });
                          },
                          secondary: const Icon(Icons.timer),
                        ),
                        SizedBox(height: 16.h),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: pickImage,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Wybierz zdjęcie'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: updateExercise,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: const Text('Zapisz'),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12.r),
                            child: imageBytes != null
                                ? Image.memory(
                                    imageBytes!,
                                    height: 200.h,
                                    width: double.infinity,
                                    fit: BoxFit.fitHeight,
                                  )
                                : Container(
                                    height: 200.h,
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image,
                                        size: 50, color: Colors.white),
                                  ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          exercise['name'] ?? 'Brak nazwy',
                          style: Theme.of(context)
                              .textTheme
                              .displayLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          exercise['description'] ?? 'Brak opisu',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.timer,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Czasowe: ${exercise['is_timed'] ? "Tak" : "Nie"}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
    );
  }
}
