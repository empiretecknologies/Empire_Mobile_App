import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
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
  String? _type = 'LOC';
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
  int _loadToken = 0;
  BuildContext? _themeContext;
  final _formScroll = ScrollController();
  final _itemsScroll = ScrollController();
  final _remarksFocus = FocusNode();
  final _commentKey = GlobalKey();

  BuildContext get _theme => _themeContext ?? context;

  @override
  void initState() {
    super.initState();
    _voucherDate = DateTime.now();
    _seedBlankLines();
    _remarksFocus.addListener(_onRemarksFocus);
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
    _formScroll.dispose();
    _itemsScroll.dispose();
    _remarksFocus.removeListener(_onRemarksFocus);
    _remarksFocus.dispose();
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
      _movements = _movementOptions(results[1]);
      _parties = results[2];
      _conditions = results[3];
      _types = _sbfTypeOptions(results[4]);
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
    _type = _sbfTypeCode(sodaCode(sodaFieldLoose(_master, 'sbF_TYPE')));
    _sodaType = sodaCode(sodaFieldLoose(_master, 'sodA_TYPE'));
    _seller = _find(_parties, sodaCode(sodaFieldLoose(_master, 'selleR_CODE')))
            ?.code ??
        sodaCode(sodaFieldLoose(_master, 'selleR_CODE'));
    _buyer = _find(_parties, sodaCode(sodaFieldLoose(_master, 'buyeR_CODE')))
            ?.code ??
        sodaCode(sodaFieldLoose(_master, 'buyeR_CODE'));
    _broker = _find(_parties, sodaCode(sodaFieldLoose(_master, 'brokeR_CODE')))
            ?.code ??
        sodaCode(sodaFieldLoose(_master, 'brokeR_CODE'));
    _condition = sodaCode(sodaFieldLoose(_master, 'cond'));
    _currency = sodaCode(sodaFieldLoose(_master, 'curR_CODE'));
    _unit = sodaCode(sodaFieldLoose(_master, 'unit'));
    _status = sodaCode(sodaFieldLoose(_master, 'shiP_STATUS'));
    _movement = _movementCode(
      sodaCode(sodaFieldLoose(_master, 'p_S')),
    );
    for (final row in document.detail) {
      _lines.add(_lineFrom(row));
    }
    _seedBlankLines();
  }

  void _seedBlankLines({int count = 1}) {
    while (_lines.length < count) {
      _lines.insert(0, _DetailLine()..unitCode = _unit);
    }
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
    _type = 'LOC';
    _sodaType = null;
    _seller = null;
    _buyer = null;
    _broker = null;
    _condition = null;
    _currency = null;
    _unit = null;
    _status = null;
    _movement = null;
    _seedBlankLines();
    setState(() {});
  }

  void _applyCreditDueDate() {
    final days = int.tryParse(_creditDays.text.trim());
    if (days == null || _voucherDate == null) return;
    _dueDate = _voucherDate!.add(Duration(days: days));
  }

  void _recalc(_DetailLine line) {
    final qty = _readNum(line.qty.text);
    final rate = _readNum(line.rate.text);
    if (qty == null || rate == null) {
      if (line.amount.text.isNotEmpty) {
        line.amount.text = '';
        setState(() {});
      }
      return;
    }
    final text = _numberText(qty * rate);
    if (line.amount.text != text) {
      line.amount.text = text;
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_voucherDate == null) {
      _message('Voucher date is required.');
      return;
    }
    final master = _masterPayload();
    final detail = _detailPayload();
    if (detail.isEmpty) {
      _message('Add at least one item before saving.');
      return;
    }
    debugPrint(
      'SodaBookFeeding ${ _tranId != null ? 'PUT' : 'POST' } '
      '${ApiConfig.sodaBookFeeding} body=${jsonEncode({'master': master, 'detail': detail})}',
    );
    setState(() => _saving = true);
    try {
      final update = _tranId != null;
      final data = await _service.save(
        master: master,
        detail: detail,
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
    sodaSetField(master, 'sbF_TYPE', _sbfTypeCode(_type));
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
    sodaSetField(master, 'p_S', _movementCode(_movement));
    sodaSetField(master, 'ref', _blank(_ref.text));
    sodaSetField(master, 'remarks', _blank(_remarks.text));
    sodaSetField(master, 'bcode', session.bcode);
    sodaSetField(master, 'perioD_ID', session.pid);
    return _allowedMap(master, _masterFields);
  }

  List<Map<String, dynamic>> _detailPayload() {
    final session = AppSession.instance;
    final rows = <Map<String, dynamic>>[];
    for (final line in _lines) {
      if (line.itemCode == null || line.itemCode!.isEmpty) continue;
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
      rows.add(_allowedMap(row, _detailFields));
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
  }

  void _addLine() {
    setState(() {
      _lines.insert(0, _DetailLine()..unitCode = _unit);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemsScroll.hasClients) {
        _itemsScroll.jumpTo(0);
      }
    });
  }

  void _removeLine(int index) {
    if (index < 0 || index >= _lines.length) return;
    final removed = _lines.removeAt(index);
    setState(_seedBlankLines);
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
          final keyboard = MediaQuery.viewInsetsOf(context).bottom;
          return Scaffold(
            backgroundColor: AppTheme.pageBackground(context),
            resizeToAvoidBottomInset: false,
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
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        controller: _formScroll,
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          12,
                          horizontal,
                          12,
                        ),
                        child: Column(
                          children: [
                            _masterCard(context, busy),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: _itemsViewportHeight(
                                constraints.maxHeight,
                              ),
                              child: _itemsCard(context, busy),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (keyboard == 0) _actions(context, busy, horizontal),
                SizedBox(height: keyboard),
              ],
            ),
          );
        },
      ),
    );
  }

  double _itemsViewportHeight(double available) {
    const twoRows = 540.0;
    const minRows = 220.0;
    if (available <= 0) return twoRows;
    final upper = available < minRows ? minRows : available;
    return twoRows.clamp(minRows, upper);
  }

  void _onRemarksFocus() {
    if (_remarksFocus.hasFocus) {
      _revealField(_commentKey.currentContext ?? context, alignment: 0.12);
    }
  }

  void _revealField(BuildContext fieldContext, {double alignment = 0.12}) {
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (!fieldContext.mounted) return;
      Scrollable.ensureVisible(
        fieldContext,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        alignment: alignment,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );
    });
  }

  Widget _masterCard(BuildContext context, bool busy) {
    final voucher = _voucherNo.text.trim();
    return _shellCard(
      context,
      child: Column(
        children: [
          _cardHeader(
            context,
            icon: Icons.description_outlined,
            title: 'Invoice No.',
            value: voucher.isEmpty ? 'New voucher' : voucher,
            trailing: _statusChip(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              children: [
                _pair(
                  _dateTile(
                    context,
                    label: 'Transaction Date',
                    value: _voucherDate,
                    enabled: !busy,
                    compact: true,
                    onPick: (value) => setState(() {
                      _voucherDate = value;
                      _applyCreditDueDate();
                    }),
                  ),
                  _lookupTile(
                    context,
                    label: 'Movement',
                    value: _movement,
                    options: _movements,
                    icon: Icons.swap_horiz_rounded,
                    enabled: !busy,
                    compact: true,
                    onChanged: (value) => setState(
                      () => _movement = _movementCode(value),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _lookupTile(
                  context,
                  label: 'Seller Code',
                  value: _seller,
                  options: _parties,
                  icon: Icons.person_outline_rounded,
                  hint: 'Select Seller',
                  enabled: !busy,
                  onChanged: _onSeller,
                ),
                const SizedBox(height: 8),
                _lookupTile(
                  context,
                  label: 'Buyer Code',
                  value: _buyer,
                  options: _parties,
                  icon: Icons.storefront_outlined,
                  hint: 'Select Buyer',
                  enabled: !busy,
                  onChanged: _onBuyer,
                ),
                const SizedBox(height: 8),
                _lookupTile(
                  context,
                  label: 'Type',
                  value: _type,
                  options: _types,
                  icon: Icons.category_outlined,
                  enabled: !busy,
                  onChanged: (value) => setState(
                    () => _type = _sbfTypeCode(value),
                  ),
                ),
                const SizedBox(height: 8),
                _commentField(context, busy),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemsCard(BuildContext context, bool busy) {
    return _shellCard(
      context,
      child: Column(
        children: [
          _cardHeader(
            context,
            icon: Icons.shopping_cart_outlined,
            title: 'Invoice Items',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _countChip(context, '${_lines.length} Items'),
                IconButton(
                  tooltip: 'Add item',
                  onPressed: busy ? null : _addLine,
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: AppTheme.isDark(context)
                        ? AppColors.lime
                        : AppColors.forestDeep,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: ListView.separated(
                controller: _itemsScroll,
                itemCount: _lines.length,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const ClampingScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _itemCard(context, index, busy),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(BuildContext context, int index, bool busy) {
    final line = _lines[index];
    final amount = line.amount.text.trim();
    final accent = AppTheme.isDark(context)
        ? AppColors.lime
        : AppColors.forestDeep;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.isDark(context)
            ? const Color(0xFF161E1B)
            : const Color(0xFFF4F8F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor(context)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Item #${(index + 1).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: AppTheme.primaryText(context),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(
                        color: AppTheme.secondaryText(context),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      amount.isEmpty ? '0' : amount,
                      style: TextStyle(
                        color: accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Remove item',
                  visualDensity: VisualDensity.compact,
                  onPressed: busy ? null : () => _removeLine(index),
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _lookupTile(
              context,
              label: 'Item',
              value: line.itemCode,
              options: _items,
              icon: Icons.inventory_2_outlined,
              hint: 'Select Product',
              enabled: !busy,
              onChanged: (value) => _onItem(line, value),
            ),
            const SizedBox(height: 8),
            _pair(
              _numberTile(
                context,
                label: 'Quantity',
                controller: line.qty,
                icon: Icons.inventory_outlined,
                enabled: !busy,
                compact: true,
                onChanged: (_) => _recalc(line),
              ),
              _numberTile(
                context,
                label: 'Rate',
                controller: line.rate,
                icon: Icons.payments_outlined,
                enabled: !busy,
                compact: true,
                onChanged: (_) => _recalc(line),
              ),
            ),
            const SizedBox(height: 8),
            _pair(
              _lookupTile(
                context,
                label: 'Unit',
                value: line.unitCode,
                options: _units,
                icon: Icons.straighten_outlined,
                hint: 'Select Unit',
                enabled: !busy,
                compact: true,
                onChanged: (value) => setState(() => line.unitCode = value),
              ),
              _lookupTile(
                context,
                label: 'RT Type',
                value: line.rtType,
                options: _rtTypes,
                icon: Icons.tune_outlined,
                hint: 'Select RT Type',
                enabled: !busy,
                compact: true,
                onChanged: (value) => setState(() => line.rtType = value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shellCard(BuildContext context, {required Widget child}) {
    final dark = AppTheme.isDark(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.dividerColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.22 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: child,
      ),
    );
  }

  Widget _cardHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? value,
    Widget? trailing,
  }) {
    final accent = AppTheme.isDark(context)
        ? AppColors.lime
        : AppColors.forestDeep;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(
          alpha: AppTheme.isDark(context) ? 0.28 : 0.08,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
      ),
      child: Row(
        children: [
          _iconBox(context, icon),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.secondaryText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (value != null)
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _statusChip(BuildContext context) {
    final isNew = _tranId == null;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(alpha: isNew ? 0.12 : 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isNew ? AppColors.forestMid : AppColors.forestDeep,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isNew ? 'New' : 'Saved',
            style: TextStyle(
              color: AppTheme.isDark(context)
                  ? AppColors.lime
                  : AppColors.forestDeep,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _countChip(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(
          alpha: AppTheme.isDark(context) ? 0.28 : 0.12,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.isDark(context)
              ? AppColors.lime
              : AppColors.forestDeep,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _iconBox(BuildContext context, IconData icon, {bool compact = false}) {
    final size = compact ? 28.0 : 34.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.forest.withValues(
          alpha: AppTheme.isDark(context) ? 0.35 : 0.12,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: compact ? 16 : 18,
        color: AppTheme.isDark(context) ? AppColors.lime : AppColors.forestDeep,
      ),
    );
  }

  Widget _commentField(BuildContext context, bool busy) {
    return _inputFrame(
      context,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: _iconBox(context, Icons.chat_bubble_outline),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comment',
                  style: TextStyle(
                    color: AppTheme.secondaryText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextField(
                  key: _commentKey,
                  controller: _remarks,
                  focusNode: _remarksFocus,
                  enabled: !busy,
                  maxLines: 1,
                  scrollPadding: const EdgeInsets.fromLTRB(20, 80, 20, 180),
                  onTap: () => _revealField(
                    _commentKey.currentContext ?? context,
                    alignment: 0.12,
                  ),
                  style: TextStyle(
                    color: AppTheme.primaryText(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Enter remarks...',
                    hintStyle: TextStyle(
                      color: AppTheme.secondaryText(context),
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 2, bottom: 2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTile(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPick,
    bool enabled = true,
    bool compact = false,
  }) {
    return _inputFrame(
      context,
      compact: compact,
      onTap: enabled
          ? () async {
              final picked = await showDatePicker(
                context: _theme,
                initialDate: value ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked == null) return;
              onPick(DateTime(picked.year, picked.month, picked.day));
            }
          : null,
      child: Row(
        children: [
          _iconBox(context, Icons.calendar_today_outlined, compact: compact),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.secondaryText(context),
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value == null ? 'Select' : _dateLabel(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: value == null
                        ? AppTheme.secondaryText(context)
                        : AppTheme.primaryText(context),
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lookupTile(
    BuildContext context, {
    required String label,
    required String? value,
    required List<SodaOption> options,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    String hint = 'Select',
    bool enabled = true,
    bool compact = false,
  }) {
    return _AnchoredDropdown(
      label: label,
      value: value,
      options: options,
      icon: icon,
      hint: hint,
      enabled: enabled,
      compact: compact,
      onChanged: onChanged,
      iconBox: _iconBox(context, icon, compact: compact),
    );
  }

  Widget _numberTile(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required IconData icon,
    ValueChanged<String>? onChanged,
    bool enabled = true,
    bool compact = false,
  }) {
    return _inputFrame(
      context,
      compact: compact,
      child: Row(
        children: [
          _iconBox(context, icon, compact: compact),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.secondaryText(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Builder(
                  builder: (fieldContext) => TextField(
                  controller: controller,
                  enabled: enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  scrollPadding: const EdgeInsets.fromLTRB(20, 80, 20, 180),
                  onTap: () => _revealField(fieldContext, alignment: 0.12),
                  onChanged: onChanged,
                  style: TextStyle(
                    color: AppTheme.primaryText(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 2, bottom: 2),
                  ),
                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputFrame(
    BuildContext context, {
    required Widget child,
    VoidCallback? onTap,
    bool compact = false,
  }) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.isDark(context)
            ? const Color(0xFF1B2420)
            : AppColors.inputFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.dividerColor(context)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 8 : 10,
        ),
        child: child,
      ),
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: box,
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
            padding: EdgeInsets.fromLTRB(horizontal, 10, horizontal, 10),
            child: Row(
              children: [
                if (_tranId != null) ...[
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: busy
                        ? null
                        : () {
                            _delete();
                          },
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: AppButton(
                    label: 'New',
                    outlined: true,
                    onPressed: busy ? null : _resetNew,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    label: 'Save',
                    icon: Icons.save_outlined,
                    loading: _saving,
                    onPressed: busy
                        ? null
                        : () {
                            _save();
                          },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pair(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 8),
        Expanded(child: right),
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

class _AnchoredDropdown extends StatelessWidget {
  const _AnchoredDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.icon,
    required this.onChanged,
    required this.iconBox,
    this.hint = 'Select',
    this.enabled = true,
    this.compact = false,
  });

  final String label;
  final String? value;
  final List<SodaOption> options;
  final IconData icon;
  final ValueChanged<String?> onChanged;
  final Widget iconBox;
  final String hint;
  final bool enabled;
  final bool compact;

  Future<void> _open(BuildContext context) async {
    if (!enabled) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _LookupSheet(
        title: label,
        options: options,
        value: value,
      ),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _find(options, value);
    final text =
        selected?.name ??
        (value == null || value!.isEmpty ? hint : value!);
    final hasValue =
        selected != null || (value != null && value!.isNotEmpty);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _open(context) : null,
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppTheme.isDark(context)
                ? const Color(0xFF1B2420)
                : AppColors.inputFill,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.dividerColor(context)),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 10,
              vertical: compact ? 8 : 10,
            ),
            child: Row(
              children: [
                iconBox,
                SizedBox(width: compact ? 8 : 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppTheme.secondaryText(context),
                          fontSize: compact ? 11 : 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: hasValue
                              ? AppTheme.primaryText(context)
                              : AppTheme.secondaryText(context),
                          fontSize: compact ? 13 : 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.secondaryText(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LookupSheet extends StatefulWidget {
  const _LookupSheet({
    required this.title,
    required this.options,
    required this.value,
  });

  final String title;
  final List<SodaOption> options;
  final String? value;

  @override
  State<_LookupSheet> createState() => _LookupSheetState();
}

class _LookupSheetState extends State<_LookupSheet> {
  final _search = TextEditingController();
  String _filter = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<SodaOption> _visible() {
    final query = _filter.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return [
      for (final item in widget.options)
        if (item.name.toLowerCase().contains(query) ||
            item.code.toLowerCase().contains(query) ||
            (sodaCode(sodaFieldLoose(item.raw, 'customizedKey')) ?? '')
                .toLowerCase()
                .contains(query))
          item,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = (media.size.height * 0.62).clamp(280.0, 520.0);
    final items = _visible();
    final dark = AppTheme.isDark(context);
    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _filter = value),
                decoration: _formDecoration(
                  context,
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        widget.options.isEmpty
                            ? 'No records.'
                            : 'No matching records.',
                        style: TextStyle(
                          color: AppTheme.secondaryText(context),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemExtent: 48,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = item.code == widget.value;
                        return ListTile(
                          dense: true,
                          title: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? (dark
                                        ? AppColors.lime
                                        : AppColors.forestDeep)
                                  : AppTheme.primaryText(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: () => Navigator.pop(context, item.code),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
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

/// Maps Type labels/codes to the 3-char `SBF_TYPE` values expected by the DB.
String? _sbfTypeCode(String? value, {String? name}) {
  for (final candidate in [value, name]) {
    if (candidate == null) continue;
    final text = candidate.trim().toUpperCase();
    if (text.isEmpty) continue;
    if (text == 'LOC' || text == 'LOCAL') return 'LOC';
    if (text == 'IMP' || text == 'IMPORT') return 'IMP';
    if (text == 'EXP' || text == 'EXPORT') return 'EXP';
  }
  return null;
}

String _sbfTypeName(String code, String fallback) {
  final text = fallback.trim();
  final upper = text.toUpperCase();
  switch (code) {
    case 'LOC':
      return upper == 'LOC' || text.isEmpty ? 'Local' : text;
    case 'IMP':
      return upper == 'IMP' || text.isEmpty ? 'Import' : text;
    case 'EXP':
      return upper == 'EXP' || text.isEmpty ? 'Export' : text;
    default:
      return text.isEmpty ? code : text;
  }
}

List<SodaOption> _sbfTypeOptions(List<SodaOption> items) {
  final options = <SodaOption>[];
  final seen = <String>{};
  for (final item in items) {
    final code = _sbfTypeCode(item.code, name: item.name);
    if (code == null || !seen.add(code)) continue;
    options.add(
      SodaOption(code: code, name: _sbfTypeName(code, item.name), raw: item.raw),
    );
  }
  for (final item in const [
    SodaOption(code: 'LOC', name: 'Local'),
    SodaOption(code: 'IMP', name: 'Import'),
    SodaOption(code: 'EXP', name: 'Export'),
  ]) {
    if (seen.add(item.code)) options.add(item);
  }
  return options;
}

String? _movementCode(String? value, {String? name}) {
  for (final candidate in [value, name]) {
    if (candidate == null) continue;
    final text = candidate.trim().toUpperCase();
    if (text.isEmpty) continue;
    if (text == 'P' ||
        text == 'PU' ||
        text == 'PURCHASE' ||
        text.startsWith('PURCH')) {
      return 'P';
    }
    if (text == 'S' || text == 'SA' || text == 'SALE' || text.startsWith('SALE')) {
      return 'S';
    }
  }
  return null;
}

String _movementName(String code) => code == 'S' ? 'Sale' : 'Purchase';

List<SodaOption> _movementOptions(List<SodaOption> items) {
  final options = <SodaOption>[];
  final seen = <String>{};
  for (final item in items) {
    final code = _movementCode(item.code, name: item.name);
    if (code == null || !seen.add(code)) continue;
    options.add(
      SodaOption(code: code, name: _movementName(code), raw: item.raw),
    );
  }
  for (final item in const [
    SodaOption(code: 'P', name: 'Purchase'),
    SodaOption(code: 'S', name: 'Sale'),
  ]) {
    if (seen.add(item.code)) options.add(item);
  }
  return options;
}

const _masterFields = [
  'traN_ID',
  'v_DATE',
  'voucheR_NO',
  'selleR_CODE',
  'sacT_CODE',
  'buyeR_CODE',
  'bacT_CODE',
  'ref',
  'remarks',
  'cond',
  'brokeR_CODE',
  'coB_CODE',
  'bD_ACT_CODE',
  'coB_ACODE',
  'bcode',
  'perioD_ID',
  'astatus',
  'menU_ID',
  'dlt',
  'crediT_DAYS',
  'duE_DATE',
  'sbF_TYPE',
  'curR_CODE',
  'unit',
  'crate',
  'shiP_DATE',
  'shiP_STATUS',
  'p_S',
  'p_SHIP',
  'tranS_PS',
  'sodA_TYPE',
];

const _detailFields = [
  'traN_ID',
  'dT_CODE',
  'iteM_CODE',
  'qty',
  'unit',
  'qtY2',
  'baL_QTY',
  'rate',
  'amt',
  'dT_DESC',
  'duE_DATE',
  'bcode',
  'perioD_ID',
  'chk',
  'rT_TYPE',
];

Map<String, dynamic> _allowedMap(
  Map<String, dynamic> source,
  List<String> names,
) {
  final result = <String, dynamic>{};
  for (final name in names) {
    final value = sodaFieldLoose(source, name);
    if (value == null) continue;
    result[name] = value;
  }
  return result;
}

SodaOption? _find(List<SodaOption> items, String? code) {
  if (code == null || code.isEmpty) return null;
  for (final item in items) {
    if (item.code == code) return item;
    final customized = sodaCode(sodaFieldLoose(item.raw, 'customizedKey')) ??
        sodaCode(sodaFieldLoose(item.raw, 'customKey'));
    if (customized == code) return item;
  }
  return null;
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
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final day = date.day.toString().padLeft(2, '0');
  return '$day-${months[date.month - 1]}-${date.year}';
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
