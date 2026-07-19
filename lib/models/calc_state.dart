/// Immutable snapshot of what the display should currently show.
///
/// [expression] is the full expression line (top).
/// [result] is the live/final result line (bottom) — may be empty when
/// there is nothing meaningful to show yet.
class CalcState {
  final String expression;
  final String result;

  const CalcState({
    required this.expression,
    required this.result,
  });
}
