import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/soda_book.dart';
import '../services/soda_book_service.dart';
import '../session/app_session.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import 'login_screen.dart';

class SodaBookFeedingScreen extends StatefulWidget {
  const SodaBookFeedingScreen({super.key});

  @override
  State<SodaBookFeedingScreen> createState() => _SodaBookFeedingScreenState();
}

class _SodaBookFeedingScreenState extends State<SodaBookFeedingScreen> {
  final _service = SodaBookService();
  final _voucherNo = TextEditingController();
  final _ref = TextEditingController();
  final _remarks = TextEditingController();
  final _creditDays = TextEditingController();
  final _rate = TextEditingController();

  Map<String, dynamic> _master = {};
  final List<_DetailLine> _lines = [];

  List<SodaOption> _statuses = const [];
  List<SodaOption> _movements = const [];
  List<SodaOption> _parties = const [];
  List<SodaOption> _conditions = const [];
  List<SodaOption> _types = const [];
  List<SodaOption> _currencies = const [];
  List<SodaOption> _units = const [];
  List<SodaOption> _sodaTypes = const [];
  List<SodaOption> _items = const [];
  List<SodaOption> _rtTypes = const [];

  DateTime? _voucherDate;
  DateTime? _dueDate;
  DateTime? _shipDate;
  String? _type;
  String? _sodaType;
  String? _seller;
  String? _buyer;
  String? _broker;
  String? _condition;
  String? _currency;
  String? _unit;
  String? _status;
  String? _movement;
  int? _tranId;

  bool _lookupsLoading = false;
  bool _loadingVoucher = false;
  bool _saving = false;
  bool _leaving = false;
  int _page = 0;
  StateSetter? _lineSheetSetter;
  int _loadToken = 0;
  BuildContext? _themeContext;

  BuildContext get _theme => _themeContext ?? context;

  @override
  void initState() {
    super.initState();
    _voucherDate = DateTime.now();
    _lines.add(_DetailLine()..unitCode = _unit);
    if (AppSession.instance.isLoggedIn) {
      _lookupsLoading = true;
      unawaited(_loadLookups());
    }
  }

  @override
  void dispose() {
    _voucherNo.dispose();
    _ref.dispose();
    _remarks.dispose();
    _creditDays.dispose();
    _rate.dispose();
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _loadLookups() async {
    var unauthorized = false;
    String? error;
    Future<List<SodaOption>> load(Future<List<SodaOption>> future) async {
      try {
        return await future;
      } on ApiException catch (failure) {
        if (failure.isUnauthorized) {
          unauthorized = true;
        } else {
          error ??= failure.message;
        }
        return const [];
      }
    }

    final results = await Future.wait([
      load(_service.statuses()),
      load(_service.movements()),
      load(_service.parties()),
      load(_service.conditions()),
      load(_service.types()),
      load(_service.currencies()),
      load(_service.units()),
      load(_service.sodaTypes()),
      load(_service.items()),
      load(_service.rtTypes()),
    ]);
    if (!mounted) return;
    if (unauthorized) {
      _leave();
      return;
    }
    setState(() {
      _statuses = results[0];
      _movements = results[1];
      _parties = results[2];
      _conditions = results[3];
      _types = results[4];
      _currencies = results[5];
      _units = results[6];
      _sodaTypes = results[7];
      _items = results[8];
      _rtTypes = results[9];
      _lookupsLoading = false;
    });
    final lookupError = error;
    if (lookupError != null) _message(lookupError);
  }

  Future<void> _openVouchers() async {
    final id = await showModalBottomSheet<int>(
      context: _theme,
      isScrollControlled: true,
      builder: (context) => _VoucherSheet(
        service: _service,
        parties: _parties,
        onUnauthorized: _leave,
      ),
    );
    if (id != null) await _loadVoucher(id);
  }

  Future<void> _loadVoucher(int id) async {
    final token = ++_loadToken;
    setState(() => _loadingVoucher = true);
    try {
      final document = await _service.getById(id);
      if (!mounted || token != _loadToken) return;
      setState(() {
        _applyDocument(document, tranId: id);
        _loadingVoucher = false;
      });
    } on ApiException catch (error) {
      if (!mounted || token != _loadToken) return;
      setState(() => _loadingVoucher = false);
      if (error.isUnauthorized) {
        _leave();
        return;
      }
      _message(error.message);
    }
  }

  void _releaseLines() {
    final previous = List<_DetailLine>.of(_lines);
    _lines.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final line in previous) {
        line.dispose();
      }
    });
  }

  void _applyDocument(SodaDocument document, {int? tranId}) {
    _releaseLines();
    _master = Map<String, dynamic>.from(document.master);
    final parsed = int.tryParse(
      sodaCode(sodaFieldLoose(_master, 'traN_ID')) ?? '',
    );
    _tranId = parsed == null || parsed == 0 ? tranId : parsed;
    if (_tranId == 0) _tranId = null;
    if (_tranId != null) sodaSetField(_master, 'traN_ID', _tranId);
    _voucherNo.text =
        sodaFieldLoose(_master, 'voucheR_NO')?.toString().trim() ?? '';
    _ref.text = sodaFieldLoose(_master, 'ref')?.toString().trim() ?? '';
    _remarks.text = sodaFieldLoose(_master, 'remarks')?.toString().trim() ?? '';
    _creditDays.text = _numberText(sodaFieldLoose(_master, 'crediT_DAYS'));
    _rate.text = _numberText(sodaFieldLoose(_master, 'crate'));
    _voucherDate =
        _dateFrom(sodaFieldLoose(_master, 'v_DATE')) ?? DateTime.now();
    _dueDate = _dateFrom(sodaFieldLoose(_master, 'duE_DATE'));
    _shipDate = _dateFrom(sodaFieldLoose(_master, 'shiP_DATE'));
    _type = sodaCode(sodaFieldLoose(_master, 'sbF_TYPE'));
    _sodaType = sodaCode(sodaFieldLoose(_master, 'sodA_TYPE'));
    _seller = sodaCode(sodaFieldLoose(_master, 'selleR_CODE'));
    _buyer = sodaCode(sodaFieldLoose(_master, 'buyeR_CODE'));
    _broker = sodaCode(sodaFieldLoose(_master, 'brokeR_CODE'));
    _condition = sodaCode(sodaFieldLoose(_master, 'cond'));
    _currency = sodaCode(sodaFieldLoose(_master, 'curR_CODE'));
    _unit = sodaCode(sodaFieldLoose(_master, 'unit'));
    _status = sodaCode(sodaFieldLoose(_master, 'shiP_STATUS'));
    _movement = sodaCode(sodaFieldLoose(_master, 'p_S'));
    for (final row in document.detail) {
      _lines.add(_lineFrom(row));
    }
    if (_lines.isEmpty) _lines.add(_DetailLine()..unitCode = _unit);
  }

  _DetailLine _lineFrom(Map<String, dynamic> row) {
    final line = _DetailLine(raw: Map<String, dynamic>.from(row));
    line.itemCode = sodaCode(sodaFieldLoose(row, 'iteM_CODE'));
    line.unitCode = sodaCode(sodaFieldLoose(row, 'unit'));
    line.rtType = sodaCode(sodaFieldLoose(row, 'rT_TYPE'));
    line.desc.text = sodaFieldLoose(row, 'dT_DESC')?.toString().trim() ?? '';
    line.qty.text = _numberText(sodaFieldLoose(row, 'qty'));
    line.qty2.text = _numberText(sodaFieldLoose(row, 'qtY2'));
    line.rate.text = _numberText(sodaFieldLoose(row, 'rate'));
    line.amount.text = _numberText(sodaFieldLoose(row, 'amt'));
    line.dueDate = _dateFrom(sodaFieldLoose(row, 'duE_DATE'));
    line.balance = _numberText(sodaFieldLoose(row, 'baL_QTY'));
    final check = int.tryParse(sodaCode(sodaFieldLoose(row, 'chk')) ?? '');
    line.checked = check == 1;
    return line;
  }

  void _resetNew() {
    _releaseLines();
    _master = {};
    _tranId = null;
    _voucherNo.clear();
    _ref.clear();
    _remarks.clear();
    _creditDays.clear();
    _rate.clear();
    _voucherDate = DateTime.now();
    _dueDate = null;
    _shipDate = null;
    _type = null;
    _sodaType = null;
    _seller = null;
    _buyer = null;
    _broker = null;
    _condition = null;
    _currency = null;
    _unit = null;
    _status = null;
    _movement = null;
    _lines.add(_DetailLine());
    setState(() {});
  }

  void _applyCreditDueDate() {
    final days = int.tryParse(_creditDays.text.trim());
    if (days == null || _voucherDate == null) return;
    _dueDate = _voucherDate!.add(Duration(days: days));
  }

  void _syncDueDate() {
    setState(_applyCreditDueDate);
  }

  void _recalc(_DetailLine line) {
    final qty = _readNum(line.qty.text);
    final rate = _readNum(line.rate.text);
    if (qty == null || rate == null) return;
    final text = _numberText(qty * rate);
    if (line.amount.text != text) line.amount.text = text;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_voucherDate == null) {
      _message('Voucher date is required.');
      return;
    }
    setState(() => _saving = true);
    try {
      final update = _tranId != null;
      final data = await _service.save(
        master: _masterPayload(),
        detail: _detailPayload(),
        update: update,
      );
      if (!mounted) return;
      final savedId = _idFromSave(data) ?? _tranId;
      final savedNo = data is Map
          ? sodaField(data, 'voucherNo')?.toString()
          : null;
      if (savedNo != null && savedNo.trim().isNotEmpty) {
        _voucherNo.text = savedNo.trim();
      }
      if (savedId != null) {
        _tranId = savedId;
        final document = await _service.getById(savedId);
        if (!mounted) return;
        setState(() {
          _applyDocument(document, tranId: savedId);
          _saving = false;
        });
      } else if (mounted) {
        setState(() => _saving = false);
      }
      _message('Voucher saved.');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (error.isUnauthorized) {
        _leave();
        return;
      }
      _message(error.message);
    }
  }

  Map<String, dynamic> _masterPayload() {
    final session = AppSession.instance;
    final master = Map<String, dynamic>.from(_master);
    sodaSetField(master, 'traN_ID', _tranId);
    sodaSetField(master, 'v_DATE', _dateToApi(_voucherDate));
    sodaSetField(master, 'voucheR_NO', _blank(_voucherNo.text));
    sodaSetField(master, 'sbF_TYPE', _blank(_type));
    sodaSetField(master, 'sodA_TYPE', _blank(_sodaType));
    sodaSetField(master, 'selleR_CODE', _blank(_seller));
    sodaSetField(master, 'buyeR_CODE', _blank(_buyer));
    sodaSetField(master, 'brokeR_CODE', _blank(_broker));
    sodaSetField(master, 'cond', _blank(_condition));
    sodaSetField(master, 'curR_CODE', _apiInt(_currency));
    sodaSetField(master, 'crate', _readNum(_rate.text));
    sodaSetField(master, 'unit', _apiInt(_unit));
    sodaSetField(master, 'crediT_DAYS', _readNum(_creditDays.text));
    sodaSetField(master, 'duE_DATE', _dateToApi(_dueDate));
    sodaSetField(master, 'shiP_DATE', _dateToApi(_shipDate));
    sodaSetField(master, 'shiP_STATUS', _apiInt(_status));
    sodaSetField(master, 'p_S', _blank(_movement));
    sodaSetField(master, 'ref', _blank(_ref.text));
    sodaSetField(master, 'remarks', _blank(_remarks.text));
    sodaSetField(master, 'bcode', session.bcode);
    sodaSetField(master, 'perioD_ID', session.pid);
    return master;
  }

  List<Map<String, dynamic>> _detailPayload() {
    final session = AppSession.instance;
    final rows = <Map<String, dynamic>>[];
    for (final line in _lines) {
      if (_lineIsEmpty(line)) continue;
      final row = Map<String, dynamic>.from(line.raw);
      sodaSetField(row, 'traN_ID', _tranId);
      sodaSetField(row, 'iteM_CODE', _apiInt(line.itemCode));
      sodaSetField(row, 'dT_DESC', _blank(line.desc.text));
      sodaSetField(row, 'qty', _readNum(line.qty.text));
      sodaSetField(row, 'unit', _apiInt(line.unitCode ?? _unit));
      sodaSetField(row, 'qtY2', _readNum(line.qty2.text));
      sodaSetField(row, 'rate', _readNum(line.rate.text));
      sodaSetField(row, 'amt', _readNum(line.amount.text));
      sodaSetField(row, 'rT_TYPE', _readNum(line.rtType ?? ''));
      sodaSetField(row, 'duE_DATE', _dateToApi(line.dueDate));
      sodaSetField(row, 'chk', line.checked ? 1 : 0);
      sodaSetField(row, 'bcode', session.bcode);
      sodaSetField(row, 'perioD_ID', session.pid);
      rows.add(row);
    }
    return rows;
  }

  Future<void> _delete() async {
    final id = _tranId;
    if (id == null || _saving) return;
    final confirmed = await showDialog<bool>(
      context: _theme,
      builder: (context) => AlertDialog(
        title: const Text('Delete voucher'),
        content: const Text('Delete this Soda Book Feeding voucher?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _service.delete(id);
      if (!mounted) return;
      _resetNew();
      setState(() => _saving = false);
      _message('Voucher deleted.');
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (error.isUnauthorized) {
        _leave();
        return;
      }
      _message(error.message);
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

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _onSeller(String? code) {
    setState(() => _seller = code);
    final act = sodaActCode(_find(_parties, code)?.raw ?? const {});
    if (act != null) sodaSetField(_master, 'sacT_CODE', act);
  }

  void _onBuyer(String? code) {
    setState(() => _buyer = code);
    final act = sodaActCode(_find(_parties, code)?.raw ?? const {});
    if (act != null) sodaSetField(_master, 'bacT_CODE', act);
  }

  void _onItem(_DetailLine line, String? code) {
    setState(() => line.itemCode = code);
    if (line.desc.text.trim().isEmpty) {
      final name = _find(_items, code)?.name;
      if (name != null && name.isNotEmpty) line.desc.text = name;
    }
    _lineSheetSetter?.call(() {});
  }

  void _addLine() {
    final line = _DetailLine()..unitCode = _unit;
    setState(() => _lines.add(line));
    _editLine(_lines.length - 1);
  }

  void _removeLine(int index) {
    if (index < 0 || index >= _lines.length) return;
    final removed = _lines.removeAt(index);
    setState(() {
      if (_lines.isEmpty) _lines.add(_DetailLine()..unitCode = _unit);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.sizeOf(context).width >= 600 ? 28.0 : 16.0;
    final busy = _saving || _loadingVoucher;

    return AppThemeScope(
      child: Builder(
        builder: (context) {
          _themeContext = context;
          return Scaffold(
            backgroundColor: AppTheme.pageBackground(context),
            appBar: AppBar(
              backgroundColor: AppColors.forestDeep,
              foregroundColor: AppColors.onForest,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Soda Book Feeding',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              actions: [
                IconButton(
                  tooltip: 'Vouchers',
                  onPressed: () {
                    _openVouchers();
                  },
                  icon: const Icon(Icons.folder_open_outlined),
                ),
              ],
            ),
            body: Column(
              children: [
                if (_lookupsLoading || _loadingVoucher)
                  const LinearProgressIndicator(
                    minHeight: 3,
                    color: AppColors.lime,
                    backgroundColor: AppColors.forestMid,
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          12,
                          horizontal,
                          12,
                        ),
                        child: _sectionSwitch(context),
                      ),
                      Expanded(
                        child: _page == 0
                            ? _masterPage(context, horizontal)
                            : _detailPage(context, busy, horizontal),
                      ),
                    ],
                  ),
                ),
                _actions(context, busy, horizontal),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _masterPage(BuildContext context, double horizontal) {
    return ListView(
      padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        _panel(context, 'Master', [
          _pair(
            _dateField(
              'Transaction Date',
              _voucherDate,
              (value) => setState(() {
                _voucherDate = value;
                _applyCreditDueDate();
              }),
            ),
            _text('Transaction #', _voucherNo),
          ),
          _pair(
            _lookup('Type', _type, _types, (value) {
              setState(() => _type = value);
            }),
            _lookup('Soda Type', _sodaType, _sodaTypes, (value) {
              setState(() => _sodaType = value);
            }),
          ),
          _pair(
            _lookup('Seller', _seller, _parties, _onSeller),
            _lookup('Buyer', _buyer, _parties, _onBuyer),
          ),
          _pair(
            _lookup('Broker', _broker, _parties, (value) {
              setState(() => _broker = value);
            }),
            _lookup('Condition', _condition, _conditions, (value) {
              setState(() => _condition = value);
            }),
          ),
          _pair(
            _lookup('Currency', _currency, _currencies, (value) {
              setState(() => _currency = value);
            }),
            _text('Rate', _rate, number: true),
          ),
          _pair(
            _lookup('Unit', _unit, _units, (value) {
              setState(() => _unit = value);
            }),
            _text(
              'Credit Days',
              _creditDays,
              number: true,
              onChanged: (_) => _syncDueDate(),
            ),
          ),
          _pair(
            _dateField(
              'Due Date',
              _dueDate,
              (value) => setState(() => _dueDate = value),
            ),
            _dateField(
              'Ship Date',
              _shipDate,
              (value) => setState(() => _shipDate = value),
            ),
          ),
          _pair(
            _lookup('Status', _status, _statuses, (value) {
              setState(() => _status = value);
            }),
            _lookup('Movement', _movement, _movements, (value) {
              setState(() => _movement = value);
            }),
          ),
          _text('Reference #', _ref),
          _text('Remarks', _remarks, lines: 3),
        ]),
      ],
    );
  }

  Widget _sectionSwitch(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor(context)),
      ),
      child: Row(
        children: [
          _sectionTab(context, 'Master', 0),
          _sectionTab(context, 'Detail (${_lines.length})', 1),
        ],
      ),
    );
  }

  Widget _sectionTab(BuildContext context, String label, int page) {
    final selected = _page == page;
    final accent = AppTheme.isDark(context)
        ? AppColors.lime
        : AppColors.onForest;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: selected ? AppColors.forest : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() => _page = page),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? accent : AppTheme.primaryText(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailPage(BuildContext context, bool busy, double horizontal) {
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontal, 0, horizontal, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.dividerColor(context)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.isDark(context)
                          ? AppColors.lime
                          : AppColors.forestDeep,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: _section('Detail')),
                  TextButton.icon(
                    onPressed: busy ? null : _addLine,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add line'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.isDark(context)
                          ? AppColors.lime
                          : AppColors.forestDeep,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: AppTheme.dividerColor(context)),
            Expanded(
              child: ListView.builder(
                itemCount: _lines.length,
                itemBuilder: (context, index) => _detailRow(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, int index) {
    final line = _lines[index];
    final title = _lineTitle(line, index);
    final meta = _lineMeta(line);
    final amount = line.amount.text.trim();
    final accent = AppTheme.isDark(context)
        ? AppColors.lime
        : AppColors.forestDeep;
    return InkWell(
      onTap: () => _editLine(index),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.dividerColor(context)),
          ),
          color: index.isOdd ? AppTheme.zebraColor(context) : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: AppTheme.secondaryText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.primaryText(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppTheme.secondaryText(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amount.isEmpty ? '-' : amount,
                style: TextStyle(
                  color: amount.isEmpty
                      ? AppTheme.secondaryText(context)
                      : accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                tooltip: 'Remove line',
                visualDensity: VisualDensity.compact,
                onPressed: () => _removeLine(index),
                icon: Icon(
                  Icons.close,
                  size: 18,
                  color: AppTheme.secondaryText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _lineTitle(_DetailLine line, int index) {
    final item = _find(_items, line.itemCode)?.name;
    if (item != null && item.isNotEmpty) return item;
    final desc = line.desc.text.trim();
    if (desc.isNotEmpty) return desc;
    return 'Line ${index + 1}';
  }

  String _lineMeta(_DetailLine line) {
    final qty = line.qty.text.trim();
    final unit = _find(_units, line.unitCode)?.name ?? line.unitCode ?? '';
    final rate = line.rate.text.trim();
    final parts = <String>[
      if (qty.isNotEmpty) 'Qty $qty${unit.isEmpty ? '' : ' $unit'}',
      if (rate.isNotEmpty) 'Rate $rate',
      if (line.checked) 'Checked',
    ];
    if (parts.isEmpty) return 'Tap to enter this detail line';
    return parts.join('  ·  ');
  }

  Future<void> _editLine(int index) async {
    if (index < 0 || index >= _lines.length) return;
    await showModalBottomSheet<void>(
      context: _theme,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            _lineSheetSetter = setSheet;
            if (index >= _lines.length) return const SizedBox.shrink();
            return _lineEditor(context, index);
          },
        );
      },
    );
    _lineSheetSetter = null;
    if (mounted) setState(() {});
  }

  Widget _lineEditor(BuildContext context, int index) {
    final line = _lines[index];
    final media = MediaQuery.of(context);
    final height = (media.size.height * 0.92 - media.viewInsets.bottom).clamp(
      280.0,
      media.size.height * 0.92,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _section('Detail'),
                          const SizedBox(height: 2),
                          Text(
                            'Line ${index + 1}',
                            style: TextStyle(
                              color: AppTheme.primaryText(context),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppTheme.dividerColor(context)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    _lookup(
                      'Item',
                      line.itemCode,
                      _items,
                      (value) => _onItem(line, value),
                      tag: 'item$index',
                    ),
                    const SizedBox(height: 12),
                    _text('Description', line.desc),
                    const SizedBox(height: 12),
                    _pair(
                      _text(
                        'Qty',
                        line.qty,
                        number: true,
                        onChanged: (_) => _recalc(line),
                      ),
                      _lookup('Unit', line.unitCode, _units, (value) {
                        setState(() => line.unitCode = value);
                        _lineSheetSetter?.call(() {});
                      }, tag: 'unit$index'),
                    ),
                    const SizedBox(height: 12),
                    _pair(
                      _text('Qty 2', line.qty2, number: true),
                      _text(
                        'Rate',
                        line.rate,
                        number: true,
                        onChanged: (_) => _recalc(line),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _text(
                      'Amount',
                      line.amount,
                      number: true,
                      readOnly: true,
                      emphasize: true,
                    ),
                    const SizedBox(height: 12),
                    _pair(
                      _lookup('RT Type', line.rtType, _rtTypes, (value) {
                        setState(() => line.rtType = value);
                        _lineSheetSetter?.call(() {});
                      }, tag: 'rt$index'),
                      _dateField('Due Date', line.dueDate, (value) {
                        setState(() => line.dueDate = value);
                        _lineSheetSetter?.call(() {});
                      }),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      value: line.checked,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        'Check',
                        style: TextStyle(
                          color: AppTheme.primaryText(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => line.checked = value ?? false);
                        _lineSheetSetter?.call(() {});
                      },
                    ),
                    if (line.balance.isNotEmpty)
                      _balanceChip(context, line.balance),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, bool busy, double horizontal) {
    return Material(
      color: AppTheme.cardColor(context),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppTheme.dividerColor(context)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 12, horizontal, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'New',
                        outlined: true,
                        onPressed: busy ? null : _resetNew,
                      ),
                    ),
                    if (_tranId != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          label: 'Delete',
                          outlined: true,
                          onPressed: busy
                              ? null
                              : () {
                                  _delete();
                                },
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Save',
                  icon: Icons.save_outlined,
                  loading: _saving,
                  onPressed: busy
                      ? null
                      : () {
                          _save();
                        },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _balanceChip(BuildContext context, String balance) {
    final accent = AppTheme.isDark(context)
        ? AppColors.lime
        : AppColors.forestDeep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(
          alpha: AppTheme.isDark(context) ? 0.28 : 0.08,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Text(
            'Balance Qty',
            style: TextStyle(
              color: AppTheme.secondaryText(context),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            balance,
            style: TextStyle(
              color: accent,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel(
    BuildContext context,
    String title,
    List<Widget> fields, {
    Widget? trailing,
  }) {
    final accent = AppTheme.isDark(context)
        ? AppColors.lime
        : AppColors.forestDeep;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: AppTheme.isDark(context) ? 0.22 : 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(
              color: AppColors.forest.withValues(
                alpha: AppTheme.isDark(context) ? 0.28 : 0.08,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _section(title, accent)),
                ?trailing,
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: _fields(fields)),
        ],
      ),
    );
  }

  Widget _section(String text, [Color? color]) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color ?? AppTheme.secondaryText(_theme),
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _pair(Widget left, Widget right) {
    final wide = MediaQuery.sizeOf(_theme).width >= 600;
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [left, const SizedBox(height: 14), right],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }

  Widget _fields(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          children[i],
        ],
      ],
    );
  }

  Widget _caption(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.secondaryText(_theme),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.2,
      ),
    );
  }

  Widget _text(
    String label,
    TextEditingController controller, {
    bool number = false,
    int lines = 1,
    bool readOnly = false,
    bool emphasize = false,
    ValueChanged<String>? onChanged,
  }) {
    final accent = AppTheme.isDark(_theme)
        ? AppColors.lime
        : AppColors.forestDeep;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _caption(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          maxLines: lines,
          style: TextStyle(
            color: emphasize ? accent : AppTheme.primaryText(_theme),
            fontSize: 14,
            fontWeight: emphasize ? FontWeight.w800 : FontWeight.w500,
            height: 1.2,
          ),
          keyboardType: number
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          onChanged: onChanged,
          decoration: _formDecoration(_theme, emphasize: emphasize),
        ),
      ],
    );
  }

  Widget _lookup(
    String label,
    String? value,
    List<SodaOption> items,
    ValueChanged<String?> onChanged, {
    Object? tag,
  }) {
    final options = _withSelected(items, value);
    final selected = value != null && options.any((item) => item.code == value)
        ? value
        : null;
    return _FieldDropdown(
      key: ValueKey(tag ?? label),
      label: label,
      value: selected,
      options: options,
      onChanged: onChanged,
    );
  }

  Widget _dateField(
    String label,
    DateTime? value,
    ValueChanged<DateTime> onPick,
  ) {
    final hasValue = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _caption(label),
        const SizedBox(height: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () async {
              final picked = await showDatePicker(
                context: _theme,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;
              onPick(DateTime(picked.year, picked.month, picked.day));
            },
            child: InputDecorator(
              decoration: _formDecoration(
                _theme,
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppTheme.secondaryText(_theme),
                ),
              ),
              child: Text(
                hasValue ? _dateLabel(value) : 'Select',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: hasValue
                      ? AppTheme.primaryText(_theme)
                      : AppTheme.secondaryText(_theme),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailLine {
  _DetailLine({Map<String, dynamic>? raw}) : raw = raw ?? {};

  final Map<String, dynamic> raw;
  final desc = TextEditingController();
  final qty = TextEditingController();
  final qty2 = TextEditingController();
  final rate = TextEditingController();
  final amount = TextEditingController();
  String? itemCode;
  String? unitCode;
  String? rtType;
  DateTime? dueDate;
  bool checked = false;
  String balance = '';

  void dispose() {
    desc.dispose();
    qty.dispose();
    qty2.dispose();
    rate.dispose();
    amount.dispose();
  }
}

InputDecoration _formDecoration(
  BuildContext context, {
  bool emphasize = false,
  Widget? suffixIcon,
  String? hintText,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    filled: true,
    fillColor: _formFill(context, emphasize: emphasize),
    isDense: true,
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 48),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: _formBorder(context),
    enabledBorder: _formBorder(context),
    focusedBorder: _formBorder(context, focused: true),
    disabledBorder: _formBorder(context),
  );
}

InputDecorationTheme _formTheme(BuildContext context) {
  return InputDecorationTheme(
    filled: true,
    fillColor: _formFill(context),
    isDense: true,
    hintStyle: TextStyle(
      color: AppTheme.secondaryText(context),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: _formBorder(context),
    enabledBorder: _formBorder(context),
    focusedBorder: _formBorder(context, focused: true),
    disabledBorder: _formBorder(context),
  );
}

Color _formFill(BuildContext context, {bool emphasize = false}) {
  final dark = AppTheme.isDark(context);
  if (emphasize) {
    return AppColors.forest.withValues(alpha: dark ? 0.28 : 0.08);
  }
  return dark ? const Color(0xFF1B2420) : AppColors.inputFill;
}

Color _formBorderColor(BuildContext context, {bool focused = false}) {
  final dark = AppTheme.isDark(context);
  if (focused) return dark ? AppColors.limeSoft : AppColors.forest;
  return dark ? const Color(0xFF5C6E66) : const Color(0xFFB0B8B3);
}

OutlineInputBorder _formBorder(BuildContext context, {bool focused = false}) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(
      color: _formBorderColor(context, focused: focused),
      width: focused ? 1.6 : 1.2,
    ),
  );
}

class _FieldDropdown extends StatefulWidget {
  const _FieldDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<SodaOption> options;
  final ValueChanged<String?> onChanged;

  @override
  State<_FieldDropdown> createState() => _FieldDropdownState();
}

class _FieldDropdownState extends State<_FieldDropdown> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _showSelected();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant _FieldDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_focus.hasFocus) return;
    if (oldWidget.value != widget.value ||
        oldWidget.options != widget.options) {
      _showSelected();
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocus() {
    if (_focus.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
      return;
    }
    _showSelected();
  }

  void _showSelected() {
    final label = _find(widget.options, widget.value)?.name ?? '';
    if (_controller.text == label) return;
    _controller.value = TextEditingValue(
      text: label,
      selection: TextSelection.collapsed(offset: label.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.isDark(context) ? AppColors.lime : AppColors.forest;
    final availableHeight = MediaQuery.sizeOf(context).height * 0.45;
    final menuHeight = availableHeight < 320 ? availableHeight : 320.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: AppTheme.secondaryText(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return DropdownMenu<String>(
              controller: _controller,
              focusNode: _focus,
              requestFocusOnTap: true,
              enableFilter: true,
              enableSearch: true,
              expandedInsets: EdgeInsets.zero,
              width: width.isFinite ? width : null,
              initialSelection: widget.value,
              hintText: 'Select',
              menuHeight: menuHeight,
              alignmentOffset: const Offset(0, 6),
              textStyle: TextStyle(
                color: AppTheme.primaryText(context),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              inputDecorationTheme: _formTheme(context),
              menuStyle: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(
                  AppTheme.cardColor(context),
                ),
                surfaceTintColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
                elevation: const WidgetStatePropertyAll(8),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: _formBorderColor(context)),
                  ),
                ),
              ),
              trailingIcon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.secondaryText(context),
              ),
              selectedTrailingIcon: Icon(
                Icons.keyboard_arrow_up_rounded,
                color: accent,
              ),
              filterCallback: (entries, filter) {
                final query = filter.trim().toLowerCase();
                if (query.isEmpty) return entries;
                return [
                  for (final entry in entries)
                    if (entry.label.toLowerCase().contains(query) ||
                        entry.value.toLowerCase().contains(query))
                      entry,
                ];
              },
              dropdownMenuEntries: [
                for (final item in widget.options)
                  DropdownMenuEntry<String>(
                    value: item.code,
                    label: item.name,
                    labelWidget: Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: item.code == widget.value
                            ? accent
                            : AppTheme.primaryText(context),
                        fontSize: 14,
                        fontWeight: item.code == widget.value
                            ? FontWeight.w700
                            : FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                    trailingIcon: item.code == widget.value
                        ? Icon(Icons.check, color: accent, size: 18)
                        : null,
                  ),
              ],
              onSelected: (value) {
                if (value == null) {
                  _showSelected();
                  return;
                }
                widget.onChanged(value);
                final label = _find(widget.options, value)?.name ?? value;
                _controller.value = TextEditingValue(
                  text: label,
                  selection: TextSelection.collapsed(offset: label.length),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _VoucherSheet extends StatefulWidget {
  const _VoucherSheet({
    required this.service,
    required this.parties,
    required this.onUnauthorized,
  });

  final SodaBookService service;
  final List<SodaOption> parties;
  final VoidCallback onUnauthorized;

  @override
  State<_VoucherSheet> createState() => _VoucherSheetState();
}

class _VoucherSheetState extends State<_VoucherSheet> {
  final _query = TextEditingController();
  Timer? _debounce;
  int _token = 0;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_load(''));
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_load(value));
    });
  }

  Future<void> _load(String search) async {
    final token = ++_token;
    setState(() {
      _loading = true;
      _error = null;
      _rows = const [];
    });
    try {
      final rows = await widget.service.quickSearch(search: search);
      if (!mounted || token != _token) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted || token != _token) return;
      if (error.isUnauthorized) {
        Navigator.pop(context);
        widget.onUnauthorized();
        return;
      }
      setState(() {
        _loading = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = (media.size.height * 0.7 - media.viewInsets.bottom).clamp(
      240.0,
      media.size.height * 0.7,
    );
    final entries = [
      for (final row in _rows)
        if (_tranId(row) != null) row,
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  'Vouchers',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  onChanged: _onQueryChanged,
                  onSubmitted: (value) {
                    _debounce?.cancel();
                    unawaited(_load(value));
                  },
                  decoration: _formDecoration(
                    context,
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(child: _body(entries)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(List<Map<String, dynamic>> entries) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            color: AppColors.forest,
          ),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (entries.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No vouchers.'),
        ),
      );
    }
    return ListView(
      children: [
        for (final row in entries)
          ListTile(
            title: Text(_title(row)),
            subtitle: Text(_subtitle(row, widget.parties)),
            onTap: () => Navigator.pop(context, _tranId(row)),
          ),
      ],
    );
  }
}

List<SodaOption> _withSelected(List<SodaOption> items, String? value) {
  if (value == null ||
      value.isEmpty ||
      items.any((item) => item.code == value)) {
    return items;
  }
  return [SodaOption(code: value, name: value), ...items];
}

SodaOption? _find(List<SodaOption> items, String? code) {
  if (code == null || code.isEmpty) return null;
  for (final item in items) {
    if (item.code == code) return item;
  }
  return null;
}

bool _lineIsEmpty(_DetailLine line) {
  return (line.itemCode == null || line.itemCode!.isEmpty) &&
      line.desc.text.trim().isEmpty &&
      line.qty.text.trim().isEmpty &&
      line.qty2.text.trim().isEmpty &&
      line.rate.text.trim().isEmpty &&
      (line.rtType == null || line.rtType!.isEmpty) &&
      line.dueDate == null &&
      !line.checked;
}

int? _idFromSave(dynamic data) {
  if (data is num && data != 0) return data.toInt();
  if (data is Map) {
    final code =
        sodaFieldLoose(data, 'code') ??
        sodaFieldLoose(data, 'traN_ID') ??
        sodaFieldLoose(data, 'id');
    final parsed = int.tryParse(sodaCode(code) ?? '');
    if (parsed != null && parsed != 0) return parsed;
  }
  return null;
}

int? _apiInt(String? code) {
  if (code == null || code.trim().isEmpty) return null;
  return int.tryParse(code.trim());
}

num? _readNum(String text) {
  final trimmed = text.trim().replaceAll(',', '');
  if (trimmed.isEmpty) return null;
  return num.tryParse(trimmed);
}

String? _blank(String? text) {
  final value = text?.trim() ?? '';
  return value.isEmpty ? null : value;
}

String _numberText(dynamic value) {
  if (value == null) return '';
  final parsed = value is num ? value : num.tryParse(value.toString());
  if (parsed == null) return value.toString();
  if (parsed == parsed.roundToDouble()) return parsed.toInt().toString();
  var text = parsed.toStringAsFixed(4);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return text;
}

DateTime? _dateFrom(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

String? _dateToApi(DateTime? date) {
  if (date == null) return null;
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-${day}T00:00:00';
}

String _dateLabel(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

int? _tranId(Map<String, dynamic> row) {
  for (final key in const ['traN_ID', 'id']) {
    final parsed = int.tryParse(sodaCode(sodaFieldLoose(row, key)) ?? '');
    if (parsed != null && parsed != 0) return parsed;
  }
  return null;
}

String _title(Map<String, dynamic> row) {
  final number = sodaFieldLoose(row, 'voucheR_NO')?.toString().trim() ?? '';
  if (number.isNotEmpty) return number;
  return 'Voucher ${_tranId(row)}';
}

String _subtitle(Map<String, dynamic> row, List<SodaOption> parties) {
  final date = _dateFrom(sodaFieldLoose(row, 'v_DATE'));
  final sellerCode = sodaCode(sodaFieldLoose(row, 'selleR_CODE'));
  final seller = _find(parties, sellerCode)?.name ?? sellerCode ?? '';
  return [
    if (date != null) _dateLabel(date),
    if (seller.isNotEmpty) seller,
  ].join(' · ');
}
