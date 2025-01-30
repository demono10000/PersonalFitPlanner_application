import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ExecutionTrainingScreen extends StatefulWidget {
  final int trainingPlanId;
  final int trainingId;

  const ExecutionTrainingScreen({
    super.key,
    required this.trainingPlanId,
    required this.trainingId,
  });

  @override
  _ExecutionTrainingScreenState createState() =>
      _ExecutionTrainingScreenState();
}

class _ExecutionTrainingScreenState extends State<ExecutionTrainingScreen> {
  Map<String, dynamic> trainingPlan = {};
  int currentExerciseIndex = 0;
  Timer? _timer;
  int _timeRemaining = 0;
  bool isTimedExercise = false;
  bool isTimerRunning = false;
  Uint8List? imageBytes;
  double _multiplier = 1.0;
  final TextEditingController _multiplierController =
      TextEditingController(text: '1.0');
  bool isLoading = true;
  bool hasExercises = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _promptForMultiplier();
    });
  }

  Future<void> _promptForMultiplier() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ustawienie poziomu trudności'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Wprowadź mnożnik poziomu trudności (od 0.1):'),
              SizedBox(height: 10.h),
              TextField(
                controller: _multiplierController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: '1.0',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                double inputMultiplier =
                    double.tryParse(_multiplierController.text) ?? 1.0;
                setState(() {
                  _multiplier = inputMultiplier >= 0.1 ? inputMultiplier : 0.1;
                });
                Navigator.of(context).pop();
                fetchTrainingPlanDetail();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchTrainingPlanDetail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/training-plans/${widget.trainingPlanId}'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        List<dynamic> exercises = data['exercises'] ?? [];

        setState(() {
          trainingPlan = data;
          hasExercises = exercises.isNotEmpty;

          if (hasExercises) {
            for (var exercise in exercises) {
              if (exercise['exercise']['id'] != -1) {
                if (exercise['is_timed'] == true) {
                  int duration = exercise['repetitions'];
                  exercise['repetitions'] = (duration * _multiplier).round();
                } else {
                  int repetitions = exercise['repetitions'];
                  exercise['repetitions'] = (repetitions * _multiplier).round();
                }
              }
            }
          }

          isLoading = false;
        });

        if (hasExercises) {
          _startExercise();
        }
      } else {
        setState(() {
          isLoading = false;
          hasExercises = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się pobrać szczegółów planu treningowego'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasExercises = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas pobierania planu treningowego'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _startExercise() async {
    if (hasExercises && trainingPlan['exercises'].isNotEmpty) {
      var currentExercise = trainingPlan['exercises'][currentExerciseIndex];
      setState(() {
        isTimedExercise = currentExercise['is_timed'] == true;
      });
      _resetTimer();

      if (currentExercise['exercise']['image'] != null) {
        await fetchExerciseImage(currentExercise['exercise']['image']);
      } else {
        setState(() {
          imageBytes = null;
        });
      }

      if (isTimedExercise) {
        setState(() {
          _timeRemaining = currentExercise['repetitions'];
        });
      }
    }
  }

  Future<void> fetchExerciseImage(String imageUrl) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final url = Uri.parse('${Config.apiUrl}$imageUrl');
      final imageResponse = await http.get(
        url,
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
          const SnackBar(
            content: Text('Nie udało się pobrać obrazu'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas pobierania obrazu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _startTimer() {
    setState(() {
      isTimerRunning = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          timer.cancel();
          isTimerRunning = false;
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      isTimerRunning = false;
    });
  }

  void _resetTimer() {
    _pauseTimer();
    if (hasExercises && trainingPlan['exercises'].isNotEmpty) {
      var currentExercise = trainingPlan['exercises'][currentExerciseIndex];
      setState(() {
        _timeRemaining = currentExercise['repetitions'];
      });
    }
  }

  void _goToNextExercise() async {
    if (hasExercises && trainingPlan['exercises'].isNotEmpty) {
      if (currentExerciseIndex < trainingPlan['exercises'].length - 1) {
        setState(() {
          currentExerciseIndex++;
        });
        await _startExercise();
      } else {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String>? completedTrainings =
            prefs.getStringList('completedTrainings') ?? [];

        if (!completedTrainings.contains(widget.trainingId.toString())) {
          completedTrainings.add(widget.trainingId.toString());
          await prefs.setStringList('completedTrainings', completedTrainings);
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TrainingRatingScreen(
              trainingId: widget.trainingId,
              multiplier: _multiplier,
            ),
          ),
        );
      }
    }
  }

  void _goToPreviousExercise() {
    if (hasExercises && trainingPlan['exercises'].isNotEmpty) {
      if (currentExerciseIndex > 0) {
        setState(() {
          currentExerciseIndex--;
        });
        _startExercise();
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _multiplierController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Realizacja treningu'),
          centerTitle: true,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!hasExercises || (trainingPlan['exercises'] as List).isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Realizacja treningu'),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'Brak dostępnych ćwiczeń',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    var currentExercise = trainingPlan['exercises'][currentExerciseIndex];
    var exerciseName = currentExercise['exercise']['name'] ?? 'Ćwiczenie';
    var exerciseDescription = currentExercise['exercise']['description'] ?? '';
    var repetitions = currentExercise['repetitions'] ?? 0;

    var totalExercises = trainingPlan['exercises'].length;
    var nextExercise = currentExerciseIndex < totalExercises - 1
        ? trainingPlan['exercises'][currentExerciseIndex + 1]['exercise']
                ['name'] ??
            ''
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Realizacja treningu'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ćwiczenie ${currentExerciseIndex + 1}/$totalExercises',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            Text(
              exerciseName,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.h),
            SizedBox(
              height: 50.h,
              child: AutoSizeText(
                exerciseDescription,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
                maxLines: 3,
                minFontSize: 12,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 30.h),
            if (imageBytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.memory(
                  imageBytes!,
                  height: 200.h,
                  width: double.infinity,
                  fit: BoxFit.fitHeight,
                ),
              )
            else
              SizedBox(
                height: 200.h,
                width: 200.w,
                child: Center(
                  child: Icon(
                    Icons.image_not_supported,
                    size: 50.sp,
                    color: Colors.grey,
                  ),
                ),
              ),
            SizedBox(height: 30.h),
            if (isTimedExercise)
              Text(
                'Czas: $_timeRemaining sekund',
                style: TextStyle(
                  fontSize: 28.sp,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                'Powtórzenia: $repetitions',
                style: TextStyle(
                  fontSize: 28.sp,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            SizedBox(height: 30.h),
            if (isTimedExercise)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isTimerRunning ? null : _startTimer,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(0, 60.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text('Start'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isTimerRunning ? _pauseTimer : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(0, 60.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text('Pauza'),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _resetTimer,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(0, 60.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 30.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        currentExerciseIndex > 0 ? _goToPreviousExercise : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(0, 60.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: const Text('Poprzednie'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _goToNextExercise,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(0, 60.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: currentExerciseIndex < totalExercises - 1
                        ? const Text('Następne')
                        : const Text('Zakończ'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Text(
              nextExercise != null
                  ? 'Następne ćwiczenie: $nextExercise'
                  : 'To jest ostatnie ćwiczenie',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class TrainingRatingScreen extends StatefulWidget {
  final int trainingId;
  final double multiplier;

  const TrainingRatingScreen({
    super.key,
    required this.trainingId,
    required this.multiplier,
  });

  @override
  _TrainingRatingScreenState createState() => _TrainingRatingScreenState();
}

class _TrainingRatingScreenState extends State<TrainingRatingScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    setState(() {
      _isSubmitting = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('accessToken');

    try {
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/trainings/rate'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'training_id': widget.trainingId,
          'rating': _rating,
          'comment': _commentController.text,
          'multiplier': widget.multiplier,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dziękujemy za ocenę!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nie udało się przesłać oceny'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wystąpił błąd podczas przesyłania oceny'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oceń trening'),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Text(
              'Proszę ocenić trening od 1 do 10',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            DropdownButtonFormField<int>(
              value: _rating,
              items: List.generate(10, (index) => index + 1).map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(
                    '$value',
                    style: TextStyle(fontSize: 16.sp),
                  ),
                );
              }).toList(),
              onChanged: (int? newValue) {
                setState(() {
                  _rating = newValue ?? 5;
                });
              },
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
              ),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: 'Komentarz (opcjonalnie)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRating,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Prześlij ocenę'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
