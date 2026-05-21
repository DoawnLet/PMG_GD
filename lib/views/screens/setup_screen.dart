import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  late TextEditingController _keyCtrl;
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: context.read<AppProvider>().apiKey);
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await context.read<AppProvider>().saveApiKey(_keyCtrl.text.trim());
    setState(() => _saving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Da luu API key'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: const Border(
              bottom: BorderSide(color: Color(0xFFD3D1C7), width: 0.5),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 22),
              const SizedBox(width: 10),
              Text('Cai dat', style: theme.textTheme.headlineMedium),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Gemini API Key', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Lay tai aistudio.google.com -> Get API Key',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _keyCtrl,
                                obscureText: _obscure,
                                decoration: InputDecoration(
                                  hintText: 'AIza...',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 18,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _saving ? null : _save,
                              child: _saving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Luu'),
                            ),
                          ],
                        ),
                        Consumer<AppProvider>(
                          builder: (_, p, _) {
                            if (!p.hasApiKey) return const SizedBox.shrink();
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    size: 14,
                                    color: Color(0xFF1D9E75),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'API key da duoc cau hinh',
                                    style: TextStyle(
                                      color: Color(0xFF1D9E75),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
