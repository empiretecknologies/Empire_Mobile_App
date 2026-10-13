import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../api/api_client.dart';
import '../models/dashboard_summary.dart';
import '../services/dashboard_service.dart';
import '../session/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import 'login_screen.dart';

class CityOutstandingScreen extends StatefulWidget {
  const CityOutstandingScreen({super.key, required this.city});

  final String city;

  @override
  State<CityOutstandingScreen> createState() => _CityOutstandingScreenState();
}

class _CityOutstandingScreenState extends State<CityOutstandingScreen> {
  final _dashboardService = DashboardService();

  bool _loading = true;
  bool _exporting = false;
  bool _leaving = false;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!(_loading && _error == null && _rows.isEmpty) && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final rows = await _dashboardService.getCityOutstanding(widget.city);
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.isUnauthorized) {
        _leave();
        return;
      }
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  void _leave() {
    if (_leaving || !mounted) return;
    _leaving = true;
    AppSession.instance.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _export() async {
    if (_rows.isEmpty || _exporting) return;
    setState(() => _exporting = true);
    try {
      final bytes = await _buildCityOutstandingPdf(
        city: widget.city,
        rows: _rows,
      );
      final safe = widget.city.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Outstanding-${safe.isEmpty ? 'city' : safe}.pdf',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to export the PDF.')),
        );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width >= 600 ? 28.0 : 16.0;

    return AppThemeScope(
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: AppTheme.pageBackground(context),
            appBar: AppBar(
              backgroundColor: AppColors.forestDeep,
              foregroundColor: AppColors.onForest,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text(
                widget.city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
                  child: const Text(
                    'City-wise Outstanding Balance',
                    style: TextStyle(
                      color: AppColors.forest,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 0),
                  child: AppButton(
                    label: 'Export PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    loading: _exporting,
                    onPressed: _rows.isEmpty || _exporting
                        ? null
                        : () {
                            _export();
                          },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(child: _body(context, horizontal)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, double horizontal) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppColors.forest,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Loading report...',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFC62828), fontSize: 13),
              ),
              TextButton(
                onPressed: () {
                  _load();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_rows.isEmpty) {
      return const Center(
        child: Text(
          'No records for this city.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 12),
      child: _CityReport(rows: _rows),
    );
  }
}

class _CityReport extends StatelessWidget {
  const _CityReport({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final layout = _cityColumns(rows);
    if (layout.keys.isEmpty) {
      return const Center(
        child: Text(
          'No records for this city.',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: Material(
            clipBehavior: Clip.antiAlias,
            color: AppTheme.cardColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.dividerColor(context)),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final widths = _columnWidths(constraints.maxWidth, layout);
                final tableWidth = widths.fold<double>(
                  0,
                  (sum, width) => sum + width,
                );
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: tableWidth,
                    height: constraints.maxHeight,
                    child: Column(
                      children: [
                        _ReportHeader(layout: layout, widths: widths),
                        Expanded(
                          child: ListView.builder(
                            itemCount: rows.length,
                            itemBuilder: (context, index) {
                              return _ReportDataRow(
                                row: rows[index],
                                layout: layout,
                                widths: widths,
                                shaded: index.isOdd,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        _TotalsBar(
          debit: _totalLabel(rows, layout.debitKey),
          credit: _totalLabel(rows, layout.creditKey),
        ),
      ],
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.layout, required this.widths});

  final _CityColumns layout;
  final List<double> widths;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.forest,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            for (var i = 0; i < layout.keys.length; i++)
              _ReportCell(
                width: widths[i],
                alignEnd: layout.moneyKeys.contains(layout.keys[i]),
                child: Text(
                  _columnHeading(layout.keys[i], layout),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: layout.moneyKeys.contains(layout.keys[i])
                      ? TextAlign.right
                      : TextAlign.left,
                  style: const TextStyle(
                    color: AppColors.onForest,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportDataRow extends StatelessWidget {
  const _ReportDataRow({
    required this.row,
    required this.layout,
    required this.widths,
    required this.shaded,
  });

  final Map<String, dynamic> row;
  final _CityColumns layout;
  final List<double> widths;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: shaded
          ? AppTheme.zebraColor(context)
          : AppTheme.cardColor(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.dividerColor(context)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              for (var i = 0; i < layout.keys.length; i++)
                _ReportCell(
                  width: widths[i],
                  alignEnd: layout.moneyKeys.contains(layout.keys[i]),
                  child: Builder(
                    builder: (context) {
                      final text = _cityCell(row, layout.keys[i], layout);
                      return Text(
                        text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: layout.moneyKeys.contains(layout.keys[i])
                            ? TextAlign.right
                            : TextAlign.left,
                        style: _valueStyle(
                          context,
                          layout.keys[i],
                          text,
                          layout,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCell extends StatelessWidget {
  const _ReportCell({
    required this.width,
    required this.alignEnd,
    required this.child,
  });

  final double width;
  final bool alignEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Align(
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
          child: child,
        ),
      ),
    );
  }
}

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({required this.debit, required this.credit});

  final String debit;
  final String credit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.forestDeep,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TotalFigure(label: 'Total Debit', value: debit),
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.onForest.withValues(alpha: 0.24),
          ),
          Expanded(
            child: _TotalFigure(label: 'Total Credit', value: credit),
          ),
        ],
      ),
    );
  }
}

class _TotalFigure extends StatelessWidget {
  const _TotalFigure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.limeSoft,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.onForest,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

String _reportLabel(String key) {
  final spaced = key
      .replaceAll('_', ' ')
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match[1]} ${match[2]}',
      )
      .trim();
  if (spaced.isEmpty) return key;
  return '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

String _reportCell(dynamic value) {
  if (value == null) return '-';
  if (value is num) return formatDashboardNumber(value);
  final text = value.toString().trim();
  return text.isEmpty ? '-' : text;
}

List<String> _reportColumns(List<Map<String, dynamic>> rows) {
  final keys = <String>[];
  for (final row in rows) {
    for (final entry in row.entries) {
      if (entry.value is Map || entry.value is List) continue;
      if (!keys.contains(entry.key)) keys.add(entry.key);
    }
  }
  return keys;
}

Future<Uint8List> _buildCityOutstandingPdf({
  required String city,
  required List<Map<String, dynamic>> rows,
}) {
  final layout = _cityColumns(rows);
  final session = AppSession.instance;
  final details = <String>[
    'City: $city',
    if ((session.company?.name ?? '').trim().isNotEmpty)
      'Company: ${session.company!.name}',
    if ((session.branch?.name ?? '').trim().isNotEmpty)
      'Branch: ${session.branch!.name}',
    if ((session.period?.name ?? '').trim().isNotEmpty)
      'Period: ${session.period!.name}',
  ];

  final document = pw.Document();
  document.addPage(
    pw.MultiPage(
      pageFormat: layout.keys.length > 5
          ? PdfPageFormat.a4.landscape
          : PdfPageFormat.a4,
      build: (context) => [
        pw.Text(
          'City-wise Outstanding Balance',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF0E6B38),
          ),
        ),
        pw.SizedBox(height: 8),
        for (final line in details)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(line, style: const pw.TextStyle(fontSize: 10)),
          ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: [for (final key in layout.keys) _columnHeading(key, layout)],
          data: [
            for (final row in rows)
              [for (final key in layout.keys) _cityCell(row, key, layout)],
          ],
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
            color: PdfColors.white,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFF0E6B38),
          ),
          oddRowDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF7FAF7),
          ),
          cellAlignments: {
            for (var i = 0; i < layout.keys.length; i++)
              i: layout.moneyKeys.contains(layout.keys[i])
                  ? pw.Alignment.centerRight
                  : pw.Alignment.centerLeft,
          },
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          color: PdfColor.fromInt(0xFF094D28),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Debit: ${_totalLabel(rows, layout.debitKey)}',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              pw.Text(
                'Total Credit: ${_totalLabel(rows, layout.creditKey)}',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  return document.save();
}

bool _numericColumn(String key, List<Map<String, dynamic>> rows) {
  var sawValue = false;
  for (final row in rows) {
    final value = row[key];
    if (value == null || value == '') continue;
    sawValue = true;
    if (value is! num) return false;
  }
  return sawValue;
}

class _CityColumns {
  const _CityColumns({
    required this.keys,
    required this.debitKey,
    required this.creditKey,
    required this.moneyKeys,
  });

  final List<String> keys;
  final String? debitKey;
  final String? creditKey;
  final Set<String> moneyKeys;
}

String _normKey(String key) =>
    key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

bool _isDebitKey(String key) {
  final name = _normKey(key);
  if (name.contains('day')) return false;
  return name == 'dr' ||
      name == 'dramt' ||
      name == 'dramnt' ||
      name == 'dramount' ||
      name.contains('debit');
}

bool _isCreditKey(String key) {
  final name = _normKey(key);
  if (name.contains('day')) return false;
  return name == 'cr' ||
      name == 'cramt' ||
      name == 'cramnt' ||
      name == 'cramount' ||
      name.contains('credit');
}

bool _isBalanceKey(String key) {
  final name = _normKey(key);
  return name == 'bal' || name.contains('balance');
}

_CityColumns _cityColumns(List<Map<String, dynamic>> rows) {
  final source = _reportColumns(rows);
  String? debit;
  String? credit;
  final text = <String>[];
  final money = <String>[];
  final balance = <String>[];
  for (final key in source) {
    if (_isDebitKey(key)) {
      if (debit == null) {
        debit = key;
      } else {
        money.add(key);
      }
      continue;
    }
    if (_isCreditKey(key)) {
      if (credit == null) {
        credit = key;
      } else {
        money.add(key);
      }
      continue;
    }
    if (_isBalanceKey(key)) {
      balance.add(key);
      continue;
    }
    if (_numericColumn(key, rows)) {
      money.add(key);
    } else {
      text.add(key);
    }
  }
  return _CityColumns(
    keys: [...text, ...money, ?debit, ?credit, ...balance],
    debitKey: debit,
    creditKey: credit,
    moneyKeys: {...money, ...balance, ?debit, ?credit},
  );
}

List<double> _columnWidths(double viewport, _CityColumns layout) {
  final mins = <double>[
    for (final key in layout.keys)
      layout.moneyKeys.contains(key) ? 118.0 : 156.0,
  ];
  if (mins.isEmpty) return mins;
  final sum = mins.fold<double>(0, (total, width) => total + width);
  if (sum >= viewport) return mins;
  final targets = <int>[
    for (var i = 0; i < layout.keys.length; i++)
      if (!layout.moneyKeys.contains(layout.keys[i])) i,
  ];
  final indexes = targets.isEmpty
      ? [for (var i = 0; i < mins.length; i++) i]
      : targets;
  final extra = (viewport - sum) / indexes.length;
  final widths = List<double>.of(mins);
  for (final index in indexes) {
    widths[index] += extra;
  }
  return widths;
}

String _columnHeading(String key, _CityColumns layout) {
  if (key == layout.debitKey) return 'Debit';
  if (key == layout.creditKey) return 'Credit';
  return _reportLabel(key);
}

num? _readAmount(dynamic value) {
  if (value is num) return value;
  if (value == null) return null;
  final text = value.toString().trim().replaceAll(',', '');
  if (text.isEmpty || text == '-') return null;
  return num.tryParse(text);
}

String _cityCell(Map<String, dynamic> row, String key, _CityColumns layout) {
  final value = row[key];
  if (layout.moneyKeys.contains(key)) {
    final amount = _readAmount(value);
    if (amount != null) return formatDashboardNumber(amount);
  }
  return _reportCell(value);
}

String _totalLabel(List<Map<String, dynamic>> rows, String? key) {
  if (key == null) return '-';
  num total = 0;
  for (final row in rows) {
    total += _readAmount(row[key]) ?? 0;
  }
  return formatDashboardNumber(total);
}

TextStyle _valueStyle(
  BuildContext context,
  String key,
  String text,
  _CityColumns layout,
) {
  final name = _normKey(key);
  final important =
      key == layout.debitKey ||
      key == layout.creditKey ||
      _isBalanceKey(key) ||
      name.contains('amount') ||
      name.endsWith('amt');
  final negative = text.trim().startsWith('-');
  final Color color;
  if (negative && important) {
    color = const Color(0xFFC62828);
  } else if (key == layout.debitKey) {
    color = AppTheme.isDark(context)
        ? const Color(0xFF9ECAFF)
        : const Color(0xFF1565C0);
  } else if (key == layout.creditKey || _isBalanceKey(key)) {
    color = AppTheme.isDark(context) ? AppColors.lime : AppColors.forestDeep;
  } else {
    color = AppTheme.primaryText(context);
  }
  return TextStyle(
    color: color,
    fontSize: 13,
    fontWeight: important ? FontWeight.w700 : FontWeight.w500,
    height: 1.25,
  );
}
