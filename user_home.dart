import 'dart:async';

import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../widgets.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key, required this.api});

  final ApiClient api;

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  AppState? _state;
  String? _loadError;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _refresh();
    // تحديث دوري حتى تظهر تغييرات لوحة التحكم للمستخدم
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final s = await widget.api.fetchState();
      if (!mounted) return;
      setState(() {
        _state = s;
        _loadError = null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _loadError = e.message);
    }
  }

  Future<void> _run(Future<AppState> Function() action) async {
    try {
      final s = await action();
      if (mounted) setState(() => _state = s);
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _onSend() async {
    final v = await showDialog<List<String>>(
      context: context,
      builder: (_) => const FormDialog(
        title: 'إرسال تجريبي',
        labels: ['اسم المستلم', 'المبلغ'],
      ),
    );
    if (v == null) return;
    final amount = int.tryParse(v[1]) ?? 0;
    if (v[0].isEmpty || amount <= 0) {
      _snack('أدخل بيانات صحيحة');
      return;
    }
    await _run(() => widget.api.send(v[0], amount));
  }

  Future<void> _onDeposit() async {
    final v = await showDialog<List<String>>(
      context: context,
      builder: (_) => const FormDialog(
        title: 'شحن تجريبي',
        labels: ['المبلغ'],
      ),
    );
    if (v == null) return;
    final amount = int.tryParse(v[0]) ?? 0;
    if (amount <= 0) {
      _snack('أدخل مبلغاً صحيحاً');
      return;
    }
    await _run(() => widget.api.deposit(amount));
  }

  void _showReceive(AppState s) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('استلام'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 120),
            const SizedBox(height: 12),
            SelectableText(s.accountNumber),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _state;
    return Scaffold(
      appBar: AppBar(title: Text(s?.brand ?? 'محفظة')),
      body: s == null
          ? Center(
              child: _loadError != null
                  ? Text(_loadError!)
                  : const CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (s.notice.isNotEmpty)
                    Card(
                      color: Colors.amber.shade100,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(s.notice),
                      ),
                    ),
                  if (s.notice.isNotEmpty) const SizedBox(height: 12),
                  _BalanceCard(s: s),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.send_rounded,
                        label: 'إرسال',
                        enabled: s.features.send,
                        onTap: _onSend,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.add_card_rounded,
                        label: 'شحن',
                        enabled: s.features.deposit,
                        onTap: _onDeposit,
                      ),
                      const SizedBox(width: 8),
                      _ActionButton(
                        icon: Icons.qr_code_2,
                        label: 'استلام',
                        enabled: s.features.receive,
                        onTap: () => _showReceive(s),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'آخر العمليات',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  if (s.txs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('لا توجد عمليات'),
                    )
                  else
                    for (final t in s.txs) TxTile(tx: t),
                ],
              ),
            ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.s});

  final AppState s;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [scheme.primary, scheme.tertiary]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.userName,
            style: TextStyle(color: scheme.onPrimary.withOpacity(.85)),
          ),
          const SizedBox(height: 12),
          Text(
            'الرصيد الحالي',
            style: TextStyle(color: scheme.onPrimary.withOpacity(.85)),
          ),
          const SizedBox(height: 4),
          Text(
            formatSyp(s.balance),
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: scheme.onPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'رقم الحساب: ${s.accountNumber}',
            style: TextStyle(
              fontSize: 12,
              color: scheme.onPrimary.withOpacity(.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: enabled ? onTap : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}
