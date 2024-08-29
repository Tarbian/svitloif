import 'package:flutter/material.dart';
import 'dart:math';
import 'range_model.dart';

class CircularTimeChart extends StatelessWidget {
  final String title;
  final Range range;

  const CircularTimeChart({
    Key? key,
    this.title = "ПІДЧЕРГА",
    required this.range,
  }) : super(key: key);

  List<TimeSegment> _getTimeSegments() {
    List<TimeSegment> segments = [];
    for (int hour = 0; hour < 24; hour++) {
      Color color = _getColorForHour(hour);
      segments.add(TimeSegment(hour, hour + 1, color));
    }
    return segments;
  }

  Color _getColorForHour(int hour) {
    if (_isInInterval(hour, range.off)) {
      return const Color.fromARGB(255, 252, 104, 104);
    } else if (_isInInterval(hour, range.on)) {
      return const Color.fromARGB(255, 125, 204, 113);
    } else if (_isInInterval(hour, range.maybe)) {
      return const Color.fromARGB(255, 253, 217, 94);
    } else {
      return Colors.grey;
    }
  }

  bool _isInInterval(int hour, List<List<int>> intervals) {
    for (var interval in intervals) {
      if (hour >= interval[0] && hour < interval[1]) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: CircularTimeChartPainter(
              title: title,
              number: range.name,
              segments: _getTimeSegments(),
            ),
          ),
        );
      },
    );
  }
}

class CircularTimeChartPainter extends CustomPainter {
  final String title;
  final String number;
  final List<TimeSegment> segments;

  CircularTimeChartPainter({
    required this.title,
    required this.number,
    required this.segments,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.5;

    for (int i = 0; i < 24; i++) {
      final startAngle = (i * 15 - 90) * (pi / 180);
      final endAngle = ((i + 1) * 15 - 90) * (pi / 180);

      final segment = segments[i];

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        (endAngle - startAngle) * 0.95,
        true,
        paint,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$i-${(i + 1) % 25}',
          style: const TextStyle(color: Colors.black, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textCenter = center +
          Offset.fromDirection(
            (startAngle + endAngle - 0.015) / 2,
            (radius + innerRadius) / 1.7,
          );
      textPainter.paint(canvas,
          textCenter - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    final innerCirclePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerCirclePaint);

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: const TextStyle(color: Colors.black, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    );
    titlePainter.layout();
    titlePainter.paint(canvas, center + Offset(-titlePainter.width / 2, -20));

    final numberPainter = TextPainter(
      text: TextSpan(
        text: number,
        style: const TextStyle(
            color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    numberPainter.layout();
    numberPainter.paint(canvas, center + Offset(-numberPainter.width / 2, 0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TimeSegment {
  final int startHour;
  final int endHour;
  final Color color;

  TimeSegment(this.startHour, this.endHour, this.color);
}
