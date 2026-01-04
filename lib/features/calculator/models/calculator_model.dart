class CalculatorModel {
  String displayText = '';
  String result = '';
  bool hasError = false;

  void clear() {
    displayText = '';
    result = '';
    hasError = false;
  }

  bool get canCalculate {
    return displayText.isNotEmpty &&
        !_endsWithOperator(displayText) &&
        !hasError;
  }

  bool _endsWithOperator(String text) {
    return text.endsWith('+') ||
        text.endsWith('-') ||
        text.endsWith('×') ||
        text.endsWith('÷');
  }
}
