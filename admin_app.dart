import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لوحة التحكم',
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: LoginPage(api: api),
    );
  }
}

// ---------------- تسجيل الدخول ----------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.api});

  final ApiClient api;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.api.login(_password.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => AdminHome(api: widget.api)),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.admin_panel_settings_rounded,
                    size: 56, color: scheme.primary),
                const SizedBox(height: 12),
                Text(
                  'لوحة التحكم',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _password,
                  obscureText: true,
                  onSubmitted: (_) => _login(),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    errorText: _error,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _login,
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('دخول'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- الشاشة الرئيسية للوحة ----------------

class AdminHome extends StatefulWidget {
  const AdminHome({super.key, required this.api});

  final ApiClient api;

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  AppState? _s;
  final _brand = TextEditingController();
  final _notice = TextEditingController();
  final _userName = TextEditingController();
  final _amount = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_brand, _notice, _userName, _amount]) {
      c.dispose();
    }
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _run(Future<AppState> Function() action, {String? success}) async {
    try {
      final s = await action();
      if (!mounted) return;
      setState(() => _s = s);
      if (success != null) _snack(success);
    } on ApiException catch (e) {
      _snack(e.message);
    }
  }

  Future<void> _load() async {
    await _run(() async {
      final s = await widget.api.fetchState();
      _brand.text = s.brand;
      _notice.text = s.notice;
      _userName.text = s.userName;
      return s;
    });
  }

  void _saveSettings() {
    _run(
      () => widget.api.patchSettings({
        'brand': _brand.text.trim(),
        'notice': _notice.text.trim(),
        'userName': _userName.text.trim(),
      }),
      success: 'تم حفظ الإعدادات',
    );
  }

  void _toggle(String key, bool value) {
    final f = _s!.features;
    _run(() => widget.api.patchSettings({
          'features': {
            'send': f.send,
            'deposit': f.deposit,
            'receive': f.receive,
            key: value,
          },
        }));
  }

  void _adjust(int sign) {
    final amt = int.tryParse(_amount.text.trim()) ?? 0;
    if (amt <= 0) {
      _snack('أدخل مبلغاً صحيحاً');
      return;
    }
    _amount.clear();
    _run(() => widget.api.adjustBalance(sign * amt), success: 'تم تعديل الرصيد');
  }

  void _logout() {
    widget.api.logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage(api: widget.api)),
      (_) => false,
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            tooltip: 'خروج',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section('الإعدادات العامة'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _brand,
                          decoration:
                              const InputDecoration(labelText: 'اسم التطبيق'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _userName,
                          decoration:
                              const InputDecoration(labelText: 'اسم المستخدم'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _notice,
                          decoration: const InputDecoration(
                            labelText: 'إشعار للمستخدم (اتركه فارغاً للإخفاء)',
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: FilledButton(
                            onPressed: _saveSettings,
                            child: const Text('حفظ'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _section('الميزات'),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('الإرسال'),
                        value: s.features.send,
                        onChanged: (v) => _toggle('send', v),
                      ),
                      SwitchListTile(
                        title: const Text('الشحن'),
                        value: s.features.deposit,
                        onChanged: (v) => _toggle('deposit', v),
                      ),
                      SwitchListTile(
                        title: const Text('الاستلام'),
                        value: s.features.receive,
                        onChanged: (v) => _toggle('receive', v),
                      ),
                    ],
                  ),
                ),
                _section('تعديل الرصيد'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'الرصيد الحالي: ${formatSyp(s.balance)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _amount,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'المبلغ'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: () => _adjust(1),
                                child: const Text('إضافة'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _adjust(-1),
                                child: const Text('خصم'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _section('سجل العمليات'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        if (s.txs.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('لا توجد عمليات'),
                          ),
                        for (final t in s.txs) TxTile(tx: t),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
