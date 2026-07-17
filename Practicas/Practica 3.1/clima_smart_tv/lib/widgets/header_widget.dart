import 'package:flutter/material.dart';

import '../utils/text_styles.dart';
import 'clock_widget.dart';

class HeaderWidget extends StatelessWidget {
  final String city;

  const HeaderWidget({
    super.key,
    required this.city,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        96,
        54,
        96,
        24,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              city,
              style: TVTextStyles.header,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const ClockWidget(),
        ],
      ),
    );
  }
}