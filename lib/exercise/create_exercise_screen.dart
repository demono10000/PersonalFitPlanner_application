import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CreateExerciseScreen extends StatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  _CreateExerciseScreenState createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String description = '';
  bool isTimed = false;
  File? _image;

  Future<void> addExercise() async {
    if (_formKey.currentState!.validate()) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? accessToken = prefs.getString('accessToken');

      var request = http.MultipartRequest(
          'POST', Uri.parse('${Config.apiUrl}/exercises/'));
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['is_timed'] = isTimed.toString();

      if (_image != null) {
        final imageBytes = await _image!.readAsBytes();
        if (imageBytes.lengthInBytes > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Zdjęcie jest za duże (maks. 10MB)'),
                backgroundColor: Colors.red),
          );
          return;
        }

        request.files.add(
          http.MultipartFile.fromBytes('image', imageBytes,
              filename: 'compressed_image.jpg'),
        );
      }

      var response = await request.send();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Pomyślnie stworzono ćwiczenie'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Nie udało się stworzyć ćwiczenia'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      File? compressedImage = await _compressImageToJpeg(imageFile);
      setState(() {
        _image = compressedImage;
      });
    }
  }

  Future<File?> _compressImageToJpeg(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      return null;
    }
    final img.Image resizedImage = img.copyResize(
      originalImage,
      width: originalImage.width > 2000 ? 2000 : originalImage.width,
      height: originalImage.height > 2000 ? 2000 : originalImage.height,
    );
    final compressedImageBytes = img.encodeJpg(resizedImage, quality: 85);
    final tempDir = await Directory.systemTemp.createTemp();
    final compressedFile = File('${tempDir.path}/compressed_image.jpg');
    await compressedFile.writeAsBytes(compressedImageBytes);
    return compressedFile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stwórz ćwiczenie'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Text(
              'Personal Fit Planner',
              style: Theme.of(context).textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Dodaj nowe ćwiczenie',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Nazwa',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        name = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wprowadź nazwę';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Opis',
                      prefixIcon: const Icon(Icons.description),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        description = value;
                      });
                    },
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Wprowadź opis';
                      }
                      return null;
                    },
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
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
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
                  if (_image != null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.file(
                          _image!,
                          height: 200.h,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: addExercise,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text('Stwórz ćwiczenie'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
