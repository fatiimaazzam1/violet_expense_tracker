import 'package:intl/intl.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static String format(double amount, String symbol) {
    return NumberFormat.currency(
      locale: 'en_US',
      symbol: symbol,
    ).format(amount);
  }
}
