import 'package:flutter/foundation.dart';

import '../models/calc_state.dart';

enum _TokenType { number, operatorToken }

class _Token {
  _TokenType type;
  String value;
  _Token(this.type, this.value);
}

class _DivisionByZeroException implements Exception {}

/// Maximum count of digits (excluding sign and decimal point) allowed in a
/// single number, per spec.
const int _kMaxDigits = 15;

/// Core calculator logic: builds up an expression token-by-token as the
/// user presses buttons, live-evaluates it using standard operator
/// precedence (BODMAS), and finalizes on "=".
///
/// This class is intentionally UI-agnostic — [CalcScreen] just listens to
/// it via [ChangeNotifier] and renders whatever [state] returns.
class CalcEngine extends ChangeNotifier {
  final List<_Token> _tokens = [];

  /// True immediately after "=" has produced a final result and no new
  /// input has been entered yet.
  bool _isResultDisplayed = false;

  /// The numeric value of the last finalized result, used to continue a
  /// calculation when an operator is pressed right after "=".
  /// Null when the last result was "Undefined" (division by zero).
  double? _lastResultValue;

  /// Current display state (expression + live/final result).
  CalcState get state => CalcState(
        expression: _expressionDisplay,
        result: _isResultDisplayed ? '' : (_computeLiveResult() ?? ''),
      );

  // ---------------------------------------------------------------------
  // Public input handlers — one per button type.
  // ---------------------------------------------------------------------

  void inputDigit(String digit) {
    assert(digit.length == 1 && '0123456789'.contains(digit));
    if (_isResultDisplayed) {
      clear();
    }
    _ensureEditableNumberToken();
    final token = _tokens.last;
    token.value = _appendDigit(token.value, digit);
    notifyListeners();
  }

  void inputDoubleZero() {
    if (_isResultDisplayed) {
      clear();
    }
    _ensureEditableNumberToken();
    final token = _tokens.last;

    final unsigned =
        token.value.startsWith('-') ? token.value.substring(1) : token.value;
    final buildingIntegerPart = !unsigned.contains('.');
    final integerPart =
        buildingIntegerPart ? unsigned : unsigned.split('.').first;

    if (buildingIntegerPart && (integerPart.isEmpty || integerPart == '0')) {
      // "00" on an empty/zero number should still just be a single zero.
      token.value = _appendDigit(token.value, '0');
    } else {
      token.value = _appendDigit(token.value, '0');
      token.value = _appendDigit(token.value, '0');
    }
    notifyListeners();
  }

  void inputDecimal() {
    if (_isResultDisplayed) {
      clear();
    }
    _ensureEditableNumberToken();
    final token = _tokens.last;

    if (token.value.contains('.')) {
      // A number may contain only one decimal point — ignore.
      notifyListeners();
      return;
    }

    if (token.value.isEmpty) {
      token.value = '0.';
    } else if (token.value == '-') {
      token.value = '-0.';
    } else {
      token.value = '${token.value}.';
    }
    notifyListeners();
  }

  /// [op] is one of '+', '-', '*', '/' (internal representation — the
  /// display layer maps these to +, −, ×, ÷).
  void inputOperator(String op) {
    if (_isResultDisplayed) {
      if (_lastResultValue == null) {
        // Can't continue from "Undefined" — start fresh.
        clear();
        notifyListeners();
        return;
      }
      final continuation = _lastResultValue!;
      _tokens
        ..clear()
        ..add(_Token(_TokenType.number, _formatNumber(continuation)));
      _isResultDisplayed = false;
      _lastResultValue = null;
    }

    if (_tokens.isEmpty) {
      // Only "-" is allowed to start an expression (begins a negative
      // number).
      if (op == '-') {
        _tokens.add(_Token(_TokenType.number, '-'));
      }
      notifyListeners();
      return;
    }

    final last = _tokens.last;
    if (last.type == _TokenType.operatorToken) {
      if (op == '-') {
        // A minus right after an operator starts a negative number,
        // rather than acting as another operator.
        _tokens.add(_Token(_TokenType.number, '-'));
      } else {
        // Consecutive operators: the new one replaces the old one.
        last.value = op;
      }
      notifyListeners();
      return;
    }

    // last is a number token.
    if (last.value.isEmpty || last.value == '-') {
      // Incomplete number (lone sign, no digits yet) — ignore.
      notifyListeners();
      return;
    }
    _tokens.add(_Token(_TokenType.operatorToken, op));
    notifyListeners();
  }

  void backspace() {
  if (_isResultDisplayed) {
    _isResultDisplayed = false;
    _lastResultValue = null;
  }

  if (_tokens.isEmpty) return;

  final last = _tokens.last;

  if (last.value.length <= 1) {
    _tokens.removeLast();
  } else {
    last.value = last.value.substring(0, last.value.length - 1);
  }

  notifyListeners();
}

  void clear() {
    _tokens.clear();
    _isResultDisplayed = false;
    _lastResultValue = null;
    notifyListeners();
  }

  /// Intentionally non-functional in v1.0 — the button exists in the UI
  /// but has no effect on the expression or result, per spec.
  void percent() {
    // No-op by design.
  }

  void equals() {
    if (_isResultDisplayed) return; // Repeated "=" does nothing.
    if (_tokens.isEmpty) return;

    final evalTokens = _prepareForEvaluation(requireComplete: true);
    if (evalTokens == null) return; // Incomplete/invalid — do nothing.

    try {
      final value = _evaluate(evalTokens);
      _lastResultValue = value;
      _tokens
        ..clear()
        ..add(_Token(_TokenType.number, _formatNumber(value)));
      _isResultDisplayed = true;
    } on _DivisionByZeroException {
      _lastResultValue = null;
      _tokens
        ..clear()
        ..add(_Token(_TokenType.number, 'Undefined'));
      _isResultDisplayed = true;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------

  void _ensureEditableNumberToken() {
    if (_tokens.isEmpty || _tokens.last.type == _TokenType.operatorToken) {
      _tokens.add(_Token(_TokenType.number, ''));
    }
  }

  /// Appends [digit] to [current] respecting the "no leading zeros" and
  /// "max 15 digits" rules.
  String _appendDigit(String current, String digit) {
    final sign = current.startsWith('-') ? '-' : '';
    final rest = current.startsWith('-') ? current.substring(1) : current;

    final dotIndex = rest.indexOf('.');
    final hasDecimal = dotIndex != -1;
    String integerPart = hasDecimal ? rest.substring(0, dotIndex) : rest;
    String fractionPart = hasDecimal ? rest.substring(dotIndex) : ''; // incl "."

    final totalDigits =
        (integerPart + fractionPart.replaceAll('.', '')).length;
    if (totalDigits >= _kMaxDigits) {
      return current; // Ignore — number is already at max length.
    }

    if (!hasDecimal) {
      if (integerPart.isEmpty) {
        integerPart = digit;
      } else if (integerPart == '0') {
        // No leading zeros: replace the placeholder zero unless another
        // zero was pressed, in which case it just stays a single "0".
        integerPart = digit;
      } else {
        integerPart += digit;
      }
    } else {
      fractionPart += digit;
    }

    return '$sign$integerPart$fractionPart';
  }

  /// Builds the expression string exactly as it should be displayed,
  /// mapping internal operator characters to their display glyphs.
  String get _expressionDisplay {
    final buffer = StringBuffer();
    for (final token in _tokens) {
      if (token.type == _TokenType.operatorToken) {
        buffer.write(_operatorSymbol(token.value));
      } else {
        buffer.write(token.value);
      }
    }
    return buffer.toString();
  }

  String _operatorSymbol(String op) {
    switch (op) {
      case '+':
        return '+';
      case '-':
        return '−';
      case '*':
        return '×';
      case '/':
        return '÷';
      default:
        return op;
    }
  }

  /// Returns the live-evaluated result string, or null if there's nothing
  /// meaningful to show yet (e.g. expression is just "-").
  String? _computeLiveResult() {
    final evalTokens = _prepareForEvaluation(requireComplete: false);
    if (evalTokens == null) return null;
    try {
      final value = _evaluate(evalTokens);
      return _formatNumber(value);
    } on _DivisionByZeroException {
      return 'Undefined';
    }
  }

  /// Produces a clean, evaluable copy of the token list, trimming any
  /// trailing operator or incomplete number.
  ///
  /// When [requireComplete] is true (used by "="), an incomplete/trailing
  /// operator or number makes the whole expression invalid (returns null)
  /// rather than being silently trimmed.
  List<_Token>? _prepareForEvaluation({required bool requireComplete}) {
    if (_tokens.isEmpty) return null;

    final working =
        _tokens.map((t) => _Token(t.type, t.value)).toList(growable: true);

    if (working.last.type == _TokenType.operatorToken) {
      if (requireComplete) return null;
      working.removeLast();
      if (working.isEmpty) return null;
    }

    final lastValue = working.last.value;
    if (_parsePartialNumber(lastValue) == null) {
      if (requireComplete) return null;
      working.removeLast();
      if (working.isNotEmpty &&
          working.last.type == _TokenType.operatorToken) {
        working.removeLast();
      }
      if (working.isEmpty) return null;
    }

    return working;
  }

  /// Parses a number token's raw text into a double, tolerating a
  /// trailing decimal point (e.g. "5." -> 5.0). Returns null for
  /// anything not yet a valid number (e.g. "", "-", ".", "-.").
  double? _parsePartialNumber(String value) {
    if (value.isEmpty || value == '-') return null;
    var v = value;
    if (v.endsWith('.')) v = v.substring(0, v.length - 1);
    if (v.isEmpty || v == '-') return null;
    return double.tryParse(v);
  }

  /// Evaluates a valid, alternating number/operator token list using
  /// standard operator precedence (× and ÷ before + and −), i.e. BODMAS.
  double _evaluate(List<_Token> evalTokens) {
    final numbers = <double>[];
    final operators = <String>[];
    for (final token in evalTokens) {
      if (token.type == _TokenType.number) {
        numbers.add(_parsePartialNumber(token.value) ?? 0);
      } else {
        operators.add(token.value);
      }
    }

    // Pass 1: resolve × and ÷ (left to right).
    final passOneNumbers = <double>[numbers.first];
    final passOneOperators = <String>[];
    for (var i = 0; i < operators.length; i++) {
      final op = operators[i];
      final nextNumber = numbers[i + 1];
      if (op == '*') {
        passOneNumbers[passOneNumbers.length - 1] =
            passOneNumbers.last * nextNumber;
      } else if (op == '/') {
        if (nextNumber == 0) throw _DivisionByZeroException();
        passOneNumbers[passOneNumbers.length - 1] =
            passOneNumbers.last / nextNumber;
      } else {
        passOneNumbers.add(nextNumber);
        passOneOperators.add(op);
      }
    }

    // Pass 2: resolve + and − (left to right).
    var result = passOneNumbers.first;
    for (var i = 0; i < passOneOperators.length; i++) {
      if (passOneOperators[i] == '+') {
        result += passOneNumbers[i + 1];
      } else {
        result -= passOneNumbers[i + 1];
      }
    }
    return result;
  }

  /// Formats a double as a clean, human-friendly result string: trailing
  /// zeros trimmed, huge magnitudes shown in scientific notation.
  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return 'Undefined';

    if (value != 0 && value.abs() >= 1e15) {
      return _formatScientific(value);
    }

    var s = value.toStringAsFixed(10);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      s = s.replaceAll(RegExp(r'\.$'), '');
    }
    if (s == '-0') s = '0';
    return s;
  }

  String _formatScientific(double value) {
    final raw = value.toStringAsExponential(6); // e.g. "1.234500e+15"
    final parts = raw.split('e');
    var mantissa = parts[0];
    if (mantissa.contains('.')) {
      mantissa = mantissa.replaceAll(RegExp(r'0+$'), '');
      mantissa = mantissa.replaceAll(RegExp(r'\.$'), '');
    }
    var exponent = parts[1];
    if (exponent.startsWith('+')) exponent = exponent.substring(1);
    return '${mantissa}e$exponent';
  }
}
