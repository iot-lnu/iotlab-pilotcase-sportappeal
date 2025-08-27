import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final bool isPassword;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final bool readOnly;
  final String? initialValue;

  const CustomTextField({
    super.key,
    required this.label,
    this.isPassword = false,
    this.controller,
    this.validator,
    this.readOnly = false,
    this.initialValue,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  // Add a state variable to toggle password visibility
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 227,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            readOnly: widget.readOnly,
            initialValue: widget.initialValue,
            // Use the state variable for obscureText when it's a password field
            obscureText: widget.isPassword ? _obscureText : false,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: AppTextStyles.labelStyle,
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.white, width: 1),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.accentGreen, width: 1),
              ),
              contentPadding: const EdgeInsets.only(bottom: 8),
              isDense: true,
              // Add a suffix icon if it's a password field
              suffixIcon: widget.isPassword 
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
