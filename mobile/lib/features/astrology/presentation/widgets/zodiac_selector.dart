import 'package:flutter/material.dart';
import '../../domain/entities/zodiac_sign.dart';

class ZodiacSelector extends StatefulWidget {
  final String label;
  final Function(ZodiacSign) onSelected;
  final ZodiacSign? initialValue;

  const ZodiacSelector({
    Key? key,
    required this.label,
    required this.onSelected,
    this.initialValue,
  }) : super(key: key);

  @override
  State<ZodiacSelector> createState() => _ZodiacSelectorState();
}

class _ZodiacSelectorState extends State<ZodiacSelector> {
  late ZodiacSign selectedSign;

  @override
  void initState() {
    super.initState();
    selectedSign = widget.initialValue ?? ZodiacSign.aries;
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton<ZodiacSign>(
      value: selectedSign,
      isExpanded: true,
      items: ZodiacSign.values.map((sign) {
        return DropdownMenuItem(
          value: sign,
          child: Row(
            children: [
              Text(sign.symbol, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(sign.turkishName),
            ],
          ),
        );
      }).toList(),
      onChanged: (ZodiacSign? value) {
        if (value != null) {
          setState(() => selectedSign = value);
          widget.onSelected(value);
        }
      },
    );
  }
}
