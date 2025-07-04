import 'package:flutter/material.dart';

class TagsField extends StatefulWidget {
  final List<String> initialTags;
  final Function(List<String>) onTagsChanged;
  final String? labelText;
  final String? hintText;

  const TagsField({
    super.key,
    this.initialTags = const [],
    required this.onTagsChanged,
    this.labelText,
    this.hintText,
  });

  @override
  State<TagsField> createState() => _TagsFieldState();
}

class _TagsFieldState extends State<TagsField> {
  final TextEditingController _controller = TextEditingController();
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
    
    // Set the initial text to comma-separated tags
    if (_tags.isNotEmpty) {
      _controller.text = _tags.join(', ');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateTags(String value) {
    if (value.isEmpty) {
      if (_tags.isNotEmpty) {
        setState(() {
          _tags = [];
          widget.onTagsChanged(_tags);
        });
      }
      return;
    }

    final newTags = value
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    if (_listEquals(newTags, _tags)) return;

    setState(() {
      _tags = newTags;
      widget.onTagsChanged(_tags);
    });
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.labelText ?? 'Tags',
            hintText: widget.hintText ?? 'Enter tags separated by commas',
            helperText: 'e.g. academic, online, 2025',
          ),
          onChanged: _updateTags,
        ),
        if (_tags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _tags.map((tag) => Chip(
                label: Text(tag),
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                visualDensity: VisualDensity.compact,
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                    _controller.text = _tags.join(', ');
                    widget.onTagsChanged(_tags);
                  });
                },
              )).toList(),
            ),
          ),
      ],
    );
  }
}
