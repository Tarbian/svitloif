import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:svitloif/models/range_model.dart';

class DataService {
  static Future<void> loadDataForDate(
      String date, Function(List<Range>) setRanges) async {
    final url = 'https://poweroff.if.ua/schedule?date=$date';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['ranges'] != null) {
        final List<Range> loadedRanges = List<Range>.from(
            data['ranges'].map((item) => Range.fromJson(item)));
        setRanges(loadedRanges);
        await cacheData(date, loadedRanges);
      } else {
        setRanges([]);
      }
    } else {
      throw Exception('Failed to load data for $date');
    }
  }

  static Future<void> cacheData(String date, List<Range> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = json.encode(data.map((range) => range.toJson()).toList());
    await prefs.setString('cached_data_$date', jsonData);
  }
}
