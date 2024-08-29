import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'range_model.dart';
import 'circular_time_chart.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Range> ranges = [];
  List<Range> nextDayRanges = [];
  Range? selectedRange;
  Range? nextDaySelectedRange;
  int? valueIndex;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('uk', null).then((_) => loadData());
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
    });

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tomorrow = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().add(const Duration(days: 1)));

    try {
      List<Range> newRanges = [];
      List<Range> newNextDayRanges = [];

      await Future.wait([
        loadDataForDate(today, (data) => newRanges = data),
        loadDataForDate(tomorrow, (data) => newNextDayRanges = data),
      ]);

      setState(() {
        ranges = newRanges;
        nextDayRanges = newNextDayRanges;
        isLoading = false;
      });

      // Load the last selected queue
      await loadLastSelectedQueue();
    } catch (error) {
      // Завантаження даних з кешу у разі помилки
      final cachedRanges = await loadCachedData(today);
      final cachedNextDayRanges = await loadCachedData(tomorrow);

      setState(() {
        ranges = cachedRanges;
        nextDayRanges = cachedNextDayRanges;
        isLoading = false;
      });

      // Load the last selected queue
      await loadLastSelectedQueue();

      // Показуємо спливаюче повідомлення про відсутність зв'язку
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Немає зв\'язку. Дані можуть бути застарілі.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> loadLastSelectedQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSelectedQueueName = prefs.getString('lastSelectedQueue');
    if (lastSelectedQueueName != null) {
      final index = ranges.indexWhere((r) => r.name == lastSelectedQueueName);
      if (index != -1) {
        setState(() {
          selectedRange = ranges[index];
          valueIndex = index;
          nextDaySelectedRange =
              index < nextDayRanges.length ? nextDayRanges[index] : null;
        });
      }
    }
  }

  Future<void> saveLastSelectedQueue(String queueName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastSelectedQueue', queueName);
  }

  Future<void> loadDataForDate(
      String date, Function(List<Range>) setRanges) async {
    final url = 'https://poweroff.if.ua/schedule?date=$date';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['ranges'] != null) {
        final List<Range> loadedRanges = List<Range>.from(
            data['ranges'].map((item) => Range.fromJson(item)));
        setRanges(loadedRanges);
        // Зберігаємо дані в кеш
        await cacheData(date, loadedRanges);
      } else {
        setRanges([]);
      }
    } else {
      throw Exception('Failed to load data for $date');
    }
  }

  Future<void> cacheData(String date, List<Range> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = json.encode(data.map((range) => range.toJson()).toList());
    await prefs.setString('cached_data_$date', jsonData);
  }

  Future<List<Range>> loadCachedData(String date) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('cached_data_$date');
    if (jsonData != null) {
      final List<dynamic> decodedData = json.decode(jsonData);
      return decodedData.map((item) => Range.fromJson(item)).toList();
    }
    return [];
  }

  String formatDate(DateTime date) {
    final localDate = date.toLocal();
    final DateFormat dayMonthFormat = DateFormat('dd.MM');
    final DateFormat dayMonthWordsFormat = DateFormat('d MMMM', 'uk');
    return '${dayMonthFormat.format(localDate)} (${dayMonthWordsFormat.format(localDate)})';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Графік відключення світла'),
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          children: [
            Center(
              child: DropdownButton<Range>(
                hint: const Text('Оберіть чергу'),
                value: ranges.contains(selectedRange) ? selectedRange : null,
                onChanged: (Range? newValue) {
                  setState(() {
                    selectedRange = newValue;
                    valueIndex =
                        newValue != null ? ranges.indexOf(newValue) : null;
                    nextDaySelectedRange =
                        valueIndex != null && nextDayRanges.isNotEmpty
                            ? nextDayRanges[valueIndex!]
                            : null;
                  });
                  if (newValue != null) {
                    saveLastSelectedQueue(newValue.name);
                  }
                },
                items: ranges.map<DropdownMenuItem<Range>>((Range range) {
                  return DropdownMenuItem<Range>(
                    value: range,
                    child: Text(range.name),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (selectedRange != null) ...[
              Center(
                child: Text('Сьогодні: ${formatDate(selectedRange!.date)}'),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: CircularTimeChart(
                  title: 'ПІДЧЕРГА',
                  range: selectedRange!,
                ),
              ),
              Center(
                child: Text(
                    'Завтра: ${formatDate(selectedRange!.date.add(const Duration(days: 1)))}'),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: nextDaySelectedRange != null
                    ? CircularTimeChart(
                        title: 'ПІДЧЕРГА',
                        range: nextDaySelectedRange!,
                      )
                    : const Center(
                        child: Text('Розклад відсутній'),
                      ),
              ),
            ] else
              const Center(
                child: Text('Будь ласка, оберіть чергу'),
              ),
          ],
        ),
      ),
    );
  }
}
