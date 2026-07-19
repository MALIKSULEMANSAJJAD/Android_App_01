import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class CalcDisplay extends StatelessWidget {
  final String expression;
  final String result;

  const CalcDisplay({
    super.key,
    required this.expression,
    required this.result,
  });

 @override
Widget build(BuildContext context) {
  return Expanded(
    flex: 3,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 8),
      alignment: Alignment.bottomRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SingleChildScrollView(
            reverse: true,
            scrollDirection: Axis.horizontal,
            child: Text(
              expression,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.expressionText,
                fontSize: 56,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),

          const SizedBox(height: 8),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              result,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.resultText,
                fontSize: 40,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}