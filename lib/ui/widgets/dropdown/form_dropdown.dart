import 'package:flutter/material.dart';
import 'package:tlobni/ui/widgets/dropdown/dropdown.dart';
import 'package:tlobni/utils/extensions/extensions.dart';

class FormDropdown<T> extends StatelessWidget {
  const FormDropdown({
    super.key,
    this.items,
    this.entries,
    this.hint,
    this.borderColor,
    this.allowSearch = false,
    required this.selectedValue,
    required this.onSelected,
  });

  final List<(T, String)>? items;
  final List<DropdownMenuEntry<T>>? entries;
  final bool allowSearch;
  final String? hint;
  final Color? borderColor;
  final T? selectedValue;
  final bool? Function(T? value) onSelected;

  @override
  Widget build(BuildContext context) {
    assert(items != null || entries != null);
    final borderColor = this.borderColor ?? Color(0xffe6e6e6);
    return MyDropdownMenu<T>(
      expandFormField: false,
      selectedValue: selectedValue,
      onSelected: onSelected,
      trailingIcon: SizedBox(),
      textStyle: context.textTheme.bodyMedium,
      takeSelectedValue: true,
      requestFocusOnTap: allowSearch,
      enableSearch: allowSearch,
      hintText: hint,
      enableFilter: allowSearch,
      inputDecorationTheme: InputDecorationThemeData(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: borderColor),
        ),
        contentPadding: EdgeInsets.all(13),
      ),
      menuStyle: MenuStyle(
        maximumSize: WidgetStatePropertyAll(Size(double.infinity, 500)),
        minimumSize: WidgetStatePropertyAll(Size(double.infinity, 500)),
        side: WidgetStatePropertyAll(BorderSide(color: borderColor)),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      ),
      dropdownMenuEntries: items
              ?.map((e) => DropdownMenuEntry(
                    value: e.$1,
                    label: e.$2,
                    style: ButtonStyle(
                      padding: WidgetStatePropertyAll(
                        EdgeInsets.all(10),
                      ),
                    ),
                  ))
              .toList() ??
          entries ??
          [],
    );
  }
}
