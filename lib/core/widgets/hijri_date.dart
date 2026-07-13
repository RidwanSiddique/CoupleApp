import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

class HijriDate extends StatelessWidget {
  const HijriDate({super.key, this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final greg = date ?? DateTime.now();
    final hijri = HijriCalendar.fromDate(greg);
    final gregLabel = DateFormat('d MMM yyyy').format(greg);
    final hijriLabel =
        '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}';

    return Text(
      '$hijriLabel  ·  $gregLabel',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
