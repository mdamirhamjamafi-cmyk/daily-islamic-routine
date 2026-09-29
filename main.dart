import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const DailyIslamicRoutineApp());
}

class Routine {
  String title;
  String time;
  bool completed;

  Routine({required this.title, required this.time, this.completed = false});

  Map<String, dynamic> toJson() => {
        'title': title,
        'time': time,
        'completed': completed,
      };

  factory Routine.fromJson(Map<String, dynamic> json) => Routine(
        title: json['title'] ?? '',
        time: json['time'] ?? '',
        completed: json['completed'] ?? false,
      );
}

class DailyIslamicRoutineApp extends StatelessWidget {
  const DailyIslamicRoutineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Islamic Routine',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B4D)),
        scaffoldBackgroundColor: const Color(0xFFF5F8F6),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Routine> routines = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRoutines();
  }

  Future<void> loadRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('routines');

    if (raw == null) {
      routines = [
        Routine(title: 'ফজরের নামাজ', time: 'ভোর'),
        Routine(title: 'কুরআন তিলাওয়াত', time: 'সকাল'),
        Routine(title: 'পড়াশোনা', time: 'সকাল'),
        Routine(title: 'যোহরের নামাজ', time: 'দুপুর'),
        Routine(title: 'আসরের নামাজ', time: 'বিকেল'),
        Routine(title: 'মাগরিবের নামাজ', time: 'সন্ধ্যা'),
        Routine(title: 'ইশার নামাজ', time: 'রাত'),
        Routine(title: 'ঘুমের আগে যিকর', time: 'রাত'),
      ];
      await saveRoutines();
    } else {
      final list = jsonDecode(raw) as List;
      routines = list
          .map((e) => Routine.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    setState(() => loading = false);
  }

  Future<void> saveRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'routines',
      jsonEncode(routines.map((r) => r.toJson()).toList()),
    );
  }

  void toggleRoutine(int index) {
    setState(() => routines[index].completed = !routines[index].completed);
    saveRoutines();
  }

  void deleteRoutine(int index) {
    final removed = routines[index].title;
    setState(() => routines.removeAt(index));
    saveRoutines();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$removed মুছে ফেলা হয়েছে')),
    );
  }

  void showAddDialog() {
    final titleController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('নতুন রুটিন যোগ করুন'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'কাজের নাম',
                prefixIcon: Icon(Icons.task_alt),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'সময়/পর্ব',
                prefixIcon: Icon(Icons.schedule),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('বাতিল'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) return;
              setState(() {
                routines.add(
                  Routine(
                    title: titleController.text.trim(),
                    time: timeController.text.trim().isEmpty
                        ? 'আজ'
                        : timeController.text.trim(),
                  ),
                );
              });
              saveRoutines();
              Navigator.pop(context);
            },
            child: const Text('যোগ করুন'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final completed = routines.where((r) => r.completed).length;
    final progress = routines.isEmpty ? 0.0 : completed / routines.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Daily Islamic Routine',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('রুটিন যোগ'),
      ),
      body: RefreshIndicator(
        onRefresh: loadRoutines,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'আজকের লক্ষ্য',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 14),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 9,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    const SizedBox(height: 10),
                    Text('$completed / ${routines.length} কাজ সম্পন্ন'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...List.generate(routines.length, (index) {
              final routine = routines[index];
              return Dismissible(
                key: ValueKey('${routine.title}-$index'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => deleteRoutine(index),
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  elevation: 0,
                  child: CheckboxListTile(
                    value: routine.completed,
                    onChanged: (_) => toggleRoutine(index),
                    title: Text(
                      routine.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        decoration: routine.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(routine.time),
                    secondary: Icon(
                      routine.completed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
