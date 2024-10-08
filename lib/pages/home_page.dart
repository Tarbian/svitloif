import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svitloif/services/data_service.dart';
import 'package:svitloif/widgets/circular_time_chart.dart';
import 'package:svitloif/models/range_model.dart';
import 'package:svitloif/pages/settings_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  final ThemeMode currentThemeMode;
  final ValueChanged<bool> onThemeChanged;

  const HomePage({
    super.key,
    required this.currentThemeMode,
    required this.onThemeChanged,
  });

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
  bool hasShownHelp = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('uk', null).then((_) {
      loadData();
      checkAndShowHelp();
    });
  }

  Future<void> checkAndShowHelp() async {
    final prefs = await SharedPreferences.getInstance();
    hasShownHelp = prefs.getBool('hasShownHelp') ?? false;
    if (!hasShownHelp) {
      Future.delayed(Duration.zero, () {
        showHelpDialog();
      });
    }
  }

  Future<void> showHelpDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Умовні позначення:'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('🟢 Зелений - відключень немає'),
              Text('🟡 Жовтий - можливе відключення'),
              Text('🔴 Червоний - буде відключення'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    if (!hasShownHelp) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasShownHelp', true);
      setState(() {
        hasShownHelp = true;
      });
    }
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
        DataService.loadDataForDate(today, (data) => newRanges = data),
        DataService.loadDataForDate(
            tomorrow, (data) => newNextDayRanges = data),
      ]);

      setState(() {
        ranges = newRanges;
        nextDayRanges = newNextDayRanges;
        isLoading = false;
      });

      await loadLastSelectedQueue();
    } catch (error) {
      final cachedRanges = await loadCachedData(today);
      final cachedNextDayRanges = await loadCachedData(tomorrow);

      setState(() {
        ranges = cachedRanges;
        nextDayRanges = cachedNextDayRanges;
        isLoading = false;
      });

      await loadLastSelectedQueue();

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(
                    currentThemeMode: widget.currentThemeMode,
                    onThemeChanged: widget.onThemeChanged,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: ListView(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Container(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.help_outline),
                      onPressed: showHelpDialog,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  child: DropdownButton<Range>(
                    hint: const Text('Оберіть чергу'),
                    value:
                        ranges.contains(selectedRange) ? selectedRange : null,
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
                Flexible(
                  child: Container(
                    alignment: Alignment.centerRight,
                  ),
                ),
              ],
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
