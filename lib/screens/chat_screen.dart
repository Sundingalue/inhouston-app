// lib/screens/chat_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_linkify/flutter_linkify.dart'; // 👈 NUEVO
import 'package:url_launcher/url_launcher.dart'; // 👈 NUEVO

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  static const Color brand = Color(0xFFF7BD02);
  static const Color ink = Color(0xFF0B0B0B);

  // API
  static const String kMobileBase = 'https://multi-bot-inteligente-v1.onrender.com/api/mobile';
  static const String kCoreBase   = 'https://multi-bot-inteligente-v1.onrender.com/api';

  // Args
  late final String numero;
  late final String nombre;
  late final String bot;

  // Estado
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _botEnabled = true;
  bool _sending = false;
  bool _isTicking = false;

  // Mensajes + notificador inmediato
  List<_Msg> _msgs = <_Msg>[];
  final ValueNotifier<List<_Msg>> _msgsVN = ValueNotifier<List<_Msg>>(<_Msg>[]);

  final Set<int> _seenServerTs = <int>{};
  int _lastTs = 0;
  Timer? _poll;

  String _displayTitle = '';

  // Debouncer de scroll (una sola orden de pegado)
  Timer? _scrollDebouncer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    numero = args?['numero']?.toString() ?? 'desconocido';
    nombre = args?['nombre']?.toString() ?? 'Cliente';
    bot    = args?['bot']?.toString()    ?? 'Sara';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDisplayTitle();
      await _tick(forceFull: true);
      _scrollToBottom();   // anclamos sin saltos
      _startPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _scrollDebouncer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    _msgsVN.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    _scrollToBottom(); // re-anclar al cambiar el teclado
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _tick(forceFull: true);
      _scrollToBottom();
    }
  }

  // ====== Título (business_name) ======
  Future<void> _loadDisplayTitle() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final token = sp.getString('auth_token') ?? '';
      final uri = Uri.parse('$kMobileBase/bot_info?bot=${Uri.encodeComponent(bot)}');
      final res = await http.get(uri, headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      }).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        if (data['ok'] == true) {
          final bn = (data['business_name'] ?? '').toString().trim();
          if (bn.isNotEmpty && mounted) {
            setState(() => _displayTitle = bn.toUpperCase());
            return;
          }
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _displayTitle = _companyLabelFallback());
  }

  // ====== Poll ======
  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _tick());
  }

  Future<void> _tick({bool forceFull = false}) async {
    if (_isTicking) return;
    _isTicking = true;
    try {
      final since = forceFull ? 0 : _lastTs;
      final uri = Uri.parse(
        '$kCoreBase/chat/${Uri.encodeComponent(bot)}/${Uri.encodeComponent(numero)}?since=$since',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return;

      final data = json.decode(res.body) as Map<String, dynamic>;

      final be = data['bot_enabled'];
      if (be is bool && mounted) setState(() => _botEnabled = be);

      final List msgs = (data['mensajes'] as List? ?? []);
      if (msgs.isEmpty) {
        final lts = data['last_ts'];
        if (lts is int && lts > _lastTs) _lastTs = lts;
        return;
      }

      msgs.sort((a, b) => (a['ts'] ?? 0).compareTo(b['ts'] ?? 0)); // asc

      bool added = false;
      final next = List<_Msg>.from(_msgs);

      for (final m in msgs) {
        final int ts = m['ts'] is int ? m['ts'] as int : 0;
        final String texto = (m['texto'] ?? '').toString();
        final _MsgType tipo = (m['tipo'] == 'user') ? _MsgType.user : _MsgType.bot;

        if (ts > 0) {
          if (_seenServerTs.contains(ts)) continue;
          _seenServerTs.add(ts);
          if (ts > _lastTs) _lastTs = ts;
        }

        // Fusiona eco con burbuja pendiente (por texto)
        final int idxPending = _findPendingUserIndex(texto, list: next);
        if (idxPending != -1) {
          next[idxPending] = next[idxPending].copyWith(
            pending: false,
            serverTs: ts == 0 ? next[idxPending].serverTs : ts,
          );
          added = true;
          continue;
        }

        next.add(_Msg(
          localId: 'srv-${ts}_${tipo.name}_${next.length}',
          tipo: tipo,
          texto: texto,
          serverTs: ts > 0 ? ts : null,
          pending: false,
        ));
        added = true;
      }

      if (added && mounted) {
        _msgs = next;
        _msgsVN.value = List<_Msg>.from(_msgs); // nunca vaciamos lista aquí
        _scrollToBottom(); // una sola orden, debounced
      }
    } catch (_) {
      // silencioso
    } finally {
      _isTicking = false;
    }
  }

  int _findPendingUserIndex(String text, {List<_Msg>? list}) {
    final src = list ?? _msgs;
    for (int i = src.length - 1; i >= 0; i--) {
      final m = src[i];
      if (m.tipo == _MsgType.user && m.pending && m.texto == text) return i;
    }
    return -1;
  }

  void _ensureDeliveredByText(String text) {
    final idx = _findPendingUserIndex(text);
    if (idx != -1) {
      final next = List<_Msg>.from(_msgs);
      next[idx] = next[idx].copyWith(pending: false);
      _msgs = next;
      _msgsVN.value = List<_Msg>.from(_msgs);
      _scrollToBottom();
    }
  }

  // ===== Scroll al fondo (reverse:true ⇒ fondo = minScrollExtent = 0) debounced, sin animación
  void _scrollToBottom() {
    _scrollDebouncer?.cancel();
    _scrollDebouncer = Timer(const Duration(milliseconds: 50), () {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        final double target = _scroll.position.minScrollExtent; // 0 con reverse:true
        if ((_scroll.position.pixels - target).abs() > 1) {
          _scroll.jumpTo(target); // sin animación → sin “ida y vuelta”
        }
      });
    });
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleText = (_displayTitle.isNotEmpty) ? _displayTitle : _companyLabelFallback();

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      resizeToAvoidBottomInset: true,

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xD20A0A0A),
            border: const Border(bottom: BorderSide(color: Colors.white24, width: 0.6)),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 6))],
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            left: 14, right: 14, bottom: 8,
          ),
          child: Center(
            child: Text(
              titleText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: .35),
            ),
          ),
        ),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/fondo_chat_in_houston.jpg', fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0x66000000), Color(0x33000000)],
                ),
              ),
            ),
          ),

          Column(
            children: [
              // Barra de estado del bot
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Color(0x29FFFFFF), Color(0x00FFFFFF)],
                  ),
                  border: Border(bottom: BorderSide(color: Colors.white24, width: 0.6)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _BackButtonPill(onTap: () => Navigator.pop(context)),
                    Row(
                      children: [
                        _SwitchBot(
                          enabled: _botEnabled,
                          onChanged: (v) async {
                            final ok = await _toggleBot(v);
                            if (ok && mounted) setState(()=>_botEnabled=v);
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _botEnabled ? 'BOT ON' : 'BOT OFF',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de mensajes (reactiva)
              Expanded(
                child: NotificationListener<OverscrollIndicatorNotification>(
                  onNotification: (n) { n.disallowIndicator(); return true; },
                  child: ValueListenableBuilder<List<_Msg>>(
                    valueListenable: _msgsVN,
                    builder: (context, msgs, _) {
                      return ListView.builder(
                        controller: _scroll,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                        itemCount: msgs.length,
                        itemBuilder: (context, i) {
                          final m = msgs[msgs.length - 1 - i];
                          final isUser = m.tipo == _MsgType.user;
                          return Align(
                            key: ValueKey(m.localId),
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: _Bubble(
                              isUser: isUser,
                              pending: m.pending,
                              child: Linkify( // 👈 cambio aquí
                                onOpen: (link) async {
                                  if (await canLaunchUrl(Uri.parse(link.url))) {
                                    await launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication);
                                  }
                                },
                                text: m.texto,
                                style: TextStyle(
                                  color: isUser ? const Color(0xFF151515) : const Color(0xFFF5F5F7),
                                  fontSize: 16.5,
                                  height: 1.55,
                                  fontStyle: m.pending ? FontStyle.italic : FontStyle.normal,
                                ),
                                linkStyle: const TextStyle(
                                  color: Colors.blueAccent,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              // Composer
              AnimatedPadding(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0x1AFFFFFF),
                            border: Border.all(color: Colors.white24, width: 1),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3))],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: TextField(
                            controller: _controller,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _enviar(),
                            style: const TextStyle(color: Color(0xFFE8EAF0)),
                            decoration: const InputDecoration(
                              hintText: 'Escribe tu respuesta',
                              hintStyle: TextStyle(color: Colors.white60),
                              border: InputBorder.none,
                            ),
                            onTap: _scrollToBottom,
                            onChanged: (_) => _scrollToBottom(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _enviar,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            backgroundColor: brand,
                            foregroundColor: ink,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            side: const BorderSide(color: Colors.white24, width: 1),
                            elevation: 6,
                          ),
                          child: Text(_sending ? '…' : 'Enviar',
                              style: const TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _companyLabelFallback() {
    switch (bot) {
      case 'Sara': return 'IN HOUSTON TEXAS';
      case 'Camila': return 'SENIOR LIFE INSURANCE';
      default: return bot.isNotEmpty ? bot.toUpperCase() : 'IN HOUSTON TEXAS';
    }
  }

  // ===== Enviar =====
  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;

    _forceHideKeyboard();
    setState(()=> _sending = true);

    final optimistic = _Msg(
      localId: 'loc-${DateTime.now().microsecondsSinceEpoch}',
      tipo: _MsgType.user,
      texto: texto,
      serverTs: null,
      pending: true,
    );
    _msgs = List<_Msg>.from(_msgs)..add(optimistic);
    _msgsVN.value = List<_Msg>.from(_msgs);

    _controller.clear();
    _scrollToBottom();

    try {
      final uri = Uri.parse('$kCoreBase/send_manual');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'bot': bot, 'numero': numero, 'texto': texto}),
      ).timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        await _tick(forceFull: true);
        Future.delayed(const Duration(seconds: 15), () => _ensureDeliveredByText(texto));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al enviar: HTTP ${res.statusCode}')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de red al enviar.')),
        );
      }
    } finally {
      if (mounted) setState(()=> _sending = false);
    }
  }

  void _forceHideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  Future<bool> _toggleBot(bool enabled) async {
    try {
      final uri = Uri.parse('$kCoreBase/conversation_bot');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'bot': bot, 'numero': numero, 'enabled': enabled}),
      ).timeout(const Duration(seconds: 15));
      return res.statusCode == 200;
    } catch (_) { return false; }
  }
}

// ===== modelos & UI =====
enum _MsgType { user, bot }

class _Msg {
  final String localId;
  final _MsgType tipo;
  final String texto;
  final int? serverTs;
  final bool pending;

  _Msg({
    required this.localId,
    required this.tipo,
    required this.texto,
    required this.serverTs,
    required this.pending,
  });

  _Msg copyWith({
    String? localId,
    _MsgType? tipo,
    String? texto,
    int? serverTs,
    bool? pending,
  }) {
    return _Msg(
      localId: localId ?? this.localId,
      tipo: tipo ?? this.tipo,
      texto: texto ?? this.texto,
      serverTs: serverTs ?? this.serverTs,
      pending: pending ?? this.pending,
    );
  }
}

class _Bubble extends StatelessWidget {
  final bool isUser;
  final bool pending;
  final Widget child;
  const _Bubble({required this.isUser, required this.child, this.pending = false});
  @override
  Widget build(BuildContext context) {
    final bg = isUser
        ? const LinearGradient(colors: [Colors.white, Color(0xFFF7F7F7)])
        : const LinearGradient(colors: [Color(0x1AFFFFFF), Color(0x1A000000)]);
    final border = isUser ? const Color(0x14000000) : const Color(0x24FFFFFF);

    // 👇 Compacto estilo WhatsApp
    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.78;

    return Opacity(
      opacity: pending ? 0.7 : 1.0,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
        decoration: BoxDecoration(
          gradient: bg,
          borderRadius: BorderRadius.circular(7), // antes 18
          border: Border.all(color: border, width: 1),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3), // antes 20 x 18
        margin: const EdgeInsets.symmetric(vertical: 3), // antes 12
        child: child,
      ),
    );
  }
}

class _BackButtonPill extends StatelessWidget {
  final VoidCallback onTap;
  const _BackButtonPill({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ChatScreenState.brand,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x29000000), width: 1),
      ),
      elevation: 6,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check, size: 16, color: _ChatScreenState.ink),
              SizedBox(width: 10),
              Text('Volver', style: TextStyle(fontWeight: FontWeight.w900, color: _ChatScreenState.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchBot extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _SwitchBot({required this.enabled, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!enabled),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48, height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: enabled ? const Color(0x402AA26B) : const Color(0xFF2A2F3A),
          border: Border.all(color: enabled ? const Color(0x992AA26B) : const Color(0x29000000)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Align(
          alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 22, height: 22,
            decoration: const BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
            ),
          ),
        ),
      ),
    );
  }
}
