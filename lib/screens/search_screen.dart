import 'package:flutter/material.dart';

import '../navigation/erp_forms.dart';
import '../theme/app_theme.dart';
import '../widgets/page_header.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.onMenu});

  final VoidCallback onMenu;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<ErpFormEntry> get _results {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return erpForms;
    return [
      for (final form in erpForms)
        if (form.title.toLowerCase().contains(query)) form,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    final horizontal = MediaQuery.sizeOf(context).width >= 600 ? 28.0 : 16.0;
    final countLabel = results.length == 1
        ? '1 form'
        : '${results.length} forms';

    return Column(
      children: [
        PageHeader(title: 'Search', onMenu: widget.onMenu),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Search form names',
                  prefixIcon: const Icon(Icons.search),
                  fillColor: AppTheme.cardColor(context),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Search ERP form names',
                style: TextStyle(
                  color: AppTheme.secondaryText(context),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                countLabel,
                style: TextStyle(
                  color: AppTheme.secondaryText(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (results.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 36),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 36,
                        color: AppTheme.secondaryText(context),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No forms match "${_query.trim()}"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.primaryText(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final form in results) ...[
                  _FormResult(form: form),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FormResult extends StatelessWidget {
  const _FormResult({required this.form});

  final ErpFormEntry form;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardColor(context),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.dividerColor(context)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          final route = erpFormRoute(form);
          if (route != null) {
            Navigator.of(context).push(route);
            return;
          }
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  '${form.title} will be available in a future update.',
                ),
              ),
            );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.forest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(form.icon, color: AppColors.forest, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.title,
                      style: TextStyle(
                        color: AppTheme.primaryText(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ERP form',
                      style: TextStyle(
                        color: AppTheme.secondaryText(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.secondaryText(context)),
            ],
          ),
        ),
      ),
    );
  }
}
