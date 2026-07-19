import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/calc_engine.dart';
import '../widgets/calc_button.dart';
import '../widgets/calc_display.dart';

class CalcScreen extends StatefulWidget {
  const CalcScreen({super.key});

  @override
  State<CalcScreen> createState() => _CalcScreenState();
}

class _CalcScreenState extends State<CalcScreen> {
  late final CalcEngine engine;

  @override
  void initState() {
    super.initState();
    engine = CalcEngine();
  }

  @override
  void dispose() {
    engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: engine,
      builder: (context, _) {
        final state = engine.state;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                CalcDisplay(
                  expression: state.expression,
                  result: state.result,
                ),

                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        _buildRow([
                          CalcButton(
                            text: "AC",
                            onPressed: engine.clear,
                            backgroundColor: AppColors.equalsButton,
                            textColor: AppColors.equalsText,
                          ),
                          _function("%", engine.percent),
                          _function("⌫", engine.backspace),
                          _operator("÷", () => engine.inputOperator('/')),
                        ]),

                        _buildRow([
                          _number("7"),
                          _number("8"),
                          _number("9"),
                          _operator("×", () => engine.inputOperator('*')),
                        ]),

                        _buildRow([
                          _number("4"),
                          _number("5"),
                          _number("6"),
                          _operator("−", () => engine.inputOperator('-')),
                        ]),

                        _buildRow([
                          _number("1"),
                          _number("2"),
                          _number("3"),
                          _operator("+", () => engine.inputOperator('+')),
                        ]),

                        _buildRow([
                          _decimal(),
                          _number("0"),
                          _doubleZero(),
                          _equals(),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(List<Widget> children) {
    return Expanded(
      child: Row(
        children: children
            .map((button) => Expanded(child: button))
            .toList(),
      ),
    );
  }

  Widget _number(String value) {
    return CalcButton(
      text: value,
      onPressed: () => engine.inputDigit(value),
      backgroundColor: AppColors.numberButton,
      textColor: AppColors.primaryText,
    );
  }

  Widget _decimal() {
    return CalcButton(
      text: ".",
      onPressed: engine.inputDecimal,
      backgroundColor: AppColors.numberButton,
      textColor: AppColors.primaryText,
    );
  }

  Widget _doubleZero() {
    return CalcButton(
      text: "00",
      onPressed: engine.inputDoubleZero,
      backgroundColor: AppColors.numberButton,
      textColor: AppColors.primaryText,
    );
  }

  Widget _function(String text, VoidCallback action) {
    return CalcButton(
      text: text,
      onPressed: action,
      backgroundColor: AppColors.functionButton,
      textColor: AppColors.primaryText,
    );
  }

  Widget _operator(String text, VoidCallback action) {
    return CalcButton(
      text: text,
      onPressed: action,
      backgroundColor: AppColors.operatorButton,
      textColor: AppColors.operatorText,
    );
  }

  Widget _equals() {
    return CalcButton(
      text: "=",
      onPressed: engine.equals,
      backgroundColor: AppColors.equalsButton,
      textColor: AppColors.equalsText,
    );
  }
}