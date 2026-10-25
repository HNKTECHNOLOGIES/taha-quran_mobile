/// Conversion vers les chiffres arabes orientaux (٠١٢٣٤٥٦٧٨٩).
String toArabicNumerals(int value) {
  const western = '0123456789';
  const eastern = '٠١٢٣٤٥٦٧٨٩';
  return value.toString().split('').map((c) {
    final i = western.indexOf(c);
    return i >= 0 ? eastern[i] : c;
  }).join();
}
