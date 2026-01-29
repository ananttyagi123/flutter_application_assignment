import 'package:intl/intl.dart';

final _money = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

String formatMoney(num value) => _money.format(value);

