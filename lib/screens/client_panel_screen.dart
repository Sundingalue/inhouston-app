// lib/screens/client_panel_screen.dart
import 'dart:convert';
import 'dart:ui' show ImageFilter; // blur (glass)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_screen.dart';
import 'chat_login_screen.dart';

class ClientPanelScreen extends StatefulWidget {
  const ClientPanelScreen({super.key});
  @override
  State<ClientPanelScreen> createState() => _ClientPanelScreenState();
}

class _ClientPanelScreenState extends State<ClientPanelScreen> {
  static const String kApiBase =
      'https://multi-bot-inteligente-v1.onrender.com/api/mobile';

  bool _loading = true;
  String? _error;
  List<_Lead> _leads = [];
  String _botSeleccionado = '';

  // auth
  String _token = '';
  List<String> _allowedBots = const [];

  // Meta: name -> business_name
  Map<String, String> _companyMap = {};
  Set<String> _knownBotNames = {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString('auth_token') ?? '';

    if (token.isEmpty) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ChatLoginScreen()),
      );
      if (!mounted) return;

      final sp2 = await SharedPreferences.getInstance();
      _token = sp2.getString('auth_token') ?? '';
      _allowedBots = sp2.getStringList('allowed_bots') ?? const [];
      if (_token.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'No autenticado';
        });
        return;
      }
      await _fetchBotsMeta();
      await _fetchLeads();
      return;
    }

    _token = token;
    _allowedBots = sp.getStringList('allowed_bots') ?? const [];
    await _fetchBotsMeta();
    await _fetchLeads();
  }

  Map<String, String> _headers() => {
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  // ---------- META: bots activos desde /bots/*.json ----------
  Future<void> _fetchBotsMeta() async {
    try {
      final uri = Uri.parse('$kApiBase/bots_meta');
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final List bots = (data['bots'] as List?) ?? const [];
        final map = <String, String>{};
        final names = <String>{};
        for (final b in bots) {
          final name = (b['name'] ?? '').toString().trim();
          final company = (b['company'] ?? '').toString().trim();
          if (name.isEmpty) continue;
          names.add(name);
          map[name] = company.isNotEmpty ? company : name;
        }
        setState(() {
          _companyMap = map;
          _knownBotNames = names;
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchLeads({String bot = ''}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(
        bot.isEmpty
            ? '$kApiBase/leads'
            : '$kApiBase/leads?bot=${Uri.encodeQueryComponent(bot)}',
      );
      final res = await http.get(uri, headers: _headers());
      if (res.statusCode != 200) {
        setState(() {
          _error = 'HTTP ${res.statusCode}';
          _loading = false;
        });
        return;
      }
      final data = json.decode(res.body) as Map<String, dynamic>;
      final list = (data['leads'] as List? ?? [])
          .map((e) => _Lead.fromJson(e))
          .toList();

      setState(() {
        _leads = list;
        _loading = false;

        // ⛑️ Si el bot seleccionado ya no existe en las opciones, volver a "Todos"
        final opts = _botsUnicos;
        if (_botSeleccionado.isNotEmpty && !opts.contains(_botSeleccionado)) {
          _botSeleccionado = '';
        }
      });
    } catch (_) {
      setState(() {
        _error = 'Error de red';
        _loading = false;
      });
    }
  }

  Future<void> _updateEstado(_Lead lead, String nuevo) async {
    final uri = Uri.parse('$kApiBase/lead');
    await http.post(
      uri,
      headers: {'Content-Type': 'application/json', ..._headers()},
      body: json.encode(
          {'bot': lead.bot, 'numero': lead.numero, 'estado': nuevo}),
    );
    setState(() => lead.status = nuevo);
  }

  Future<void> _editarAlias(_Lead lead) async {
    final ctrl = TextEditingController(text: lead.notes ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar nombre visible'),
        content: TextField(
          controller: ctrl,
          decoration:
              const InputDecoration(hintText: 'Alias / nombre'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (ok != true) return;
    final alias = ctrl.text.trim();
    final uri = Uri.parse('$kApiBase/lead');
    await http.post(
      uri,
      headers: {'Content-Type': 'application/json', ..._headers()},
      body: json.encode(
          {'bot': lead.bot, 'numero': lead.numero, 'nota': alias}),
    );
    setState(() => lead.notes = alias);
  }

  Future<void> _borrarConversacion(_Lead lead) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borrar conversación'),
        content: Text(
          '¿Seguro que quieres borrar TODO el chat de:\n\n'
          'Bot: ${lead.bot}\nNúmero: ${lead.numero}\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Borrar')),
        ],
      ),
    );
    if (ok != true) return;

    final uri = Uri.parse('$kApiBase/delete');
    final res = await http.post(
      uri,
      headers: {'Content-Type': 'application/json', ..._headers()},
      body: json.encode(
          {'bot': lead.bot, 'numero': lead.numero}),
    );
    if (res.statusCode == 200) {
      setState(() {
        // quita de la lista local
        _leads.removeWhere(
            (l) => l.bot == lead.bot && l.numero == lead.numero);

        // ⛑️ Si ya no hay leads de ese bot y estaba seleccionado, resetear
        final queda = _leads.any((l) => l.bot == lead.bot);
        if (!queda && _botSeleccionado == lead.bot) {
          _botSeleccionado = '';
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Conversación borrada')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo borrar')));
    }
  }

  // === Filtros ===

  List<String> get _botsUnicosRaw {
    final set = <String>{};
    for (final l in _leads) {
      if (l.bot.isNotEmpty) set.add(l.bot);
    }
    // filtra por bots conocidos de los JSON (si hay meta)
    if (_knownBotNames.isNotEmpty) {
      set.retainAll(_knownBotNames);
    }
    final list = set.toList()
      ..sort((a, b) {
        final la = _companyMap[a] ?? a;
        final lb = _companyMap[b] ?? b;
        return la.compareTo(lb);
      });
    return list;
  }

  List<String> get _botsUnicos {
    if (_allowedBots.isEmpty || _allowedBots.contains('*')) {
      return _botsUnicosRaw;
    }
    return _botsUnicosRaw
        .where((b) => _allowedBots.contains(b))
        .toList();
  }

  List<_Lead> get _visibleLeads {
  final byBot = _botSeleccionado.isEmpty
      ? _leads
      : _leads.where((l) => l.bot == _botSeleccionado).toList();

  // 🧽 Filtrar: eliminar los que empiezan por "ig:"
  final sinInstagram = byBot.where((l) => !l.numero.startsWith('ig:')).toList();

  if (_allowedBots.isEmpty || _allowedBots.contains('*')) {
    return sinInstagram;
  }
  return sinInstagram.where((l) => _allowedBots.contains(l.bot)).toList();
}

  String _companyFor(String bot) => _companyMap[bot] ?? bot;

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xffF7BD02);
    final visibleLeads = _visibleLeads;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 8,
        backgroundColor: const Color(0xD20A0A0A),
        centerTitle: true,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Panel de Conversaciones',
          style: TextStyle(
            color: brand,
            fontWeight: FontWeight.w800,
            letterSpacing: .3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.6),
          child: Container(height: 0.6, color: Colors.white24),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/fondo_chat_in_houston.jpg',
                fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xB3000000), Color(0x66000000)],
                ),
              ),
            ),
          ),

          Column(
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0x1AFFFFFF),
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: Colors.white24, width: 1),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black45,
                              blurRadius: 18,
                              offset: Offset(0, 8))
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: _EmpresaSelector(
                              value: _botSeleccionado,
                              options: _botsUnicos,
                              companyFor: _companyFor,
                              onChanged: (val) {
                                setState(() => _botSeleccionado = val ?? '');
                                _fetchLeads(bot: _botSeleccionado);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          _LogoutPill(
                            onTap: () async {
                              final sp =
                                  await SharedPreferences.getInstance();
                              await sp.remove('auth_token');
                              await sp.remove('allowed_bots');
                              if (!mounted) return;
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ChatLoginScreen(),
                                ),
                              );
                              if (!mounted) return;
                              await _bootstrap();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Colors.white))
                    : _error != null
                        ? Center(
                            child: Text('Error: $_error',
                                style: const TextStyle(
                                    color: Colors.white)),
                          )
                        : visibleLeads.isEmpty
                            ? _NoLeadsCard(bot: _botSeleccionado)
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 16),
                                itemCount: visibleLeads.length,
                                itemBuilder: (context, i) {
                                  final lead = visibleLeads[i];
                                  return _LeadCard(
                                    lead: lead,
                                    onVer: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const ChatScreen(),
                                          settings: RouteSettings(
                                            arguments: {
                                              'bot': lead.bot,
                                              'numero': lead.numero,
                                              'nombre': (lead.notes
                                                              ?.isNotEmpty ??
                                                          false)
                                                      ? lead.notes
                                                      : lead.numero,
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    onEditarAlias: () =>
                                        _editarAlias(lead),
                                    onBorrar: () =>
                                        _borrarConversacion(lead),
                                    onCambiarEstado: (nuevo) =>
                                        _updateEstado(lead, nuevo),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Lead {
  final String bot;
  final String numero;
  final String lastMessage;
  final String lastSeen;
  final int messages;
  String status;
  String? notes;

  _Lead({
    required this.bot,
    required this.numero,
    required this.lastMessage,
    required this.lastSeen,
    required this.messages,
    required this.status,
    required this.notes,
  });

  factory _Lead.fromJson(Map<String, dynamic> j) => _Lead(
        bot: (j['bot'] ?? '').toString(),
        numero: (j['numero'] ?? '').toString(),
        lastMessage: (j['last_message'] ?? '').toString(),
        lastSeen: (j['last_seen'] ?? '').toString(),
        messages:
            int.tryParse((j['messages'] ?? '0').toString()) ?? 0,
        status: (j['status'] ?? '').toString(),
        notes: j['notes']?.toString(),
      );
}

class _EmpresaSelector extends StatelessWidget {
  final String value;                // bot_name actual
  final List<String> options;        // lista de bot_name
  final String Function(String) companyFor; // label
  final ValueChanged<String?> onChanged;
  const _EmpresaSelector({
    required this.value,
    required this.options,
    required this.companyFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // 🛡️ Asegura que el value exista. Si no, usa '' (Todos)
    final safeValue = options.contains(value) ? value : '';

    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: '',
        child: Text('— Todos —',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.w800, color: Colors.white)),
      ),
      ...options.map((bot) {
        final label = companyFor(bot);
        return DropdownMenuItem<String>(
          value: bot,
          child: Row(
            children: [
              const Icon(Icons.apartment_rounded,
                  size: 18, color: Colors.white),
              const SizedBox(width: 8),
              // 👇 evita desbordes en el botón y en el menú
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    ];

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        border:
            Border.all(color: Colors.white24, width: 1.5),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 14)
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white),
          items: items,
          onChanged: onChanged,
          dropdownColor: const Color(0xE6101010),
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700),
          // 👇 asegura que el “item seleccionado” también haga ellipsis
          selectedItemBuilder: (context) {
            final display = <Widget>[
              const Text('— Todos —',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: Colors.white)),
              ...options.map((bot) {
                final label = companyFor(bot);
                return Row(
                  children: [
                    const Icon(Icons.apartment_rounded,
                        size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ];
            return display;
          },
        ),
      ),
    );
  }
}

class _LogoutPill extends StatelessWidget {
  final VoidCallback onTap;
  const _LogoutPill({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0x1AFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(
            color: Colors.white24, width: 1.5),
      ),
      elevation: 8,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: const Padding(
          padding:
              EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Cerrar sesión',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  final _Lead lead;
  final VoidCallback onVer;
  final VoidCallback onEditarAlias;
  final VoidCallback onBorrar;
  final ValueChanged<String> onCambiarEstado;

  const _LeadCard({
    required this.lead,
    required this.onVer,
    required this.onEditarAlias,
    required this.onBorrar,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    const brand = Color(0xffF7BD02);
    final aliasVisible = (lead.notes?.trim().isNotEmpty ?? false)
        ? lead.notes!.trim()
        : lead.numero.replaceFirst('whatsapp:', '');

    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: const [
          BoxShadow(
              color: Colors.black45,
              blurRadius: 16,
              offset: Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título + editar alias
          Row(
            children: [
              const Icon(Icons.link_rounded, color: brand),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  aliasVisible,
                  style: const TextStyle(
                      color: brand,
                      fontWeight: FontWeight.w900,
                      fontSize: 19),
                ),
              ),
              IconButton(
                onPressed: onEditarAlias,
                icon: const Icon(Icons.edit_note_rounded,
                    color: Color(0xFFFFD54F)),
                tooltip: 'Editar nombre visible',
              ),
            ],
          ),
          const SizedBox(height: 0),
          const Divider(color: Colors.white24, thickness: .6),
          const SizedBox(height: 0),

          // Último mensaje
          Row(
            children: [
              const Icon(Icons.mail_outline_rounded,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lead.lastMessage.isEmpty ? '—' : lead.lastMessage,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Fecha
          Row(
            children: [
              const Icon(Icons.event_note_outlined,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(lead.lastSeen,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 14),

          // Estado
          Row(
            children: [
              const Icon(Icons.label_important_outline_rounded,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text('Estado:',
                  style: TextStyle(color: Colors.white, fontSize: 15)),
              const SizedBox(width: 10),
              SizedBox(
                height: 30,
                width: 160,
                child: DropdownButtonFormField<String>(
                  value: lead.status,
                  items: const [
                    DropdownMenuItem(
                        value: 'nuevo',
                        child: Text('nuevo',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13))),
                    DropdownMenuItem(
                        value: 'en espera',
                        child: Text('en espera',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13))),
                    DropdownMenuItem(
                        value: 'cerrado',
                        child: Text('cerrado',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13))),
                  ],
                  onChanged: (v) {
                    if (v != null) onCambiarEstado(v);
                  },
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded,
                      color: Colors.black, size: 18),
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 13),
                  menuMaxHeight: 220,
                  dropdownColor: Colors.white,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    filled: true,
                    fillColor: brand,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: brand, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: brand, width: 1.2),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: brand, width: 1),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Acciones: SIEMPRE en una sola fila
          Row(
            children: [
              // Botón BORRAR compacto (ancho fijo pequeño)
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 112, maxWidth: 128),
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onBorrar,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      textStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                      foregroundColor: const Color(0xFFEF5350),
                      side: const BorderSide(color: Color(0xFFEF5350), width: 1.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(0, 40),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Borrar'),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Botón VER que ocupa el resto
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: onVer,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      foregroundColor: brand,
                      side: const BorderSide(color: brand, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.visibility_rounded),
                    label: const Text('Ver conversación',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Vidrio (blur) debajo del card
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: card,
        ),
      ),
    );
  }
}

class _NoLeadsCard extends StatelessWidget {
  final String bot;
  const _NoLeadsCard({required this.bot});
  @override
  Widget build(BuildContext context) {
    final txt = bot.isEmpty
        ? 'No hay leads disponibles todavía.'
        : 'No hay conversaciones para la compañía $bot.';
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 18),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0x99FFF3CD),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Text(
              txt,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xff333333),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
