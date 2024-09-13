import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:svitloif/models/range_model.dart';


class DetailPage extends StatelessWidget {
  final Range range;

  const DetailPage({super.key, required this.range});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Деталі'),
      ),
      body: Material(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Дата: ${customFormatDate(range.date)}',
              ),
              const SizedBox(height: 10),
              Text(
                'Години відключення: ${formatIntervals(range.off)}',
              ),
              const SizedBox(height: 10),
              Text(
                'Можливі вимкнення: ${formatIntervals(range.maybe)}',
              ),
              const SizedBox(height: 10),
              Text(
                'Години увімкнення: ${formatIntervals(range.on)}',
              ),
              const SizedBox(height: 20),
              buildHourContainers(range, 0, 12),
              buildHourContainers(range, 12, 24),
            ],
          ),
        ),
      ),
    );
  }

  String formatIntervals(List<List<int>> intervals) {
    return intervals
        .map((interval) => '${interval[0]}-${interval[1]}')
        .join(', ');
  }

  String customFormatDate(DateTime date) {
    final localDate = date.toLocal();
    final formatter = DateFormat.yMMMMd().add_Hm();
    return formatter.format(localDate);
  }

  Widget buildHourContainers(Range range, int start, int end) {
    return Row(
      children: List.generate(end - start, (index) {
        int hour = start + index;
        Color bgColor = getColorForHour(hour, range);
        return Container(
          width: 30,
          height: 30,
          color: bgColor,
          child: Center(
            child: Text(
              '$hour-${(hour + 1) % 24}',
              style: const TextStyle(fontSize: 10, color: Colors.white),
            ),
          ),
        );
      }),
    );
  }

  Color getColorForHour(int hour, Range range) {
    if (isInInterval(hour, range.off)) {
      return Colors.red;
    } else if (isInInterval(hour, range.on)) {
      return Colors.green;
    } else if (isInInterval(hour, range.maybe)) {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  bool isInInterval(int hour, List<List<int>> intervals) {
    for (var interval in intervals) {
      if (hour >= interval[0] && hour < interval[1]) {
        return true;
      }
    }
    return false;
  }
}

// class MyStyle extends TextStyle {
//   const MyStyle({
//     Color color = const Color.fromARGB(255, 0, 0, 0),
//     double fontSize = 16.0,
//     FontWeight fontWeight = FontWeight.normal,
//     FontStyle fontStyle = FontStyle.normal,
//     double letterSpacing = 0.0,
//     double wordSpacing = 0.0,
//     TextDecoration decoration = TextDecoration.none,
//   }) : super(
//           color: color,
//           fontSize: fontSize,
//           fontWeight: fontWeight,
//           fontStyle: fontStyle,
//           letterSpacing: letterSpacing,
//           wordSpacing: wordSpacing,
//           decoration: decoration,
//         );
// }
