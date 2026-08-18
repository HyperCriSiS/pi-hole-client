import 'package:flutter/material.dart';

/// A generic autocomplete field widget that expands suggestions inside
/// the same container instead of using an overlay.
///
/// Features:
/// - Displays a [TextField] with a floating label style.
/// - Suggestions list is shown inside the bordered container when focused.
/// - Supports custom matching logic for filtering items.
/// - Uses an external [TextEditingController] to integrate with forms.
class AutoCompleteField<T> extends StatefulWidget {
  const AutoCompleteField({
    required this.items,
    required this.controller,
    required this.onChanged,
    required this.textOf,
    this.titleOf,
    this.subtitleOf,
    this.matches,
    this.icon,
    this.initialText,
    this.keyboardType,
    this.visualDensity,
    this.errorText,
    this.labelText = '',
    this.hintText = '',
    this.maxPopupHeight = 160,
    this.isAnimated = true,
    this.expandAnimationDurationMilliseconds = 200,
    this.contentPadding = const EdgeInsets.symmetric(vertical: 14),
    super.key,
  });

  final List<T> items;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String Function(T item) textOf;
  final String Function(T item)? titleOf;
  final String Function(T item)? subtitleOf;
  final bool Function(T item, String query)? matches;
  final String labelText;
  final String hintText;
  final IconData? icon;
  final double maxPopupHeight;
  final String? initialText;
  final TextInputType? keyboardType;
  final EdgeInsetsGeometry contentPadding;
  final int expandAnimationDurationMilliseconds;
  final bool isAnimated;
  final VisualDensity? visualDensity;
  final String? errorText;

  @override
  State<AutoCompleteField<T>> createState() => _AutoCompleteFieldState<T>();
}

class _AutoCompleteFieldState<T> extends State<AutoCompleteField<T>> {
  late FocusNode _focusNode;
  late TextEditingController _textCtrl;
  late bool _isExpanded;

  String? _selectedText;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _textCtrl = widget.controller;
    _isExpanded = false;

    if ((widget.initialText ?? '').isNotEmpty) {
      _textCtrl.text = widget.initialText!;
      _selectedText = widget.initialText;
    }

    _focusNode.addListener(() {
      setState(() => _isExpanded = _focusNode.hasFocus);
    });

    _textCtrl.addListener(() {
      widget.onChanged(_textCtrl.text);
      if (_focusNode.hasFocus && !_isExpanded) {
        setState(() => _isExpanded = true);
      } else if (!_focusNode.hasFocus &&
          _textCtrl.text.isEmpty &&
          _isExpanded) {
        setState(() => _isExpanded = false);
      }

      if (_selectedText != null && _selectedText != _textCtrl.text) {
        _selectedText = null;
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  List<T> _filteredItems() {
    final q = _textCtrl.text.toLowerCase();
    if (q.isEmpty) return widget.items;
    if (widget.matches != null) {
      return widget.items.where((it) => widget.matches!(it, q)).toList();
    }

    final titleOf = widget.titleOf;
    final subtitleOf = widget.subtitleOf;
    return widget.items.where((it) {
      final text = widget.textOf(it).toLowerCase();
      final title = (titleOf?.call(it) ?? widget.textOf(it)).toLowerCase();
      final sub = (subtitleOf?.call(it) ?? '').toLowerCase();
      return text.contains(q) || title.contains(q) || sub.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isError = (widget.errorText ?? '').isNotEmpty;
    final hasValue = _textCtrl.text.isNotEmpty || _isExpanded;
    final borderColor = isError
        ? theme.colorScheme.error
        : _isExpanded
        ? primary
        : theme.dividerColor;
    final labelVisible = widget.labelText.isNotEmpty && hasValue;

    final items = _filteredItems();

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: borderColor,
                  width: _isExpanded ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  TextField(
                    textAlignVertical: TextAlignVertical.center,
                    controller: _textCtrl,
                    focusNode: _focusNode,
                    keyboardType: widget.keyboardType ?? TextInputType.text,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      prefixIcon: widget.icon != null
                          ? Icon(
                              size: 24.0,
                              widget.icon,
                              color: theme.colorScheme.onSurfaceVariant,
                            )
                          : null,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: widget.contentPadding,
                    ),
                  ),
                  // The suggestions are visually part of the field. Keep them
                  // in the same tap group so desktop mouse interactions do not
                  // dismiss the TextField before a suggestion/scrollbar can act.
                  TextFieldTapRegion(child: _buildSuggestions(items)),
                ],
              ),
            ),
            if (isError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  widget.errorText!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        if (labelVisible)
          Positioned(
            left: 12,
            top: 3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Text(
                widget.labelText,
                style: TextStyle(
                  fontSize: 12,
                  color: isError
                      ? theme.colorScheme.error
                      : _isExpanded
                      ? primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestions(List<T> items) {
    final listView = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxPopupHeight),
      child: Material(
        type: MaterialType.transparency,
        child: ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final it = items[index];
            final title = widget.titleOf?.call(it) ?? widget.textOf(it);
            final subtitle = widget.subtitleOf?.call(it);

            return ListTile(
              visualDensity: widget.visualDensity,
              title: Text(title),
              subtitle: subtitle != null
                  ? Text(subtitle, overflow: TextOverflow.ellipsis)
                  : null,
              onTap: () {
                final text = widget.textOf(it);
                setState(() {
                  _textCtrl.text = text;
                  _textCtrl.selection = TextSelection.fromPosition(
                    TextPosition(offset: _textCtrl.text.length),
                  );
                  _selectedText = text;
                  _isExpanded = false;
                });
                widget.onChanged(text);
                _focusNode.unfocus();
              },
            );
          },
        ),
      ),
    );

    if (!widget.isAnimated) {
      return _isExpanded ? listView : const SizedBox.shrink();
    }

    return AnimatedSize(
      duration: Duration(
        milliseconds: widget.expandAnimationDurationMilliseconds,
      ),
      curve: Curves.easeInOut,
      child: _isExpanded ? listView : const SizedBox.shrink(),
    );
  }
}
