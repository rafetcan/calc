class CalculatorModel {
  String expression;
  String result;

  CalculatorModel({this.expression = '', this.result = ''});

  CalculatorModel copyWith({String? expression, String? result}) {
    return CalculatorModel(
      expression: expression ?? this.expression,
      result: result ?? this.result,
    );
  }
}
