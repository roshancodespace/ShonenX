import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/widgets/ui/shonenx_icon_btn.dart';

class NextButton extends StatelessWidget {
  const NextButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShonenXIconButton(
      icon: Iconsax.next,
      onPressed: () {},
      label: 'Next',
    );
  }
}
