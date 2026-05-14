// ALAG-AP 
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert'; // add this import if not already present
import 'dart:typed_data';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN SECURITY HELPER
// ─────────────────────────────────────────────────────────────────────────────
class ScreenSecurity {
  static const _channel = MethodChannel('com.alagap.app/screen_security');

  static Future<void> enableSecureMode() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _channel.invokeMethod('setSecureFlag', {'secure': true});
      }
    } catch (_) {}
  }

  static Future<void> disableSecureMode() async {
    if (kIsWeb) return;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await _channel.invokeMethod('setSecureFlag', {'secure': false});
      }
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────────────────────────────────────
final themeNotifier = ValueNotifier<bool>(false);

class AC {
  static Color cream(bool d)     => d ? const Color(0xFF2A2420) : const Color(0xFFFFF8F0);
  static Color card(bool d)      => d ? const Color(0xFF332E2A) : Colors.white;
  static Color blush(bool d)     => d ? const Color(0xFF5A3530) : const Color(0xFFFFD6CC);
  static Color peach(bool d)     => d ? const Color(0xFFE8846A) : const Color(0xFFFFB5A0);
  static Color sage(bool d)      => d ? const Color(0xFF4A6B5A) : const Color(0xFFB5D5C5);
  static Color sky(bool d)       => d ? const Color(0xFF2E4A6A) : const Color(0xFFBFDEF5);
  static Color lav(bool d)       => d ? const Color(0xFF3A3060) : const Color(0xFFD8CCF0);
  static Color sb(bool d)        => d ? const Color(0xFFD4B8A8) : const Color(0xFF8B6F5E);
  static Color mt(bool d)        => d ? const Color(0xFFB8A89A) : const Color(0xFF6B5B52);
  static Color lt(bool d)        => d ? const Color(0xFF8A7A72) : const Color(0xFF9C8B84);
  static Color bg1(bool d)       => d ? const Color(0xFF1A1612) : const Color(0xFFFFF0E8);
  static Color bg2(bool d)       => d ? const Color(0xFF1A1A2A) : const Color(0xFFF5EEF8);
  static const gold   = Color(0xFFFFD700);
  static const streak = Color(0xFFFF6B35);
  static const online = Color(0xFF4CAF50);
}

bool dark(BuildContext c) => Theme.of(c).brightness == Brightness.dark;

BoxDecoration gbg(bool d) => BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AC.bg1(d), AC.bg2(d)],
  ),
);

ThemeData tLight() => ThemeData(
  brightness: Brightness.light,
  useMaterial3: true,
  fontFamily: 'Georgia',
  scaffoldBackgroundColor: const Color(0xFFFFF8F0),
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFFB5A0)),
);

ThemeData tDark() => ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  fontFamily: 'Georgia',
  scaffoldBackgroundColor: const Color(0xFF1A1612),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFFFB5A0),
    brightness: Brightness.dark,
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// ENUMS
// ─────────────────────────────────────────────────────────────────────────────
enum UserRole { sender, receiver, both }
enum MapFilter { all, shelter, welfare, vet, barangay, cityHall }
enum OrgType   { shelter, vet, welfare, clinic, barangay, cityHall, other }

extension URX on UserRole {
  String get label {
    switch (this) {
      case UserRole.sender:   return 'Sender';
      case UserRole.receiver: return 'Receiver';
      case UserRole.both:     return 'Both';
    }
  }
  String get desc {
    switch (this) {
      case UserRole.sender:   return 'Report animals & send photos';
      case UserRole.receiver: return 'Receive reports as shelter/org';
      case UserRole.both:     return 'Do everything';
    }
  }
  IconData get icon {
    switch (this) {
      case UserRole.sender:   return Icons.send_rounded;
      case UserRole.receiver: return Icons.inbox_rounded;
      case UserRole.both:     return Icons.swap_horiz_rounded;
    }
  }
}

extension MFX on MapFilter {
  String get label {
    switch (this) {
      case MapFilter.all:      return 'All';
      case MapFilter.shelter:  return 'Shelters';
      case MapFilter.welfare:  return 'Welfare';
      case MapFilter.vet:      return 'Veterinary';
      case MapFilter.barangay: return 'Barangay';
      case MapFilter.cityHall: return 'City Hall';
    }
  }
  String get emoji {
    switch (this) {
      case MapFilter.all:      return '🗺️';
      case MapFilter.shelter:  return '🏠';
      case MapFilter.welfare:  return '🐾';
      case MapFilter.vet:      return '🩺';
      case MapFilter.barangay: return '🏘️';
      case MapFilter.cityHall: return '🏛️';
    }
  }
}

extension OTX on OrgType {
  String get label {
    switch (this) {
      case OrgType.shelter:  return 'Animal Shelter';
      case OrgType.vet:      return 'Veterinary';
      case OrgType.welfare:  return 'Animal Welfare';
      case OrgType.clinic:   return 'Vet Clinic';
      case OrgType.barangay: return 'Barangay Hall';
      case OrgType.cityHall: return 'City Hall';
      case OrgType.other:    return 'Animal Org';
    }
  }
  String get emoji {
    switch (this) {
      case OrgType.shelter:  return '🏠';
      case OrgType.vet:      return '🩺';
      case OrgType.welfare:  return '🐾';
      case OrgType.clinic:   return '💊';
      case OrgType.barangay: return '🏘️';
      case OrgType.cityHall: return '🏛️';
      case OrgType.other:    return '🌿';
    }
  }
  MapFilter get mf {
    switch (this) {
      case OrgType.shelter:  return MapFilter.shelter;
      case OrgType.welfare:  return MapFilter.welfare;
      case OrgType.vet:
      case OrgType.clinic:   return MapFilter.vet;
      case OrgType.barangay: return MapFilter.barangay;
      case OrgType.cityHall: return MapFilter.cityHall;
      default:               return MapFilter.all;
    }
  }
  Color pc(bool d) {
    switch (this) {
      case OrgType.shelter:  return AC.sage(d);
      case OrgType.vet:      return AC.sky(d);
      case OrgType.welfare:  return AC.lav(d);
      case OrgType.clinic:   return d ? const Color(0xFF6A4A2A) : const Color(0xFFFFE8D6);
      case OrgType.barangay: return d ? const Color(0xFF4A5A2A) : const Color(0xFFE8F5D6);
      case OrgType.cityHall: return d ? const Color(0xFF4A3A6A) : const Color(0xFFE8D6F5);
      default:               return d ? const Color(0xFF3A5A3A) : const Color(0xFFD6EAD8);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────────────────────────────────────
class ImageArg {
  final File?      file;
  final Uint8List? bytes;
  final String?    webUrl;
  const ImageArg({this.file, this.bytes, this.webUrl});
  bool get has => file != null || bytes != null || webUrl != null;
}

Widget bImg(ImageArg? a, {BoxFit fit = BoxFit.cover}) {
  if (a == null || !a.has) return const SizedBox.shrink();
  if (a.webUrl != null) {
    return Image.network(a.webUrl!, fit: fit,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
  }
  if (a.bytes != null) {
    return Image.memory(a.bytes!, fit: fit,
      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image));
  }
  return Image.file(a.file!, fit: fit);
}

class OrgPin {
  final String  name;
  final OrgType type;
  final LatLng  pos;
  final String? phone;
  final String? website;
  final double  km;
  const OrgPin({
    required this.name, required this.type, required this.pos,
    this.phone, this.website, required this.km,
  });
  String get dist => km < 1 ? '${(km * 1000).toInt()} m' : '${km.toStringAsFixed(1)} km';
}

class MUser {
  final String   id, username, emoji;
  final UserRole role;
  final bool     online;
  const MUser({
    required this.id, required this.username, required this.emoji,
    required this.role, this.online = false,
  });
  String get desc => role.desc;
}

class ChatMsg {
  final String   sid, text;
  final DateTime time;
  ChatMsg({required this.sid, required this.text, required this.time});
}

class Friend {
  final MUser   user;
  bool          pinned;
  List<ChatMsg> msgs;
  Friend({required this.user, this.pinned = false, List<ChatMsg>? msgs})
      : msgs = msgs ?? [];
}

class BItem {
  final String   id, title, subtitle, emoji;
  final DateTime at;
  BItem({required this.id, required this.title, required this.subtitle,
         required this.emoji, required this.at});
}

const kAvatars = ['🐶','🐱','🐰','🐻','🦊','🐼','🐨','🐯','🦁','🐸','🐧','🦋'];

final kMock = <MUser>[
  const MUser(id:'u1', username:'PAWS Philippines',  emoji:'🐾', role:UserRole.receiver, online:true),
  const MUser(id:'u2', username:'Jim',               emoji:'🐶', role:UserRole.sender),
  const MUser(id:'u3', username:'CityVet Office',    emoji:'🩺', role:UserRole.receiver, online:true),
  const MUser(id:'u4', username:'JR Morales',        emoji:'😊', role:UserRole.both),
  const MUser(id:'u5', username:'Jasmine',           emoji:'🏠', role:UserRole.receiver),
  const MUser(id:'u6', username:'Happy Paws Clinic', emoji:'💊', role:UserRole.receiver, online:true),
  const MUser(id:'u7', username:'Frances',           emoji:'🦋', role:UserRole.sender),
  const MUser(id:'u8', username:'Cloyd',             emoji:'🌿', role:UserRole.receiver),
];

// ─────────────────────────────────────────────────────────────────────────────
// APP USER
// ─────────────────────────────────────────────────────────────────────────────
class AppUser {
  String     username, email, displayName;
  String?    bio;
  UserRole   role;
  int        reports, adoptions, coins, streak;
  Map<String,int> coinLog;
  String?    avEmoji;
  Uint8List? avBytes;
  bool       firstTime, agreedTerms;
  List<Friend> friends;
  List<BItem>  bookmarks;

  AppUser({
    required this.username,
    required this.email,
    String? displayName,
    this.bio,
    this.role = UserRole.both,
    this.reports   = 0,
    this.adoptions = 0,
    this.coins     = 0,
    this.streak    = 0,
    Map<String,int>? coinLog,
    this.avEmoji,
    this.avBytes,
    this.firstTime   = true,
    this.agreedTerms = false,
    List<Friend>? friends,
    List<BItem>?  bookmarks,
  })  : displayName = displayName ?? username,
        coinLog   = coinLog   ?? {},
        friends   = friends   ?? [],
        bookmarks = bookmarks ?? [];

  Set<int> get loggedDays {
    final p = _mp();
    return coinLog.keys
        .where((k) => k.startsWith(p))
        .map((k) => int.parse(k.split('-')[2]))
        .toSet();
  }

  int get monthCoins {
    final p = _mp();
    return coinLog.entries
        .where((e) => e.key.startsWith(p))
        .fold(0, (s, e) => s + e.value);
  }

  static String _mp() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}';
  }

  static String today() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  static String yesterday() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
  }
}

AppUser? curUser;
bool appDark = false;

// ─────────────────────────────────────────────────────────────────────────────
// STORE
// ─────────────────────────────────────────────────────────────────────────────
class St {
  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    appDark = p.getBool('dm') ?? false;
    themeNotifier.value = appDark;
    final un = p.getString('un');
    if (un != null) {
      Uint8List? av;
      final b = p.getString('ab');
      if (b != null) {
        try { av = base64Decode(b); } catch (_) {}
      }
      Map<String,int> cl = {};
      final lj = p.getString('cl');
      if (lj != null) {
        try {
          cl = (jsonDecode(lj) as Map).map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          );
        } catch (_) {}
      }
      final rs = p.getString('role') ?? '';
      UserRole r = UserRole.values.firstWhere(
        (e) => e.name == rs, orElse: () => UserRole.both,
      );
      curUser = AppUser(
        username:     un,
        email:        p.getString('em') ?? '',
        displayName:  p.getString('dn'),
        bio:          p.getString('bio'),
        role:         r,
        reports:      p.getInt('rep')    ?? 0,
        adoptions:    p.getInt('ado')    ?? 0,
        coins:        p.getInt('coins')  ?? 0,
        streak:       p.getInt('streak') ?? 0,
        coinLog:      cl,
        avEmoji:      p.getString('ae'),
        avBytes:      av,
        firstTime:    p.getBool('ft') ?? true,
        agreedTerms:  p.getBool('at') ?? false,
      );
      _seedFriends();
    }
  }

  static void _seedFriends() {
    if (curUser == null || curUser!.friends.isNotEmpty) return;
    curUser!.friends = [
      Friend(
        user: kMock[0],
        msgs: [
          ChatMsg(sid: 'u1', text: 'Hello! We received your animal report.',
                  time: DateTime.now().subtract(const Duration(hours: 2))),
          ChatMsg(sid: 'me', text: 'Thank you! Is the dog safe?',
                  time: DateTime.now().subtract(const Duration(hours: 1))),
          ChatMsg(sid: 'u1', text: "Yes! He's being cared for 🐶",
                  time: DateTime.now().subtract(const Duration(minutes: 30))),
        ],
      ),
      Friend(user: kMock[2]),
      Friend(user: kMock[3], pinned: true),
    ];
  }

  static Future<void> save() async {
    if (curUser == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setString('un',     curUser!.username);
    await p.setString('em',     curUser!.email);
    await p.setString('dn',     curUser!.displayName);
    if (curUser!.bio != null) {
      await p.setString('bio', curUser!.bio!);
    } else {
      await p.remove('bio');
    }
    await p.setString('role',   curUser!.role.name);
    await p.setInt('rep',       curUser!.reports);
    await p.setInt('ado',       curUser!.adoptions);
    await p.setInt('coins',     curUser!.coins);
    await p.setInt('streak',    curUser!.streak);
    await p.setString('cl',     jsonEncode(curUser!.coinLog));
    if (curUser!.avEmoji != null) {
      await p.setString('ae', curUser!.avEmoji!);
    } else {
      await p.remove('ae');
    }
    if (curUser!.avBytes != null) {
      await p.setString('ab', base64Encode(curUser!.avBytes!));
    } else {
      await p.remove('ab');
    }
    await p.setBool('dm', appDark);
    await p.setBool('ft', curUser!.firstTime);
    await p.setBool('at', curUser!.agreedTerms);
  }

  static Future<void> clear() async {
    await (await SharedPreferences.getInstance()).clear();
  }

  static Future<(bool, int, int)> bonus() async {
    if (curUser == null) return (false, 0, 0);
    final t = AppUser.today();
    if (curUser!.coinLog.containsKey(t)) return (false, 0, curUser!.streak);
    final ns = curUser!.coinLog.containsKey(AppUser.yesterday())
        ? curUser!.streak + 1
        : 1;
    final c = math.min(ns, 7);
    curUser!.streak = ns;
    curUser!.coinLog[t] = c;
    curUser!.coins += c;
    await save();
    return (true, c, ns);
  }

  static Future<void> resetStreak() async {
    curUser?.streak = 0;
    await save();
  }

  static Future<List<String>> hist() async {
    return (await SharedPreferences.getInstance()).getStringList('sh') ?? [];
  }

  static Future<void> addHist(String q) async {
    if (q.trim().isEmpty) return;
    final p = await SharedPreferences.getInstance();
    final h = p.getStringList('sh') ?? [];
    h.remove(q);
    h.insert(0, q);
    if (h.length > 20) h.removeLast();
    await p.setStringList('sh', h);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERPASS + NOMINATIM
// ─────────────────────────────────────────────────────────────────────────────
Future<List<OrgPin>> fetchOrgs(LatLng center, double rkm, MapFilter f) async {
  final r   = (rkm * 1000).toInt();
  final lat = center.latitude;
  final lng = center.longitude;

  final buf = StringBuffer();
  if (f == MapFilter.all || f == MapFilter.vet) {
    buf.writeln('node["amenity"="veterinary"](around:$r,$lat,$lng);');
    buf.writeln('way["amenity"="veterinary"](around:$r,$lat,$lng);');
    buf.writeln('node["healthcare"="veterinary"](around:$r,$lat,$lng);');
    buf.writeln('node["name"~"[Vv]et",i](around:$r,$lat,$lng);');
    buf.writeln('node["name"~"[Cc]linic",i](around:$r,$lat,$lng);');
  }
  if (f == MapFilter.all || f == MapFilter.shelter) {
    buf.writeln('node["amenity"="animal_shelter"](around:$r,$lat,$lng);');
    buf.writeln('way["amenity"="animal_shelter"](around:$r,$lat,$lng);');
    buf.writeln('node["name"~"[Ss]helter",i](around:$r,$lat,$lng);');
    buf.writeln('node["name"~"[Rr]escue",i](around:$r,$lat,$lng);');
  }
  if (f == MapFilter.all || f == MapFilter.welfare) {
    buf.writeln('node["amenity"="animal_boarding"](around:$r,$lat,$lng);');
    buf.writeln('node["shop"="pet"](around:$r,$lat,$lng);');
    buf.writeln('node["name"~"[Pp]aws",i](around:$r,$lat,$lng);');
    buf.writeln('node["name"~"[Aa]nimal",i](around:$r,$lat,$lng);');
  }
  if (f == MapFilter.all || f == MapFilter.barangay) {
    buf.writeln('node["office"="government"]["name"~"[Bb]arangay",i](around:$r,$lat,$lng);');
    buf.writeln('node["name"~"[Bb]arangay [Hh]all",i](around:$r,$lat,$lng);');
  }
  if (f == MapFilter.all || f == MapFilter.cityHall) {
    buf.writeln('node["amenity"="townhall"](around:$r,$lat,$lng);');
    buf.writeln('node["name"~"[Cc]ity [Hh]all",i](around:$r,$lat,$lng);');
  }

  final nodes = buf.toString();
  if (nodes.trim().isEmpty) return _fallback(center);

  final query = '[out:json][timeout:30];\n(\n$nodes);\nout center;';

  try {
    http.Response resp;
    if (kIsWeb) {
      final enc = Uri.encodeComponent(
        'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(query)}',
      );
      resp = await http
          .get(Uri.parse('https://api.allorigins.win/get?url=$enc'),
               headers: {'User-Agent': 'ALAG-AP/1.0 alagap.philippines@gmail.com'})
          .timeout(const Duration(seconds: 30));
    } else {
      resp = await http
          .post(Uri.parse('https://overpass-api.de/api/interpreter'),
                body: query,
                headers: {'Content-Type': 'application/x-www-form-urlencoded'})
          .timeout(const Duration(seconds: 30));
    }

    if (resp.statusCode != 200) return _fallback(center);

    Map<String,dynamic> data;
    if (kIsWeb) {
      final w = jsonDecode(resp.body) as Map<String,dynamic>;
      data    = jsonDecode(w['contents'] as String? ?? '{}') as Map<String,dynamic>;
    } else {
      data = jsonDecode(resp.body) as Map<String,dynamic>;
    }

    final els = (data['elements'] as List?) ?? [];
    if (els.isEmpty) return _fallback(center);

    final dist  = const Distance();
    final pins  = <OrgPin>[];
    final seen  = <String>{};

    for (final el in els) {
      final tags = (el['tags'] as Map<String,dynamic>?) ?? {};
      final name = (tags['name'] ?? tags['operator'] ?? 'Unnamed').toString();
      if (seen.contains(name)) continue;
      seen.add(name);

      double? elat, elng;
      if (el['type'] == 'node') {
        elat = (el['lat'] as num?)?.toDouble();
        elng = (el['lon'] as num?)?.toDouble();
      } else if (el['center'] != null) {
        elat = (el['center']['lat'] as num?)?.toDouble();
        elng = (el['center']['lon'] as num?)?.toDouble();
      }
      if (elat == null || elng == null) continue;

      final p   = LatLng(elat, elng);
      final km  = dist.as(LengthUnit.Kilometer, center, p);
      final am  = (tags['amenity']    ?? '').toString().toLowerCase();
      final sh  = (tags['shop']       ?? '').toString().toLowerCase();
      final he  = (tags['healthcare'] ?? '').toString().toLowerCase();
      final of  = (tags['office']     ?? '').toString().toLowerCase();
      final nl  = name.toLowerCase();

      OrgType t = OrgType.other;
      if (am == 'veterinary' || he == 'veterinary')           t = OrgType.vet;
      else if (am == 'animal_shelter')                         t = OrgType.shelter;
      else if (sh == 'pet' || am == 'animal_boarding')         t = OrgType.clinic;
      else if (am == 'townhall' || (of == 'government' && nl.contains('city hall'))) t = OrgType.cityHall;
      else if (of == 'government' || nl.contains('barangay'))  t = OrgType.barangay;
      else if (nl.contains('vet') || nl.contains('clinic'))    t = OrgType.vet;
      else if (nl.contains('shelter') || nl.contains('rescue'))t = OrgType.shelter;
      else if (nl.contains('paws') || nl.contains('animal'))   t = OrgType.welfare;

      if (f != MapFilter.all && t.mf != f) continue;

      pins.add(OrgPin(
        name: name, type: t, pos: p,
        phone:   tags['phone']?.toString(),
        website: tags['website']?.toString(),
        km: km,
      ));
    }

    pins.sort((a, b) => a.km.compareTo(b.km));
    return pins.isNotEmpty ? pins : _fallback(center);
  } catch (_) {
    return _fallback(center);
  }
}

List<OrgPin> _fallback(LatLng c) {
  final la = c.latitude;
  final ln = c.longitude;
  return [
    OrgPin(name:'PAWS Animal Welfare',    type:OrgType.welfare,  pos:LatLng(la+0.007,ln+0.005), phone:'+6391712345', km:0.8),
    OrgPin(name:'City Veterinary Office', type:OrgType.vet,      pos:LatLng(la-0.009,ln+0.008), phone:'+6391798765', km:1.2),
    OrgPin(name:'CARA Philippines',       type:OrgType.shelter,  pos:LatLng(la+0.015,ln-0.010), phone:'+6391812345', km:2.1),
    OrgPin(name:'Happy Paws Clinic',      type:OrgType.clinic,   pos:LatLng(la-0.016,ln-0.012), phone:'+6391912345', km:2.4),
    OrgPin(name:'Barangay Hall',          type:OrgType.barangay, pos:LatLng(la-0.003,ln+0.002), phone:'+6391500000', km:0.3),
    OrgPin(name:'City Hall',              type:OrgType.cityHall, pos:LatLng(la+0.012,ln+0.010), phone:'+6391600000', km:1.8),
  ];
}

Future<List<OrgPin>> searchNom(String q, LatLng? center) async {
  final dist   = const Distance();
  final results = <OrgPin>[];
  final seen    = <String>{};
  for (final term in ['veterinary $q', 'animal shelter $q', 'pet clinic $q', '$q Philippines']) {
    final url = 'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(term)}&format=json&limit=5&addressdetails=0';
    try {
      final r = await http.get(Uri.parse(url), headers: {
        'User-Agent': 'ALAG-AP/1.0 alagap.philippines@gmail.com',
        'Accept-Language': 'en',
      }).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) continue;
      for (final el in jsonDecode(r.body) as List) {
        final name = (el['display_name'] ?? '').toString().split(',').first.trim();
        if (seen.contains(name) || name.isEmpty) continue;
        seen.add(name);
        final la = double.tryParse(el['lat']?.toString() ?? '') ?? 0;
        final ln = double.tryParse(el['lon']?.toString() ?? '') ?? 0;
        if (la == 0 && ln == 0) continue;
        final p  = LatLng(la, ln);
        final km = center != null ? dist.as(LengthUnit.Kilometer, center, p) : 0.0;
        results.add(OrgPin(name: name, type: OrgType.other, pos: p, km: km));
      }
    } catch (_) { continue; }
  }
  results.sort((a, b) => a.km.compareTo(b.km));
  return results;
}

Future<List<String>> suggest(String q) async {
  if (q.trim().length < 2) return [];
  final url = 'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent('$q animal Philippines')}&format=json&limit=5&addressdetails=0';
  try {
    final r = await http.get(Uri.parse(url),
        headers: {'User-Agent': 'ALAG-AP/1.0 alagap.philippines@gmail.com'})
        .timeout(const Duration(seconds: 8));
    if (r.statusCode != 200) return [];
    return (jsonDecode(r.body) as List)
        .map((e) => (e['display_name'] ?? '').toString().split(',').first.trim())
        .where((s) => s.isNotEmpty)
        .take(5)
        .toList();
  } catch (_) {
    return [];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ScreenSecurity.enableSecureMode();
  
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exception}');
    debugPrint('STACK: ${details.stack}');
  };

  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }
  
  await St.load();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (_, d, __) {
        return MaterialApp(
          title: 'ALAG-AP',
          debugShowCheckedModeBanner: false,
          theme: tLight(),
          darkTheme: tDark(),
          themeMode: d ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/':         (_) => const Router_(),
            '/splash':   (_) => const SplashScreen(),
            '/terms':    (_) => const TermsScreen(),
            '/onboard':  (_) => const OnboardScreen(),
            '/auth':     (_) => const AuthScreen(),
            '/home':     (_) => const HomeScreen(),
            '/adopt':    (_) => const AdoptScreen(),
            '/report':   (_) => const ReportScreen(),
            '/profile':  (_) => const ProfileScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/friends':  (_) => const FriendsScreen(),
            '/bookmarks':(_) => const BookmarksScreen(),
          },
        );
      },
    );
  }
}

class Router_ extends StatelessWidget {
  const Router_();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/splash');
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// App logo widget — loads assets/images/logo.png, falls back to 🐾 emoji.
// ─────────────────────────────────────────────────────────────────────────────
// STEP 1: Make sure these imports exist at the top of your main.dart
//   import 'dart:convert';
//   import 'dart:typed_data';
// (dart:convert and dart:typed_data are already imported in your file ✓)
//
// STEP 2: Replace the appLogo() function in your main.dart with this entire block.
// ─────────────────────────────────────────────────────────────────────────────

// Decoded once at startup — no asset registration needed.
final Uint8List _kLogoBytes = base64Decode(_kLogoB64);

Widget appLogo({double size = 80}) {
  return Image.memory(
    _kLogoBytes,
    width: size,
    height: size,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) =>
        Text('🐾', style: TextStyle(fontSize: size * 0.48)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Base64-encoded logo PNG (logo_.png with white background)
// ─────────────────────────────────────────────────────────────────────────────
const String _kLogoB64 =
    'iVBORw0KGgoAAAANSUhEUgAAAfMAAAHzCAYAAAA0D/RLAAAQAElEQVR4Aey9B6AlRZU+/p2q7r73'
    'vjQ5MIDknBUlCMgAoqKYZc1hg2nXuOuqu/tfZ3+76roGFBHFAIqCOmZBlDiEmSENIFGQzACT0ws3'
    'dHdV/b/T99037715M0yAYYa5Pf11VVc4dc6pqnOqqt97Y9C+2hpoa6CtgbYG2hpoa2C71kDbmW/X'
    '3ddmvq2BtgbaGmhroK0BYOs487am2xpoa6CtgbYG2hpoa+BZ00DbmT9rqm0TbmugrYG2BtoaaGtg'
    '62jg+eTMt47G2q20NdDWQFsDbQ20NbCNaaDtzLexDmmz09ZAWwNtDbQ10NbApmqg7cw3VWPt8m0N'
    'tDXQ1kBbA20NbGMaaDvzbaxD2uy0NdDWQFsDbQ20NbCpGmg7803V2NYp326lrYG2BtoaaGugrYGN'
    '1kDbmW+0qtoF2xpoa6CtgbYG2hrYNjXQdubbZr9sHa7arbQ10NZAWwNtDTwvNNB25s+LbmwL0dZA'
    'WwNtDbQ1sCNroO3Md+Te3zqyt1tpa6CtgbYG2hp4ljXQdubPsoLb5NsaaGugrYG2BtoaeLY10Hbm'
    'z7aG2/S3jgbarbQ10NZAWwM7sAbaznwH7vy26G0NtDXQ1kBbA88PDbSd+fOjH9tSbB0NtFtpa6Ct'
    'gbYGtkkNtJ35NtktbabaGmhroK2BtgbaGth4DbSd+cbrql2yrYGto4F2K20NtDXQ1sAmaqDtzDdR'
    'Ye3ibQ20NdDWQFsDbQ1saxpoO/NtrUfa/LQ1sHU00G6lrYG2Bp5HGmg78+dRZ7ZFaWugrYG2Btoa'
    '2DE10HbmO2a/t6Vua2DraKDdSlsDbQ1sFQ20nflWUXO7kbYG2hpoa6CtgbYGnj0NtJ35s6fbNuW2'
    'Btoa2DoaaLfS1sAOr4G2M9/hh0BbAW0NtDXQ1kBbA9u7BtrOfHvvwTb/bQ20NbB1NNBupa2BbVgD'
    'bWe+DXdOm7W2BtoaaGugrYG2BjZGA21nvjFaapdpa6CtgbYGto4G2q20NbBZGmg7881SW7tSWwNt'
    'DbQ10NZAWwPbjgbaznzb6Ys2J20NtDXQ1sDW0UC7leedBtrO/HnXpW2B2hpoa6CtgbYGdjQNtJ35'
    'jtbjbXnbGmhrYB0NXHj9Zyac94f3H/WVC9/8xk9//fh/+PdzT3zPt3/9tpPO/8N7p88Ks9p2ch2N'
    'bVRCu9BW1EB7kG5FZbebamugrYGxNbBgwbnxJdd/ccLlc7804483fHF3xeW3fWnGnNvPHD9nzqxo'
    '7Fpbljp7zqzps7578imf/s6Lv3zbXX+65M5H51/y8Ko7f7jKPP6Nle6xc+5bedsvbn98/uUD3/39'
    'Of/2jZfO/N7v/n5aaDv2LVN6u/azpoG2M3/WVNsm3NZAWwNPp4FzZ79l3P9d+PLTfnXz9//zylt/'
    '8sOLF5z/yz8s+NHvL7nlh7//7dzzfvm7+T86/ze3/fbTX/rR619y7oL3x09Hb2Py1SF/+YK3HvXn'
    'e6764Zp00eyGrPyX1K4+tmFWTnZJX3fUnVako9pR9SsmNszqQ1bVFn6gFi2ffdd9N/z4f74z/zRd'
    'eGxMOxtTZtasWWb27Lck5577/jiEIBtTp11mlAbar4UG2s68UEP70dZAWwNbUwOzZ8+237jgTaf9'
    'dcXdlz82cP/PVkeLPlPrWHl6vWPlMQPJ0kOqpWWH1Msrj1ntnnydHZ9+bvHAI3+4+6rbv/XDSz+1'
    '15bwOYe7/M+ft+BtTyy758Le/MlT87h/QjX0ourXILM1oopq6EfV9yOP65CyR3m8RRZXJ9ue7JTH'
    'lt33vV/N++HHLn3grNLm8qF1L57/2f3//etH/dfAuN/86abFf7n2oezma/717CMv+dczXzLrv899'
    '+am/mfPx8W3nvrka3jHrtZ35jtnvbanbGlhHA7Nnv8VecNm7Os/8zXvHf3/2Wyae9ZN39GjaOgW3'
    'MEGd1GMDFxz/8Jp7/2+1X/WSPunvHrADUT2qSs0OgCHSpI5QzlCZHMuKxqK4EfVNls7qe269d87n'
    'Z8/51PTNYWF2mG3nP3TLK5YMPPQFV1qxV9RTl7rpR0NSOu4A6YhgKyX4yMBZbpKTCNVQw5qsn848'
    'Q81UpTwlmd7rV3z2+jmzz5h9z6xkU/n46R8/vvu8yy78t/l3/vGi/mT5Z2uV1S/vT1Yd3ZcsP7Ze'
    'Xn5af7Lk/1vUeOgn8++b963P/+i1b/zd3H/t3tQ22uWfFQ1s80Tbznyb76I2g20NPPMaUIc6+7rP'
    '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'
    'osDSxCyji7kC7A/9NHTPPbOThfNnVxYunF154IFLS4HpWnaocjuyjgaavb9O8hYmtKs/Zxq4884L'
    'JzhZ86/Ou7PjkuWxno85iaAoDFxozqcghgZo2+t+Q/YUoxVY8K72aliGpjkR5GYtHOMKzVO0iitN'
    'NSUttCRPacobtJMZQ0XOUKF1FVEUFQY5NhbJIComQoeNoaFvZFCoc1dHr7s4R+KeR50KpdFs0yPm'
    'giAiYi4KYm7WFJqHZ+NSx0Li1sqRrtb/ajWU62tmJo87p07c6Q/I4+Wg8CEDEhtxZ0gm16nkmeLp'
    'XChkIPi2ubdnRY+AEMu+9z342Dq/SnfssZ+s2ZLcJewfFh26RSyafkFrgxSGsgYja/mSoqwU6XQG'
    'EBFYa+GCN331vtc/kv5snSP+KZXdHu6MJ/zVN4K6T8rqAdUneFFmaYEnFYDSVoCMmOKNseI2fDqX'
    's60UYnMxsdvj8cceLP4TFGYVd1+DhK3UdZyQJ4Dj13OO5lxAwiqFotiYjwCDoh5JcNpA3z0TArnQ'
    'uFgzbUXvond+a86H1/m9eiUoVOKRR36gethh//DEMcf8003Hvezjv3/ZzH/60Yknf/R7M0/5+Lmn'
    'nPKpH7z85f9+wctf/p+zT5n5/11y0kn/ee3JJ/z7bTOP/bf7Zh77yQdf+sJ/euyFL/y7p15y0PsW'
    'H33IPyw54oj3LT/wwCdW9z2+aCCKHs6WLcvNZXd8uXPu3C91L1hw7uSbbvrmHnNv+s6R1177zZMu'
    'v/qrr73ssq+85eqrv/rOq6/u+lvi/Vdf3fGPV0185OPO3fKvixc/+vkH6o+eee+9D5758MN3fPHK'
    'cY988qqrvvqmuXPPPkj/WqXy38ZIDWx4tIws237bhjWgxvqmm35w2PLVK74RRfLppBxP51xHMAGc'
    '3wVGsy8io5O2u/dCNnIdiOG3MEGhaVSBBoUOivIU2ykGR78vctd9aH2tKz7A6Q49bTpurz8aneZA'
    'HlChYyjR8UVGHYxARMCmoQbZqUEeJKtNKT3FYBKUl1Z880IpHAjoXADGMXjRuIO7Nc/QxqbThfq7'
    'brpp/AZ353vOOOAWFr3VShl53SOiXCp3gCElU/AaSE/pNgEI2zVbKEQtS2ET21OTNUfMDiN3yXPm'
    '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'
    'LO/vhd4HJ1DeIN4cgcsPy8HVgBkqavEGjk5vzgnrDy7Vc3ooK5bDM60GHTTIfIu0AzO1QMMC2OHQ'
    '6xhm5K88EGhcf4Le0xEAGwvxscYg42mR/iCbYR1wx13n7lN34jcvuhc/PuV3+NnpJ+L488/AJXcs'
    'wGNpP7KuEvK2CA0a9qbkaBH5lJCJ5xhPBNIdxI6GBoPz4xxZtUizOg0P1ghaR8vBJyOew3fpGmZc'
    'NwWKB4aB3UKhcI6EMx0Cz7ZeAGdEbIyu3CSfuuqq8Vux27W+06fPzDbfcNs/h656qWtwBuSRcjmG'
    '050taYnQcNOcIO4I4KImJmxaxY13zcFZl56GRYvvRFBOkbsEgS0jFu6wGxWU3VhUMQlRNoEwDmE+'
    'Brr7LqETZanCNiP4/hAVGYspm+2NV+32Bmy54T5A2gXjYtLIrAYAAsB4V4AwFDiWExhapi31ioKh'
    'EU+aNZZlhf7JUodarYXMBYgq7QirVfRndclKmTFj3Rb1Svdn71p53axzrvv7aWddfeof586f9cs/'
    'zf3O96967PPfOPOWE7/xp6u++/15F5/4/XmXnPiDf95y4o/nXXfcT/9xy0k/uvCeHzN9wo/nXPPT'
    'n82+9qfHnX/lH487/abjf3fudX8++bz5p596/s2n/+WyW06fNfuuc/82/75L/3bNI1eecevi+Wfc'
    'tfz603tLi07pCx89sTd67A890aO/7Csv+mZfZfH/9FcXf7FeWfrNOxde/8ur7pi3J6e83r9mfZ9B'
    'b23JtmJxkLXGuDTzeeb+EdrSt3f+F/i1A++9NJv1LQHflucp1JiLSFwAhwcAABAASURBVLFkIoOh'
    'DQNkFLDce4qax8qBPlx4xWVY0RiAVKgkQlanklAlLYWYgkd7Obzz0DyW/lu/pALnb6CKmxGAdIRn'
    'rACBFwsSCtWwjCDxqCZmbu1NbctZY9X7s7O/tNGdj977lb68voHnPTACC5ckEAcMGw21h07YPV7o'
    'h51yLXPyQG+tHytqfajTCDa4ayyMLIt1RDVgatA1qVNTQ65Gq04j0pc0sby3G5nLIcIaBBGG2nAk'
    'sKEqDAWdj2ckobGGEQiNEJgWYZz1PI16zt16GIZQ0PFy8qHnvW9/lqC31UReDvFQ7zJcd9/tOO2C'
    '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'
    '16mlJGlMgn/u/b2dThs3bnw0R633RYtermYr1L61CNKWutlSdvvHrXP0sNlGG73VXMjPUtx5V7or'
    'ULk5CvsQVUqhiyfBgS0taAnzVk+PHlh3keX23G/3X1y+7xr7xn1A+ZVpMm6NX3Zst/7mp1Sml2Z6'
    '1oPhm19cTWG0geeBp3MLLZF+zrhGo900IESZNzmK/AZF3BWLpsZWBAhRTEPXmOSrbnL1tZZqeP46'
    'I1ba+Xc/PnKn32966rHX/urua8fv8ff3/W6jn8P5yjZ/5JEz/dtO3W/T5/5757m1jjfOafA69/aS'
    'qauFtmOpRr+6Vlf7m79/6IGb9pJ6fSGC6KAnuVG4+aSdt37q3usunvLK4xd5panHNavu3VpQ2ixI'
    'un/UNfnV37529cnNfcH/wTbjtj3p7cWHL/frWlfyZFKJ3ZC2AXj1tRcxs3MqYlUFfIdyVOHVc4yE'
    'V+SW1+uQKx4VUydG5N8a4qQMLw94RQUXpOiKutBV7cxO57lcgc+SFqOGL0Fd5sOjXm0bUsBrU5/A'
    'xdeeglPO/RX+fslvcc6EE3HBVX/BhBvPwPV3nYu7H78cT752K96c9TCmVp9D4s+CX0igAiCGZd86'
    'm0qSVNl/Be9dnaJvTimFxFnOLAVxBe2d7S34glx9Zl9Q51+Vbo+99sBhtz848fAaoiG1qAxnI5Br'
    '4PkAN55ISWVLLel6JswbGXDh0eucVO5NsJ6ihTcw8Hm1OcArIuyObt9hwy2POXzzT/63sY35Qjd1'
    'vdNyyopSCoWC0twKv4e7f5FFFxnxmoaelCYJ5+jg6wDOcfQ98EnYP6qeswq5YgHtUzqq+ZJ35c++'
    't9cPb//jE9d/3Q15Lx2/tf93/ze82PYPVbaVJEqybOdpgIvMDyw3eqqXqbLSeftYVrdUcmVRtD4g'
    '62HIsC3FJpTenIVcp2svdqurly2OOPTAbXff+JXzp+5510lPXMUT8eRx4xa+R5N8c+Ufv+I3y797'
    '+22HzJr6zMW+m/4dlUxpRTTZFMIyAq8KT0VoCNVwZSu/efH2mzdybjwXea5QZ5X+d8nRo284Yded'
    'nr//zgvLk9+8tKiSTZtzenBeJznEJd2YM/Bs4hcDb70XXn1ixazRfPj8ZMcLHi56g482ae4tAx+v'
    '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'
    'OUc/+/BJP/vDs4e13fOPXbe76pMthlwyeciQo6pDc1P5nDRE87bO4RLIyXwOv4F587+/EhAybGu7'
    'pLr71ldP2XurX43dZ7ubPxm1/S3vj9rxtr/uu8Otz4/a5s5nDt3m/j8evcPvfn/CTx8efcJOj9x1'
    '4k6P3X7yLmNu/cXI52+89KDXr7vqiLeuveqIf1x78YF/vbZ992euO3Gnx284eefHbjpxx0d+dfSO'
    'v7/7kLb77j+o7b4HD97hnkcObrvnmUN2vPuvh253z+uH7HD3Owduf9e/9tv2znF77XDrpBHDbu8a'
    'Nfy6Snt7e/ba2/dX6nnPcgl8BxKYCVXkZD4ThJoXmUsgl0AugVwCuQS+SwnkZP5dSjuvK5dALoFc'
    'ArkEcgnMBAl8BZnPhFryInMJ5BLIJZBLIJdALoGZJoGczGeaaPOCcwnkEsglkEsgl8B3I4FZRubf'
    'TffyWnIJ5BLIJZBLIJfA918COZl//+9x3sNcArkEcgnkEvieS+B7Tubf87uXdy+XQC6BXAK5BHIJ'
    'UAI5mVMI+ZlLIJdALoFcArkE5mQJ5GQ+A+5eXkQugVwCuQRyCeQSmJUSyMl8Vko/rzuXQC6BXAK5'
    'BHIJzAAJ5GQ+A4T43RSR15JLIJdALoFcArkEvloCOZl/tVzy0FwCuQRyCeQSyCUwx0ggJ/M55lZ9'
    'Nw3Na8klkEsgl0AugTlPAjmZz3n3LG9xLoFcArkEcgnkEviSBHIy/5I48ovvRgJ5LbkEcgnkEsgl'
    'MCMlkJP5jJRmXlYugVwCuQRyCeQSmAUSyMl8Fgg9r/K7kUBeSy6BXAK5BOYWCeRkPrfc6byfuQRy'
    'CeQSyCXwvZXA/wMAAP//QUtCYwAAAAZJREFUAwBJSRXR6VTOwAAAAABJRU5ErkJggg==';

Widget fld(TextEditingController c, String lbl, IconData icon, bool d, {
  TextInputType? kb, bool obs = false, Widget? suf,
  String? Function(String?)? v, int lines = 1,
}) {
  return TextFormField(
    controller: c, obscureText: obs, keyboardType: kb,
    validator: v, maxLines: lines,
    style: TextStyle(color: AC.mt(d), fontSize: 15),
    decoration: InputDecoration(
      labelText: lbl, labelStyle: TextStyle(color: AC.lt(d), fontSize: 14),
      prefixIcon: Icon(icon, color: AC.lt(d), size: 20), suffixIcon: suf,
      filled: true, fillColor: AC.cream(d),
      border:             OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AC.blush(d), width: 1.5)),
      focusedBorder:      OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AC.peach(d), width: 2)),
      errorBorder:        OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

Widget slbl(String t, bool d) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: Text(
    t.toUpperCase(),
    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AC.lt(d), letterSpacing: 2),
  ),
);

Widget stile(IconData icon, String lbl, Color col, bool d, VoidCallback t) {
  return GestureDetector(
    onTap: t,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Icon(icon, color: AC.sb(d), size: 22),
        const SizedBox(width: 14),
        Text(lbl, style: TextStyle(fontSize: 15, color: AC.sb(d), fontWeight: FontWeight.w500)),
        const Spacer(),
        Icon(Icons.arrow_forward_ios_rounded, color: AC.lt(d), size: 14),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PEACH BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class PBtn extends StatefulWidget {
  final String    label;
  final VoidCallback onTap;
  final bool      loading;
  const PBtn({super.key, required this.label, required this.onTap, this.loading = false});
  @override State<PBtn> createState() => _PBtnS();
}

class _PBtnS extends State<PBtn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _s = Tween(begin: 1.0, end: .95).animate(_c);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) {
    final d = dark(ctx);
    return GestureDetector(
      onTapDown:   (_) => _c.forward(),
      onTapUp:     (_) { _c.reverse(); if (!widget.loading) widget.onTap(); },
      onTapCancel: ()  => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          width: double.infinity, height: 54,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AC.peach(d), d ? const Color(0xFFE8644A) : const Color(0xFFFF8F7A),
            ]),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AC.peach(d).withOpacity(0.4), blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Center(
            child: widget.loading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// USER AVATAR
// ─────────────────────────────────────────────────────────────────────────────
class UAv extends StatelessWidget {
  final AppUser? u;
  final double   sz, fs;
  const UAv({super.key, required this.u, this.sz = 44, this.fs = 18});

  @override
  Widget build(BuildContext ctx) {
    final d = dark(ctx);
    if (u?.avBytes != null) {
      return SizedBox(
        width: sz, height: sz,
        child: ClipOval(
          child: Image.memory(
            u!.avBytes!, fit: BoxFit.cover, width: sz, height: sz,
            key: ValueKey(u!.avBytes!.length),
            errorBuilder: (_, __, ___) => _sh(d, _initials(d)),
          ),
        ),
      );
    }
    if (u?.avEmoji != null) {
      return _sh(d, Text(u!.avEmoji!, style: TextStyle(fontSize: fs + 4)));
    }
    return _sh(d, _initials(d));
  }

  Widget _initials(bool d) => Text(
    u != null ? u!.username[0].toUpperCase() : '👤',
    style: TextStyle(color: Colors.white, fontSize: fs, fontWeight: FontWeight.bold),
  );

  Widget _sh(bool d, Widget ch) => Container(
    width: sz, height: sz,
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [AC.peach(d), AC.sage(d)]),
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: AC.peach(d).withOpacity(0.3), blurRadius: 8)],
    ),
    child: Center(child: ch),
  );
}
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashS();
}

class _SplashS extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fa, _sc;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fa = CurvedAnimation(parent: _c, curve: Curves.easeIn);
    _sc = Tween(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.elasticOut));
    _c.forward();
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (!mounted) return;
      if (curUser == null || !curUser!.agreedTerms) {
        Navigator.pushReplacementNamed(context, '/terms');
      } else if (curUser!.firstTime) {
        Navigator.pushReplacementNamed(context, '/onboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) {
    final d = dark(ctx);
    return Scaffold(
      body: Container(
        decoration: gbg(d),
        child: Center(
          child: FadeTransition(
            opacity: _fa,
            child: ScaleTransition(
              scale: _sc,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  appLogo(size: 130),
                  const SizedBox(height: 20),
                  Text(
                    'ALAG-AP',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AC.sb(d),
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Every stray deserves a way home.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AC.peach(d),
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AC.peach(d),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// TERMS SCREEN  ← LOGO ADDED
// ─────────────────────────────────────────────────────────────────────────────
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});
  @override State<TermsScreen> createState() => _TermsS();
}

class _TermsS extends State<TermsScreen> {
  bool _ok = false;

  @override
  Widget build(BuildContext ctx) {
    final d = dark(ctx);
    return Scaffold(
      body: Container(
        decoration: gbg(d),
        child: SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(children: [
              // ── LOGO ──────────────────────────────────────────────────────
              appLogo(size: 72),
              const SizedBox(height: 10),
              Container(
                width: 54, height: 54,
                decoration: BoxDecoration(color: AC.card(d), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AC.peach(d).withOpacity(0.3), blurRadius: 16, spreadRadius: 2)]),
                child: const Center(child: Text('📋', style: TextStyle(fontSize: 28))),
              ),
              const SizedBox(height: 12),
              Text('Terms & Privacy', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AC.sb(d), letterSpacing: 1)),
              const SizedBox(height: 6),
              Text('Please read before continuing', style: TextStyle(fontSize: 13, color: AC.lt(d), fontStyle: FontStyle.italic)),
            ]),
          ),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              const SizedBox(height: 8),
              _ts('1. Acceptance',       'By using ALAG-AP you agree to these terms. ALAG-AP connects animal rescuers with shelters, vets, and welfare organizations in the Philippines.', d),
              _ts('2. Responsibilities', 'Provide accurate info when reporting animals. Misuse may result in suspension.', d),
              _ts('3. Privacy & Data',   'ALAG-AP collects name, email, and location (when reporting) only to facilitate rescue. Data is stored locally and not shared without consent.', d),
              _ts('4. Location',         'Location is requested only in the Report feature and is not stored permanently.', d),
              _ts('5. Photos',           'Photos remain yours. By submitting, you grant ALAG-AP permission to share with orgs for rescue purposes.', d),
              _ts('6. Animal Welfare',   'Report animals in distress immediately and follow proper adoption procedures.', d),
              _ts('7. Disclaimer',       'ALAG-AP is community-driven. We do not guarantee response time of listed organizations. For emergencies, contact your local barangay or city vet directly.', d),
              _ts('8. Contact',          'Concerns: alagap.philippines@gmail.com. Continuing means you have read and agreed.', d),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _ok = !_ok),
                child: Row(children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: _ok ? AC.peach(d) : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _ok ? AC.peach(d) : AC.lt(d), width: 2),
                    ),
                    child: _ok ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(
                    'I have read and agree to the Terms & Privacy Policy',
                    style: TextStyle(fontSize: 13, color: AC.mt(d), height: 1.4),
                  )),
                ]),
              ),
              const SizedBox(height: 20),
              PBtn(
                label: 'Continue →',
                onTap: _ok
                    ? () async {
                        if (curUser != null) {
                          curUser!.agreedTerms = true;
                          await St.save();
                          if (mounted) {
                            Navigator.pushReplacementNamed(context, curUser!.firstTime ? '/onboard' : '/home');
                          }
                        } else {
                          if (mounted) Navigator.pushReplacementNamed(context, '/auth');
                        }
                      }
                    : () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please agree to continue')),
                        ),
              ),
              const SizedBox(height: 24),
            ]),
          )),
        ])),
      ),
    );
  }

  Widget _ts(String title, String body, bool d) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AC.card(d).withOpacity(0.7), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AC.sb(d))),
        const SizedBox(height: 6),
        Text(body,  style: TextStyle(fontSize: 12, color: AC.mt(d), height: 1.6)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ONBOARD SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});
  @override State<OnboardScreen> createState() => _OnbS();
}

class _OnbS extends State<OnboardScreen> {
  final _pc    = PageController();
  int    _pg   = 0;
  final  _nc   = TextEditingController();
  final  _bc   = TextEditingController();
  String?    _selEmoji;
  Uint8List? _avBytes;
  UserRole   _role = UserRole.both;
  final _picker = ImagePicker();

  @override void dispose() { _pc.dispose(); _nc.dispose(); _bc.dispose(); super.dispose(); }

  Future<void> _pick() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 400, maxHeight: 400);
    if (x == null) return;
    final raw = await x.readAsBytes();
    final cap = raw.length > 150 * 1024 ? Uint8List.fromList(raw.sublist(0, 150 * 1024)) : raw;
    setState(() { _avBytes = cap; _selEmoji = null; });
  }

  Future<void> _done() async {
    if (curUser == null) return;
    if (_nc.text.trim().isNotEmpty) {
      curUser!.displayName = _nc.text.trim();
      curUser!.username    = _nc.text.trim();
    }
    curUser!.bio         = _bc.text.trim().isEmpty ? null : _bc.text.trim();
    curUser!.role        = _role;
    curUser!.firstTime   = false;
    curUser!.avEmoji     = _selEmoji;
    curUser!.avBytes     = _avBytes;
    await St.save();
    St._seedFriends();
    if (mounted) Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext ctx) {
    final d  = dark(ctx);
    final sb = AC.sb(d);
    return Scaffold(
      body: Container(
        decoration: gbg(d),
        child: SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(children: [
              Text('Setup Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: sb)),
              const Spacer(),
              ...List.generate(2, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(left: 6),
                width: _pg == i ? 24 : 8, height: 8,
                decoration: BoxDecoration(
                  color: _pg == i ? AC.peach(d) : AC.blush(d),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ]),
          ),
          Expanded(child: PageView(
            controller: _pc,
            physics: const NeverScrollableScrollPhysics(),
            children: [_page1(d, sb), _page2(d, sb)],
          )),
        ])),
      ),
    );
  }

  Widget _page1(bool d, Color sb) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        GestureDetector(
          onTap: _pick,
          child: Stack(alignment: Alignment.bottomRight, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AC.peach(d), AC.sage(d)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AC.peach(d).withOpacity(0.3), blurRadius: 16)],
              ),
              child: Center(child: _avBytes != null
                  ? ClipOval(child: Image.memory(_avBytes!, fit: BoxFit.cover, width: 100, height: 100))
                  : _selEmoji != null
                      ? Text(_selEmoji!, style: const TextStyle(fontSize: 44))
                      : Text(curUser?.username[0].toUpperCase() ?? '?',
                             style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold))),
            ),
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(color: AC.peach(d), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 2),
            itemCount: kAvatars.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final e   = kAvatars[i];
              final sel = _selEmoji == e && _avBytes == null;
              return GestureDetector(
                onTap: () => setState(() { _selEmoji = e; _avBytes = null; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: sel ? AC.peach(d).withOpacity(0.3) : AC.cream(d),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? AC.peach(d) : Colors.transparent, width: 2),
                  ),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        fld(_nc, 'Display Name', Icons.person_outline_rounded, d),
        const SizedBox(height: 14),
        fld(_bc, 'Bio (optional)', Icons.edit_outlined, d, lines: 3),
        const SizedBox(height: 28),
        PBtn(
          label: 'Next →',
          onTap: () {
            if (_nc.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a display name')));
              return;
            }
            setState(() => _pg = 1);
            _pc.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          },
        ),
      ]),
    );
  }

  Widget _page2(bool d, Color sb) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 8),
        Text('What is your role?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: sb)),
        const SizedBox(height: 6),
        Text('You can change this in Settings', style: TextStyle(fontSize: 13, color: AC.lt(d), fontStyle: FontStyle.italic)),
        const SizedBox(height: 24),
        ...UserRole.values.map((r) {
          return GestureDetector(
            onTap: () => setState(() => _role = r),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _role == r ? AC.peach(d).withOpacity(0.15) : AC.card(d),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _role == r ? AC.peach(d) : AC.blush(d), width: _role == r ? 2 : 1.5),
              ),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: _role == r ? AC.peach(d) : AC.blush(d).withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(r.icon, color: _role == r ? Colors.white : sb, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sb)),
                  const SizedBox(height: 4),
                  Text(r.desc, style: TextStyle(fontSize: 12, color: AC.mt(d), height: 1.4)),
                ])),
                if (_role == r) Icon(Icons.check_circle, color: AC.peach(d), size: 22),
              ]),
            ),
          );
        }),
        const SizedBox(height: 8),
        PBtn(label: "Let's Go! 🐾", onTap: _done),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTH SCREEN  ← LOGO ALREADY PRESENT (kept + slogan)
// ─────────────────────────────────────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override State<AuthScreen> createState() => _AuthS();
}

class _AuthS extends State<AuthScreen> with TickerProviderStateMixin {
  bool _login = true, _obs = true, _loading = false;
  final _fk = GlobalKey<FormState>();
  final _un = TextEditingController();
  final _em = TextEditingController();
  final _pw = TextEditingController();
  late AnimationController _fc;
  late Animation<double>   _fa;

  @override void initState() {
    super.initState();
    _fc = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fa = CurvedAnimation(parent: _fc, curve: Curves.easeIn);
    _fc.forward();
  }
  @override void dispose() { _fc.dispose(); _un.dispose(); _em.dispose(); _pw.dispose(); super.dispose(); }

  void _tog() { _fc.reset(); setState(() => _login = !_login); _fc.forward(); }

  Future<void> _sub() async {
    if (!_fk.currentState!.validate()) return;
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    curUser = AppUser(
      username:    _login ? _em.text.split('@').first : _un.text.trim(),
      email:       _em.text.trim(),
      firstTime:   true,
      agreedTerms: true,
    );
    await St.save();
    if (mounted) Navigator.pushReplacementNamed(context, '/onboard');
  }

  @override
  Widget build(BuildContext ctx) {
    final d  = dark(ctx);
    final sb = AC.sb(d);
    final lt = AC.lt(d);
    final mt = AC.mt(d);
    return Scaffold(
      body: Container(
        decoration: gbg(d),
        child: SafeArea(child: FadeTransition(
          opacity: _fa,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(children: [
              // ── LOGO ──────────────────────────────────────────────────────
              appLogo(size: 96),
              const SizedBox(height: 16),
              Text('ALAG-AP',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: sb, letterSpacing: 4)),
              const SizedBox(height: 4),
              Text(
                'Every stray deserves a way home.',
                style: TextStyle(
                  fontSize: 13,
                  color: AC.peach(d),
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(_login ? 'Welcome back!' : 'Create your account',
                   style: TextStyle(fontSize: 13, color: lt, fontStyle: FontStyle.italic)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AC.card(d).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [BoxShadow(color: AC.blush(d).withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8))],
                ),
                child: Form(
                  key: _fk,
                  child: Column(children: [
                    if (!_login) ...[
                      fld(_un, 'Username', Icons.person_outline_rounded, d,
                          v: (v) => (v == null || v.trim().isEmpty) ? 'Enter username' : null),
                      const SizedBox(height: 16),
                    ],
                    fld(_em, 'Email', Icons.email_outlined, d,
                        kb: TextInputType.emailAddress,
                        v: (v) {
                          if (v == null || v.isEmpty) return 'Enter email';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        }),
                    const SizedBox(height: 16),
                    fld(_pw, 'Password', Icons.lock_outline_rounded, d,
                        obs: _obs,
                        suf: IconButton(
                          icon: Icon(_obs ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: lt, size: 20),
                          onPressed: () => setState(() => _obs = !_obs),
                        ),
                        v: (v) {
                          if (v == null || v.isEmpty) return 'Enter password';
                          if (v.length < 6) return 'Min 6 chars';
                          return null;
                        }),
                    const SizedBox(height: 28),
                    PBtn(label: _login ? 'Log In' : 'Create Account', loading: _loading, onTap: _sub),
                  ]),
                ),
              ),
              const SizedBox(height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_login ? "Don't have an account? " : 'Already have an account? ',
                     style: TextStyle(fontSize: 13, color: mt)),
                GestureDetector(
                  onTap: _tog,
                  child: Text(_login ? 'Sign Up' : 'Log In',
                               style: TextStyle(fontSize: 13, color: AC.peach(d), fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  curUser = AppUser(username: 'Guest', email: 'guest@alagap.app', firstTime: true, agreedTerms: true);
                  await St.save();
                  if (mounted) Navigator.pushReplacementNamed(context, '/onboard');
                },
                child: Text('Skip for now →',
                            style: TextStyle(fontSize: 12, color: lt, decoration: TextDecoration.underline)),
              ),
            ]),
          ),
        )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BONUS DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class BonusDlg extends StatefulWidget {
  final int coins, streak, total;
  const BonusDlg({super.key, required this.coins, required this.streak, required this.total});
  @override State<BonusDlg> createState() => _BonusDlgS();
}

class _BonusDlgS extends State<BonusDlg> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _sc, _fa;
  @override void initState() {
    super.initState();
    _c  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _sc = Tween(begin: .5, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.elasticOut));
    _fa = Tween(begin: .0, end: 1.0).animate(_c);
    _c.forward();
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) {
    final d  = dark(ctx);
    final sb = AC.sb(d);
    final lt = AC.lt(d);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(opacity: _fa, child: ScaleTransition(scale: _sc,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AC.cream(d), AC.blush(d).withOpacity(0.5)]),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: AC.peach(d).withOpacity(0.3), blurRadius: 24, spreadRadius: 4)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text('Daily Bonus!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: sb)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AC.streak.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AC.streak.withOpacity(0.4), width: 1.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text('${widget.streak} Day Streak!',
                     style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AC.streak)),
              ]),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AC.gold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AC.gold.withOpacity(0.4), width: 2),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('🪙', style: TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('+${widget.coins} Coin${widget.coins > 1 ? 's' : ''}',
                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: sb)),
                  Text('Total: ${widget.total} coins', style: TextStyle(fontSize: 11, color: lt)),
                ]),
              ]),
            ),
            const SizedBox(height: 8),
            Text('Day ${widget.streak} → ${math.min(widget.streak + 1, 7)} coins tomorrow',
                 style: TextStyle(fontSize: 11, color: lt, fontStyle: FontStyle.italic)),
            const SizedBox(height: 20),
            PBtn(label: 'Awesome! 🐾', onTap: () => Navigator.pop(ctx)),
          ]),
        ),
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COIN CALENDAR
// ─────────────────────────────────────────────────────────────────────────────
class CoinCal extends StatelessWidget {
  final AppUser? u;
  final bool     d;
  const CoinCal({super.key, required this.u, required this.d});

  @override
  Widget build(BuildContext ctx) {
    final now    = DateTime.now();
    final months = ['January','February','March','April','May','June',
                    'July','August','September','October','November','December'];
    final mn     = months[now.month - 1];
    final dim    = DateUtils.getDaysInMonth(now.year, now.month);
    final fw     = DateTime(now.year, now.month, 1).weekday % 7;
    final logged = u?.loggedDays ?? {};
    final mc     = u?.monthCoins ?? 0;
    final sk     = u?.streak ?? 0;
    final sb     = AC.sb(d);
    final lt     = AC.lt(d);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AC.gold.withOpacity(0.1), AC.blush(d).withOpacity(0.15)]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AC.gold.withOpacity(0.3), width: 1.5),
      ),
      child: Column(children: [
        Row(children: [
          Text('$mn ${now.year}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: sb)),
          const Spacer(),
          const Text('🪙', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text('$mc/100 coins', style: TextStyle(fontSize: 12, color: lt, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: mc / 100, minHeight: 5,
            backgroundColor: AC.blush(d).withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(AC.gold),
          ),
        ),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Streak: $sk day${sk != 1 ? 's' : ''} 🔥',
               style: TextStyle(fontSize: 11, color: AC.streak, fontWeight: FontWeight.bold)),
          Text('Next: +${math.min(sk + 1, 7)} 🪙', style: TextStyle(fontSize: 11, color: lt)),
        ]),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S','M','T','W','T','F','S'].map((x) => SizedBox(
            width: 26,
            child: Text(x, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: lt)),
          )).toList(),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, mainAxisSpacing: 3, crossAxisSpacing: 3, childAspectRatio: 1,
          ),
          itemCount: fw + dim,
          itemBuilder: (_, i) {
            if (i < fw) return const SizedBox.shrink();
            final day = i - fw + 1;
            final isL = logged.contains(day);
            final isT = day == now.day;
            final ky  = '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            final cv  = u?.coinLog[ky] ?? 0;
            return Container(
              decoration: BoxDecoration(
                color: isL ? AC.gold.withOpacity(0.8) : isT ? AC.peach(d).withOpacity(0.35) : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: isT ? Border.all(color: AC.peach(d), width: 1.5) : null,
              ),
              child: Center(child: isL && cv > 0
                  ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('$day', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('+$cv', style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold)),
                    ])
                  : Text('$day', style: TextStyle(
                      fontSize: 9,
                      fontWeight: isT ? FontWeight.bold : FontWeight.normal,
                      color: isL ? Colors.white : sb,
                    ))),
            );
          },
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME SCREEN  ← LOGO ADDED TO HEADER
// ─────────────────────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override State<HomeScreen> createState() => _HomeS();
}

class _HomeS extends State<HomeScreen> with SingleTickerProviderStateMixin {
  File?      _f;
  Uint8List? _b;
  String?    _wu;
  final _picker = ImagePicker();
  late AnimationController _fc;
  late Animation<double>   _fa;

  bool     get _has => _f != null || _b != null || _wu != null;
  ImageArg get _arg => ImageArg(file: _f, bytes: _b, webUrl: _wu);

  @override void initState() {
    super.initState();
    _fc = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fa = CurvedAnimation(parent: _fc, curve: Curves.easeIn);
    _fc.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final (g, c, s) = await St.bonus();
      if (g && mounted) {
        showDialog(context: context, builder: (_) => BonusDlg(coins: c, streak: s, total: curUser?.coins ?? c));
        setState(() {});
      }
    });
  }
  @override void dispose() { _fc.dispose(); super.dispose(); }
  
  Future<void> _photo(ImageSource src) async {
      await ScreenSecurity.enableSecureMode();
      try {
        final x = await _picker.pickImage(
          source: src,
          imageQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
        );
       await ScreenSecurity.disableSecureMode();
       if (x == null) return;
       if (kIsWeb) {
         setState(() { _wu = x.path; _b = null; _f = null; });
       } else {
         setState(() { _f = File(x.path); _b = null; _wu = null; });
       }
    } catch (e) {
      await ScreenSecurity.disableSecureMode();
      debugPrint('Image pick error: $e');
    }
  }



  void _clear() => setState(() { _f = null; _b = null; _wu = null; });

  @override
  Widget build(BuildContext ctx) {
    final d    = dark(ctx);
    final sb   = AC.sb(d);
    final lt   = AC.lt(d);
    final role = curUser?.role ?? UserRole.both;
    return Scaffold(
      body: Container(
        decoration: gbg(d),
        child: FadeTransition(opacity: _fa, child: SafeArea(child: Column(children: [
          // ── HEADER WITH LOGO ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // App logo — small version beside the title
              appLogo(size: 38),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('ALAG-AP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: sb, letterSpacing: 3)),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AC.peach(d).withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: Text(role.label, style: TextStyle(fontSize: 10, color: AC.peach(d), fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  Text('• Rescue • Adopt', style: TextStyle(fontSize: 11, color: lt)),
                ]),
              ]),
              const Spacer(),
              if (curUser != null) Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AC.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AC.gold.withOpacity(0.4), width: 1.5),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🪙', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 3),
                  Text('${curUser!.coins}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sb)),
                  if (curUser!.streak > 0) ...[
                    const SizedBox(width: 5),
                    const Text('🔥', style: TextStyle(fontSize: 12)),
                    Text('${curUser!.streak}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AC.streak)),
                  ],
                ]),
              ),
              IconButton(
                icon: Icon(Icons.people_outline_rounded, color: sb, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => Navigator.pushNamed(ctx, '/friends').then((_) => setState(() {})),
              ),
              IconButton(
                icon: Icon(Icons.settings_outlined, color: sb, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                onPressed: () => Navigator.pushNamed(ctx, '/settings').then((_) => setState(() {})),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => Navigator.pushNamed(ctx, '/profile').then((_) => setState(() {})),
                child: UAv(
                  key: ValueKey('${curUser?.avBytes?.length ?? 0}_${curUser?.avEmoji ?? ""}'),
                  u: curUser, sz: 40, fs: 16,
                ),
              ),
            ]),
          ),
          // Role banner for receivers
          if (role == UserRole.receiver)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AC.sky(d).withOpacity(0.3), borderRadius: BorderRadius.circular(14)),
                child: Row(children: [
                  const Text('📥', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    '${curUser?.friends.length ?? 0} connections ready to receive reports.',
                    style: TextStyle(fontSize: 12, color: AC.mt(d)),
                  )),
                ]),
              ),
            ),
          // Body
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              const SizedBox(height: 8),
              _photoArea(d, sb, lt),
              const SizedBox(height: 20),
              if (_has) _actions(d) else _hints(d, role),
              const SizedBox(height: 32),
            ]),
          )),
        ]))),
      ),
    );
  }

  Widget _photoArea(bool d, Color sb, Color lt) {
    return GestureDetector(
      onTap: !_has ? () => _photo(ImageSource.camera) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: _has ? 280 : 240,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AC.card(d),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _has ? AC.sage(d) : AC.peach(d).withOpacity(0.4), width: 2),
          boxShadow: [BoxShadow(color: AC.blush(d).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: _has
              ? Stack(fit: StackFit.expand, children: [
                  bImg(_arg),
                  Positioned(
                    top: 12, right: 12,
                    child: GestureDetector(
                      onTap: _clear,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 18, color: Colors.black54),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12, left: 12,
                    child: GestureDetector(
                      onTap: () {
                        if (curUser == null) return;
                        curUser!.bookmarks.insert(0, BItem(
                          id:       '${DateTime.now().millisecondsSinceEpoch}',
                          title:    'Animal Photo',
                          subtitle: DateTime.now().toString().substring(0, 16),
                          emoji:    '📸',
                          at:       DateTime.now(),
                        ));
                        St.save();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bookmarked! 📌'), behavior: SnackBarBehavior.floating),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.85), shape: BoxShape.circle),
                        child: const Icon(Icons.bookmark_border_rounded, size: 18, color: Colors.black54),
                      ),
                    ),
                  ),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(color: AC.blush(d).withOpacity(0.5), shape: BoxShape.circle),
                    child: Icon(Icons.camera_alt_rounded, size: 34, color: AC.peach(d)),
                  ),
                  const SizedBox(height: 14),
                  Text('Take a Photo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sb)),
                  const SizedBox(height: 6),
                  Text('Tap to photograph an animal', style: TextStyle(fontSize: 12, color: lt)),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => _photo(ImageSource.gallery),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(color: AC.sage(d).withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                      child: Text('or choose from gallery', style: TextStyle(fontSize: 12, color: AC.mt(d))),
                    ),
                  ),
                ]),
        ),
      ),
    );
  }


  Widget _actions(bool d) {
    return Column(children: [
      Text('What would you like to do?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AC.mt(d))),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _AC(
          emoji: '🏠', label: 'Adopt', sub: 'Start the process', color: AC.sage(d),
          onTap: () async {
            curUser?.adoptions++;
            await St.save();
            if (mounted) Navigator.pushNamed(context, '/adopt', arguments: _arg);
          },
        )),
        const SizedBox(width: 12),
        Expanded(child: _AC(
          emoji: '📍', label: 'Report', sub: 'Find nearby help', color: AC.sky(d),
          onTap: () async {
            curUser?.reports++;
            await St.save();
            if (mounted) Navigator.pushNamed(context, '/report', arguments: _arg);
          },
        )),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _AC(
          emoji: '🔖', label: 'Bookmarks', sub: 'Saved items', color: AC.lav(d),
          onTap: () => Navigator.pushNamed(context, '/bookmarks').then((_) => setState(() {})),
        )),
        const SizedBox(width: 12),
        Expanded(child: _AC(
          emoji: '💬', label: 'Friends', sub: 'Chat & connect', color: AC.blush(d),
          onTap: () => Navigator.pushNamed(context, '/friends').then((_) => setState(() {})),
        )),
      ]),
    ]);
  }

  Widget _hints(bool d, UserRole role) {
    return Column(children: [
      if (role == UserRole.sender || role == UserRole.both) ...[
        _HC(emoji: '📍', title: 'Report a Stray',    desc: 'Find nearby shelters and send them a photo.', color: AC.sky(d).withOpacity(0.3), d: d),
        const SizedBox(height: 10),
      ],
      if (role == UserRole.receiver || role == UserRole.both) ...[
        _HC(emoji: '📥', title: 'Receive Reports',   desc: 'Connect with senders and help animals.', color: AC.lav(d).withOpacity(0.3), d: d),
        const SizedBox(height: 10),
      ],
      _HC(emoji: '🏠', title: 'Adopt an Animal',   desc: 'Learn legal steps and vet care.', color: AC.sage(d).withOpacity(0.3), d: d),
      const SizedBox(height: 10),
      _HC(emoji: '💬', title: 'Friends & Chat',    desc: 'Connect with shelters and rescuers.', color: AC.blush(d).withOpacity(0.3), d: d),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FRIENDS & CHAT
// ─────────────────────────────────────────────────────────────────────────────
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override State<FriendsScreen> createState() => _FriendsS();
}

class _FriendsS extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _sc = TextEditingController();
  String _q = '';

  @override void initState() { super.initState(); _tab = TabController(length: 2, vsync: this); }
  @override void dispose()   { _tab.dispose(); _sc.dispose(); super.dispose(); }

  List<MUser> get _sugg => kMock.where((u) =>
    _q.length > 1 &&
    u.username.toLowerCase().contains(_q.toLowerCase()) &&
    !(curUser?.friends.any((f) => f.user.id == u.id) ?? false)
  ).toList();

  void _add(MUser u) {
    if (curUser == null) return;
    curUser!.friends.add(Friend(user: u));
    St.save();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${u.username} added!'), behavior: SnackBarBehavior.floating),
    );
  }

  String _tl(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24)   return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext ctx) {
    final d  = dark(ctx);
    final sb = AC.sb(d);
    final lt = AC.lt(d);
    final fr = curUser?.friends ?? [];
    return Scaffold(
      body: Container(
        decoration: gbg(d),
        child: SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.arrow_back_ios_new_rounded), color: sb),
              Text('Friends & Chat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: sb)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: TextField(
              controller: _sc,
              onChanged: (v) => setState(() => _q = v),
              style: TextStyle(color: AC.mt(d), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search users to add...',
                hintStyle: TextStyle(color: lt, fontSize: 13),
                prefixIcon: Icon(Icons.person_search_rounded, color: lt, size: 20),
                filled: true, fillColor: AC.card(d),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          if (_sugg.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                scrollDirection: Axis.horizontal,
                itemCount: _sugg.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final u = _sugg[i];
                  return GestureDetector(
                    onTap: () => _add(u),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AC.sage(d).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AC.sage(d), width: 1.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(u.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                          Text(u.username, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: sb)),
                          Text(u.role.label, style: TextStyle(fontSize: 9, color: lt)),
                        ]),
                        const SizedBox(width: 8),
                        Icon(Icons.add_circle_rounded, color: AC.peach(d), size: 18),
                      ]),
                    ),
                  );
                },
              ),
            ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            decoration: BoxDecoration(color: AC.card(d), borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tab,
              labelColor: Colors.white,
              unselectedLabelColor: lt,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              indicator: BoxDecoration(color: AC.peach(d), borderRadius: BorderRadius.circular(10)),
              tabs: const [Tab(text: 'Friends'), Tab(text: 'Find People')],
            ),
          ),
          Expanded(child: TabBarView(controller: _tab, children: [
            fr.isEmpty
                ? Center(child: Text('No friends yet.\nSearch to add!', textAlign: TextAlign.center, style: TextStyle(color: lt, height: 1.6)))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: fr.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final f  = fr[i];
                      final u  = f.user;
                      final lm = f.msgs.isNotEmpty ? f.msgs.last : null;
                      return GestureDetector(
                        onTap: () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => ChatScreen(fr: f))).then((_) => setState(() {})),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AC.card(d), borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(children: [
                            Stack(children: [
                              Container(
                                width: 46, height: 46,
                                decoration: BoxDecoration(gradient: LinearGradient(colors: [AC.peach(d), AC.sage(d)]), shape: BoxShape.circle),
                                child: Center(child: Text(u.emoji, style: const TextStyle(fontSize: 22))),
                              ),
                              if (u.online) Positioned(right: 0, bottom: 0, child: Container(
                                width: 12, height: 12,
                                decoration: BoxDecoration(color: AC.online, shape: BoxShape.circle, border: Border.all(color: AC.card(d), width: 2)),
                              )),
                            ]),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text(u.username, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: sb)),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: AC.peach(d).withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                  child: Text(u.role.label, style: TextStyle(fontSize: 9, color: AC.peach(d))),
                                ),
                              ]),
                              if (lm != null)
                                Text(lm.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: lt))
                              else
                                Text('Tap to start chatting', style: TextStyle(fontSize: 12, color: lt, fontStyle: FontStyle.italic)),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              if (lm != null) Text(_tl(lm.time), style: TextStyle(fontSize: 10, color: lt)),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () { setState(() => f.pinned = !f.pinned); St.save(); },
                                child: Icon(f.pinned ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                            color: f.pinned ? AC.peach(d) : lt, size: 18),
                              ),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
            ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: kMock.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final u  = kMock[i];
                final ia = curUser?.friends.any((f) => f.user.id == u.id) ?? false;
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AC.card(d), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [AC.peach(d), AC.sage(d)]), shape: BoxShape.circle),
                      child: Center(child: Text(u.emoji, style: const TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u.username, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: sb)),
                      Text(u.desc, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: lt)),
                    ])),
                    if (u.online) Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AC.online.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: AC.online, shape: BoxShape.circle)),
                        const SizedBox(width: 4),
                        Text('Online', style: TextStyle(fontSize: 10, color: AC.online, fontWeight: FontWeight.bold)),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: ia ? null : () => _add(u),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ia ? AC.sage(d).withOpacity(0.2) : AC.peach(d),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(ia ? 'Added' : 'Add',
                                   style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ia ? AC.sage(d) : Colors.white)),
                      ),
                    ),
                  ]),
                );
              },
            ),
          ])),
        ])),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CHAT SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ChatScreen extends StatefulWidget {
  final Friend fr;
  const ChatScreen({super.key, required this.fr});
  @override State<ChatScreen> createState() => _ChatS();
}

class _ChatS extends State<ChatScreen> {
  final _c   = TextEditingController();
  final _sc  = ScrollController();
  @override void dispose() { _c.dispose(); _sc.dispose(); super.dispose(); }

  void _send() {
    if (_c.text.trim().isEmpty) return;
    widget.fr.msgs.add(ChatMsg(sid: 'me', text: _c.text.trim(), time: DateTime.now()));
    _c.clear();
    setState(() {});
    _scroll();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      final replies = [
        'Thank you for the report!',
        'Can you share the location?',
        "We're on our way! 🐾",
        'Photo received. We will help right away.',
        'Please keep the animal safe until we arrive.',
      ];
      widget.fr.msgs.add(ChatMsg(
        sid:  widget.fr.user.id,
        text: replies[DateTime.now().millisecond % replies.length],
        time: DateTime.now(),
      ));
      setState(() {});
      _scroll();
    });
  }

  void _scroll() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_sc.hasClients) {
        _sc.animateTo(_sc.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext ctx) {
    final d  = dark(ctx);
    final sb = AC.sb(d);
    final lt = AC.lt(d);
    final u  = widget.fr.user;
    return Scaffold(
      body: Container(
        decoration: gbg(d),
        child: SafeArea(child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
            color: AC.card(d),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.arrow_back_ios_new_rounded), color: sb),
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(gradient: LinearGradient(colors: [AC.peach(d), AC.sage(d)]), shape: BoxShape.circle),
                child: Center(child: Text(u.emoji, style: const TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u.username, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: sb)),
                Row(children: [
                  if (u.online) Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(color: AC.online, shape: BoxShape.circle),
                  ),
                  Text(u.online ? 'Online' : u.role.label, style: TextStyle(fontSize: 11, color: u.online ? AC.online : lt)),
                ]),
              ])),
              IconButton(
                icon: Icon(widget.fr.pinned ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: widget.fr.pinned ? AC.peach(d) : lt),
                onPressed: () { setState(() => widget.fr.pinned = !widget.fr.pinned); St.save(); },
              ),
            ]),
          ),
          Expanded(child: widget.fr.msgs.isEmpty
              ? Center(child: Text("Say hello to ${u.username}! 👋", style: TextStyle(color: lt, fontStyle: FontStyle.italic)))
              : ListView.builder(
                  controller: _sc,
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.fr.msgs.length,
                  itemBuilder: (_, i) {
                    final m    = widget.fr.msgs[i];
                    final isMe = m.sid == 'me';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(ctx).size.width * 0.72),
                        decoration: BoxDecoration(
                          color: isMe ? AC.peach(d) : AC.card(d),
                          borderRadius: BorderRadius.only(
                            topLeft:     const Radius.circular(16),
                            topRight:    const Radius.circular(16),
                            bottomLeft:  Radius.circular(isMe ? 16 : 4),
                            bottomRight: Radius.circular(isMe ? 4  : 16),
                          ),
                        ),
                        child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
                          Text(m.text, style: TextStyle(fontSize: 14, color: isMe ? Colors.white : sb, height: 1.4)),
                          const SizedBox(height: 4),
                          Text(
                            '${m.time.hour.toString().padLeft(2, '0')}:${m.time.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : lt),
                          ),
                        ]),
                      ),
                    );
                  },
                )),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            color: AC.card(d),
            child: Row(children: [
              Expanded(child: TextField(
                controller: _c,
                style: TextStyle(color: AC.mt(d), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: lt, fontSize: 13),
                  filled: true, fillColor: AC.cream(d),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              )),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: AC.peach(d), shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ])),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOOKMARKS
// ─────────────────────────────────────────────────────────────────────────────
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});
  @override State<BookmarksScreen> createState() => _BookS();
}

class _BookS extends State<BookmarksScreen> {
  @override
  Widget build(BuildContext ctx) {
    final d     = dark(ctx);
    final sb    = AC.sb(d);
    final lt    = AC.lt(d);
    final items = curUser?.bookmarks ?? [];
    final bf    = curUser?.friends.where((f) => f.pinned).toList() ?? [];
    return Scaffold(
      body: Container(
        decoration: gbg(d),
        child: SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.arrow_back_ios_new_rounded), color: sb),
              Text('Bookmarks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: sb)),
              const Spacer(),
              const Text('📌', style: TextStyle(fontSize: 20)),
            ]),
          ),
          Expanded(child: (items.isEmpty && bf.isEmpty)
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🔖', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text('No bookmarks yet', style: TextStyle(fontSize: 16, color: sb, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Pin friends or save animal photos here', style: TextStyle(fontSize: 13, color: lt, fontStyle: FontStyle.italic)),
                ]))
              : ListView(padding: const EdgeInsets.all(16), children: [
                  if (bf.isNotEmpty) ...[
                    Text('Pinned Contacts', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: lt, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    ...bf.map((f) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AC.card(d), borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        Container(width: 44, height: 44,
                          decoration: BoxDecoration(gradient: LinearGradient(colors: [AC.peach(d), AC.sage(d)]), shape: BoxShape.circle),
                          child: Center(child: Text(f.user.emoji, style: const TextStyle(fontSize: 22)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(f.user.username, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: sb)),
                          Text(f.user.role.label, style: TextStyle(fontSize: 12, color: lt)),
                        ])),
                        GestureDetector(
                          onTap: () { setState(() => f.pinned = false); St.save(); },
                          child: Icon(Icons.bookmark_rounded, color: AC.peach(d), size: 20),
                        ),
                      ]),
                    )),
                    const SizedBox(height: 16),
                  ],
                  if (items.isNotEmpty) ...[
                    Text('Saved Items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: lt, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    ...items.map((bm) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: AC.card(d), borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        Container(width: 44, height: 44,
                          decoration: BoxDecoration(color: AC.blush(d).withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                          child: Center(child: Text(bm.emoji, style: const TextStyle(fontSize: 24)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(bm.title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: sb)),
                          Text(bm.subtitle, style: TextStyle(fontSize: 12, color: lt)),
                        ])),
                        GestureDetector(
                          onTap: () { setState(() => curUser!.bookmarks.remove(bm)); St.save(); },
                          child: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withOpacity(0.7), size: 20),
                        ),
                      ]),
                    )),
                  ],
                ])),
        ])),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS  ← LOGO ADDED TO ABOUT DIALOG
// ─────────────────────────────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext ctx) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (ctx, dv, _) {
        final d  = dv;
        final sb = AC.sb(d);
        return Scaffold(
          body: Container(
            decoration: gbg(d),
            child: SafeArea(child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 24, 8),
                child: Row(children: [
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.arrow_back_ios_new_rounded), color: sb),
                  Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: sb)),
                ]),
              ),
              Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
                slbl('Account', d),
                stile(Icons.person_outline_rounded, 'Profile',        AC.peach(d).withOpacity(0.2), d, () => Navigator.pushNamed(ctx, '/profile')),
                stile(Icons.people_outline_rounded, 'Friends & Chat', AC.sky(d).withOpacity(0.3),   d, () => Navigator.pushNamed(ctx, '/friends')),
                stile(Icons.bookmark_border_rounded,'Bookmarks',      AC.lav(d).withOpacity(0.3),   d, () => Navigator.pushNamed(ctx, '/bookmarks')),
                const SizedBox(height: 12),
                slbl('Role', d),
                ...UserRole.values.map((r) {
                  final sel = curUser?.role == r;
                  return GestureDetector(
                    onTap: () async { curUser?.role = r; await St.save(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: sel ? AC.peach(d).withOpacity(0.15) : AC.card(d).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: sel ? AC.peach(d) : AC.blush(d), width: sel ? 2 : 1.5),
                      ),
                      child: Row(children: [
                        Icon(r.icon, color: sel ? AC.peach(d) : sb, size: 22),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(r.label, style: TextStyle(fontSize: 15, color: sb, fontWeight: FontWeight.w500)),
                          Text(r.desc,  style: TextStyle(fontSize: 11, color: AC.lt(d)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        if (sel) Icon(Icons.check_circle, color: AC.peach(d), size: 20),
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                slbl('Appearance', d),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(color: AC.lav(d).withOpacity(0.3), borderRadius: BorderRadius.circular(16)),
                  child: Row(children: [
                    Icon(Icons.dark_mode_outlined, color: sb, size: 22),
                    const SizedBox(width: 14),
                    Text('Dark Mode', style: TextStyle(fontSize: 15, color: sb, fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Switch(
                      value: d, activeColor: AC.peach(d),
                      onChanged: (v) { themeNotifier.value = v; appDark = v; St.save(); },
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                slbl('Legal', d),
                stile(Icons.policy_outlined, 'Terms & Privacy', AC.sky(d).withOpacity(0.3), d, () => Navigator.pushNamed(ctx, '/terms')),
                const SizedBox(height: 12),
                slbl('Info', d),
                stile(Icons.info_outline_rounded, 'About the App',      AC.blush(d).withOpacity(0.3), d, () => _dlg(ctx, d, false)),
                stile(Icons.code_rounded,         'About the Developer', AC.sage(d).withOpacity(0.3),  d, () => _dlg(ctx, d, true)),
                const SizedBox(height: 24),
                if (curUser != null) Center(child: GestureDetector(
                  onTap: () async {
                    await St.clear();
                    curUser = null;
                    if (ctx.mounted) Navigator.pushNamedAndRemoveUntil(ctx, '/', (r) => false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.5),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                      SizedBox(width: 8),
                      Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                  ),
                )),
              ])),
            ])),
          ),
        );
      },
    );
  }

  void _dlg(BuildContext c, bool d, bool dev) {
    showDialog(
      context: c,
      builder: (_) => AlertDialog(
        backgroundColor: AC.card(d),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── LOGO IN ABOUT DIALOG ───────────────────────────────────────
          appLogo(size: 64),
          const SizedBox(height: 8),
          Row(children: [
            Text(dev ? '👨‍💻 ' : '🐾 ', style: const TextStyle(fontSize: 20)),
            Text(dev ? 'Developer' : 'ALAG-AP',
                style: TextStyle(color: AC.sb(d), fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
        ]),
        content: Text(
          dev
            ? 'ALAG-AP is built with ❤️ for the animals of the Philippines.\n\nContact: alagap.philippines@gmail.com\n\nFlutter • OpenStreetMap • Overpass API • CARTO'
            : 'ALAG-AP connects stray animals with nearby shelters, vets, and adoption centers.\n\nLog in daily to build your streak and earn coins! 🔥🪙',
          style: TextStyle(color: AC.mt(d), height: 1.6, fontSize: 14),
        ),
        actions: [TextButton(
          onPressed: () => Navigator.pop(c),
          child: Text('Close', style: TextStyle(color: AC.peach(d), fontWeight: FontWeight.bold)),
        )],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override State<ProfileScreen> createState() => _ProfileS();
}

class _ProfileS extends State<ProfileScreen> {
  late TextEditingController _dn, _bio;
  bool _ed = false;
  final _picker = ImagePicker();

  @override void initState() {
    super.initState();
    _dn  = TextEditingController(text: curUser?.displayName ?? '');
    _bio = TextEditingController(text: curUser?.bio ?? '');
  }
  @override void dispose() { _dn.dispose(); _bio.dispose(); super.dispose(); }

  Future<void> _pickPhoto(ImageSource src) async {
    final x = await _picker.pickImage(source: src, imageQuality: 50, maxWidth: 400, maxHeight: 400);
    if (x == null) return;
    final raw = await x.readAsBytes();
    final cap = raw.length > 150 * 1024 ? Uint8List.fromList(raw.sublist(0, 150 * 1024)) : raw;
    if (mounted) setState(() { curUser?.avBytes = cap; curUser?.avEmoji = null; });
    await St.save();
  }

  void _showAvPicker() {
    final d = dark(context);
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: .55, minChildSize: .4, maxChildSize: .85, expand: false,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(color: AC.card(d), borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: ListView(controller: sc, padding: const EdgeInsets.fromLTRB(24, 12, 24, 32), children: [
            Center(child: Container(
              width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            )),
            Text('Choose Avatar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AC.sb(d))),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: _AbBtn(icon: Icons.photo_library_outlined, label: 'Gallery', color: AC.sky(d),
                onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.gallery); })),
              const SizedBox(width: 12),
              Expanded(child: _AbBtn(icon: Icons.camera_alt_outlined, label: 'Camera', color: AC.sage(d),
                onTap: () { Navigator.pop(context); _pickPhoto(ImageSource.camera); })),
            ]),
            const SizedBox(height: 20),
            Text('Or pick an animal avatar:', style: TextStyle(fontSize: 13, color: AC.lt(d), fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 6, shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8, mainAxisSpacing: 8,
              children: kAvatars.map((e) {
                final sel = curUser?.avEmoji == e && curUser?.avBytes == null;
                return GestureDetector(
                  onTap: () async {
                    setState(() { curUser?.avEmoji = e; curUser?.avBytes = null; });
                    await St.save();
                    if (mounted) { Navigator.pop(context); setState(() {}); }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: sel ? AC.peach(d).withOpacity(0.3) : AC.cream(d),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? AC.peach(d) : Colors.transparent, width: 2),
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 24))),
                  ),
                );
              }).toList(),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (curUser != null) {
      if (_dn.text.trim().isNotEmpty) {
        curUser!.displayName = _dn.text.trim();
        curUser!.username    = _dn.text.trim();
      }
      curUser!.bio = _bio.text.trim().isEmpty ? null : _bio.text.trim();
    }
    await St.save();
    setState(() => _ed = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Profile updated!'), backgroundColor: AC.sage(false), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final d  = dark(ctx);
    final sb = AC.sb(d);
    final lt = AC.lt(d);
    final u  = curUser;
    return Scaffold(
      body: Container(
        decoration: gbg(d),
        child: SafeArea(child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.arrow_back_ios_new_rounded), color: sb),
              Text('My Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: sb)),
              const Spacer(),
              if (!_ed)
                GestureDetector(
                  onTap: () => setState(() => _ed = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: AC.peach(d).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                    child: Text('Edit', style: TextStyle(color: AC.peach(d), fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                )
              else
                GestureDetector(
                  onTap: _save,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(color: AC.sage(d).withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                    child: Text('Save', style: TextStyle(color: sb, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
            ]),
          ),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              Stack(alignment: Alignment.bottomRight, children: [
                UAv(
                  key: ValueKey('${u?.avBytes?.length ?? 0}_${u?.avEmoji ?? ""}'),
                  u: u, sz: 100, fs: 42,
                ),
                GestureDetector(
                  onTap: _showAvPicker,
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: AC.peach(d), shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: AC.peach(d).withOpacity(0.3), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              if (!_ed) ...[
                Text(u?.displayName ?? u?.username ?? 'Guest',
                     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: sb)),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: AC.peach(d).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Text(u?.role.label ?? '', style: TextStyle(fontSize: 12, color: AC.peach(d), fontWeight: FontWeight.bold)),
                ),
                Text(u?.email ?? '', style: TextStyle(fontSize: 13, color: lt)),
                if (u?.bio != null) ...[
                  const SizedBox(height: 8),
                  Text(u!.bio!, textAlign: TextAlign.center,
                       style: TextStyle(fontSize: 14, color: AC.mt(d), fontStyle: FontStyle.italic)),
                ],
              ],
              const SizedBox(height: 20),
              if (u != null) Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AC.streak.withOpacity(0.1), AC.blush(d).withOpacity(0.2)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AC.streak.withOpacity(0.3), width: 1.5),
                ),
                child: Row(children: [
                  const Text('🔥', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${u.streak} Day Streak', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sb)),
                    Text(u.streak > 0 ? 'Tomorrow: +${math.min(u.streak + 1, 7)} coins' : 'Log in daily for bonuses!',
                         style: TextStyle(fontSize: 12, color: lt)),
                  ])),
                  GestureDetector(
                    onTap: () async { await St.resetStreak(); setState(() {}); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.withOpacity(0.3), width: 1),
                      ),
                      child: const Text('Reset', style: TextStyle(fontSize: 11, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ]),
              ),
              CoinCal(u: u, d: d),
              const SizedBox(height: 20),
              if (_ed) ...[
                fld(_dn, 'Display Name', Icons.person_outline_rounded, d),
                const SizedBox(height: 14),
                fld(_bio, 'Bio', Icons.edit_outlined, d, lines: 3),
                const SizedBox(height: 20),
              ],
              Row(children: [
                Expanded(child: _SC(label: 'Reports',   val: '${u?.reports   ?? 0}', emoji: '📍', col: AC.sky(d).withOpacity(0.4),  d: d)),
                const SizedBox(width: 14),
                Expanded(child: _SC(label: 'Adoptions', val: '${u?.adoptions ?? 0}', emoji: '🏠', col: AC.sage(d).withOpacity(0.4), d: d)),
              ]),
              const SizedBox(height: 32),
            ]),
          )),
        ])),
      ),
    );
  }
}



// ═══════════════════════════════════════════════════════════════════════════════
//   1. The `AdoptionCase` class
//   2. The `AdoptSt` class
//   3. The `AdoptScreen` class and `_AdoptS` state
//   4. The `_Stp` helper class at the bottom
// ═══════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// ADOPTION CASE MODEL  (replaces old AdoptionCase)
// ─────────────────────────────────────────────────────────────────────────────
class AdoptionCase {
  final String id, name, emoji;
  final DateTime addedAt;
  List<bool> steps;
  String? imagePath;   // ← NEW: stores base64-encoded image

  AdoptionCase({
    required this.id,
    required this.name,
    required this.emoji,
    required this.addedAt,
    List<bool>? steps,
    this.imagePath,
  }) : steps = steps ?? List.filled(6, false);

  double get progress => steps.where((s) => s).length / steps.length;
  int    get completedCount => steps.where((s) => s).length;
  bool   get isComplete => steps.every((s) => s);

  Map<String, dynamic> toJson() => {
    'id':        id,
    'name':      name,
    'emoji':     emoji,
    'addedAt':   addedAt.toIso8601String(),
    'steps':     steps,
    'imagePath': imagePath,   // ← NEW
  };

  factory AdoptionCase.fromJson(Map<String, dynamic> j) => AdoptionCase(
    id:        j['id'],
    name:      j['name'],
    emoji:     j['emoji'],
    addedAt:   DateTime.parse(j['addedAt']),
    steps:     List<bool>.from(j['steps']),
    imagePath: j['imagePath'] as String?,  // ← NEW
  );

  // Helper: decode stored base64 image back to bytes
  Uint8List? get imageBytes {
    if (imagePath == null) return null;
    try { return base64Decode(imagePath!); } catch (_) { return null; }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PATCH: Replace the AdoptSt class in your main.dart with this version.
// It seeds two demo cases (Brownie the dog + Serpico the ball python)
// the first time the app loads, so "My Cases" is never empty.
// ─────────────────────────────────────────────────────────────────────────────

class AdoptSt {
  static const _key = 'adopt_cases';

  static Future<List<AdoptionCase>> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);

    // ── If data already exists, return it ────────────────────────────────────
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        return list
            .map((e) => AdoptionCase.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }

    // ── First launch: seed two demo cases ────────────────────────────────────
    final demo = _seedCases();
    await save(demo);
    return demo;
  }

  /// Returns the two pre-populated demo adoption cases.
  static List<AdoptionCase> _seedCases() {
    // Brownie – Aspin dog, rescued Jan 2025, 3 of 6 steps done
    final brownie = AdoptionCase(
      id:      'demo_brownie',
      name:    'Brownie',
      emoji:   '🐶',
      addedAt: DateTime(2025, 1, 15),
      steps:   [true, true, true, false, false, false], // step 1-3 done
    );

    // Serpico – Ball python, rescued Mar 2025, 0 steps done
    final serpico = AdoptionCase(
      id:      'demo_serpico',
      name:    'Serpico',
      emoji:   '🐍',
      addedAt: DateTime(2025, 3, 10),
      steps:   [false, false, false, false, false, false], // vet overdue
    );

    return [brownie, serpico];
  }

  static Future<void> save(List<AdoptionCase> cases) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _key,
      jsonEncode(cases.map((c) => c.toJson()).toList()),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// PATCH 2: In _AdoptS, update _buildStatusBadge() to match the screenshots.
// Add this method inside the _AdoptS class (replaces any existing badge logic).
//
// It shows:
//   • "In progress — step N of 6"  when 1–5 steps done
//   • "Action needed — vet check overdue"  when 0 steps done
//   • "Complete ✓"  when all 6 done
// ─────────────────────────────────────────────────────────────────────────────

  Widget _buildStatusBadge(AdoptionCase c, bool d) {
    if (c.isComplete) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.4), width: 1),
        ),
        child: const Text(
          'Complete ✓',
          style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (c.completedCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF0E6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8A87C), width: 1),
        ),
        child: const Text(
          'Action needed — vet check overdue',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFFB85D0A),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Find the index of the first incomplete step (1-based for display)
    final nextStep = c.steps.indexWhere((s) => !s) + 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8AB4F8), width: 1),
      ),
      child: Text(
        'In progress — step $nextStep of 6',
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF1A56C4),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


// ─────────────────────────────────────────────────────────────────────────────
// PATCH 3: In the "My Cases" tab itemBuilder, replace the existing badge line:
//
//   BEFORE (inside the card Column > Row children):
//     if (c.isComplete)
//       Container( ... )
//
//   AFTER — add this right below the animal name Text widget in the card:
//     _buildStatusBadge(c, d),
//     const SizedBox(height: 4),
//
// Also update the progress label text to match screenshot style.
// Find this text inside the itemBuilder and update it:
//
//   BEFORE:
//     Text(
//       '${c.completedCount}/6 steps · '
//       '${(c.progress * 100).toInt()}%',
//       ...
//     ),
//
//   AFTER:
//     Text(
//       c.completedCount == 0
//         ? '${c.completedCount} of 6 steps complete · awaiting first vet visit'
//         : '${c.completedCount} of 6 steps complete · ${(c.progress * 100).toInt()}%',
//       style: TextStyle(
//         fontSize: 12,
//         color: c.isComplete
//             ? Colors.green
//             : c.completedCount == 0
//                 ? const Color(0xFFB85D0A)
//                 : AC.lt(d),
//         fontWeight: c.isComplete || c.completedCount == 0
//             ? FontWeight.bold
//             : FontWeight.normal,
//       ),
//     ),
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// ADOPT SCREEN  (replaces old AdoptScreen + _AdoptS)
// ─────────────────────────────────────────────────────────────────────────────
class AdoptScreen extends StatefulWidget {
  const AdoptScreen({super.key});
  @override State<AdoptScreen> createState() => _AdoptS();
}

class _AdoptS extends State<AdoptScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<AdoptionCase> _cases   = [];
  bool               _loading = true;
  final _picker = ImagePicker();

  // ── Step definitions ────────────────────────────────────────────────────────
  static const _stepInfo = [
    _Stp('01','🩺','Visit a Veterinarian',
        'A licensed vet must perform a physical exam and issue a health certificate. '
        'This ensures the animal is healthy before adoption.\n\n'
        '• Book an appointment with a PAWS-accredited vet\n'
        '• Bring the animal in a secure carrier\n'
        '• Request a complete health record\n'
        '• Check for existing microchip',
        null),
    _Stp('02','📋','Register the Animal',
        'All adopted animals must be registered at your City Hall or Barangay Hall within '
        '30 days of adoption.\n\n'
        '• Bring a valid government-issued ID\n'
        '• Present the vet health certificate\n'
        '• Pay the registration fee (varies per city)\n'
        '• Keep the registration tag on the animal',
        null),
    _Stp('03','💉','Vaccinations',
        'Core vaccines protect your pet and the community from preventable diseases.\n\n'
        '• Anti-rabies vaccine (required by law in PH)\n'
        '• Distemper / Parvovirus combo\n'
        '• Deworming every 3–6 months\n'
        '• Keep the vaccination booklet updated',
        null),
    _Stp('04','📝','Adoption Papers',
        'Formal adoption paperwork protects both you and the animal.\n\n'
        '• Sign the shelter\'s adoption agreement\n'
        '• Agree to a home inspection within 30 days\n'
        '• Provide proof of residence\n'
        '• Receive the animal\'s history / medical records',
        null),
    _Stp('05','🏡','Prepare Your Home',
        'A safe, loving environment is essential for your new pet\'s adjustment.\n\n'
        '• Set up a dedicated sleeping area\n'
        '• Pet-proof dangerous areas (cables, chemicals)\n'
        '• Stock food, water bowls, and litter (for cats)\n'
        '• Plan an introductory routine for the first week',
        null),
    _Stp('06','💛','Ongoing Healthcare',
        'Responsible pet ownership means continued commitment to health.\n\n'
        '• Vet check-up every 6 months\n'
        '• Annual booster vaccines\n'
        '• Spay/neuter if not already done\n'
        '• Update registration annually',
        null),
  ];

  static const _stepColors = [
    Color(0xFFFFD6CC),
    Color(0xFFB5D5C5),
    Color(0xFFBFDEF5),
    Color(0xFFD8CCF0),
    Color(0xFFFFB5A0),
    Color(0xFFB5D5C5),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadCases();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _loadCases() async {
    final c = await AdoptSt.load();
    setState(() { _cases = c; _loading = false; });
  }

  // ── Pick image helper ────────────────────────────────────────────────────────
  Future<String?> _pickImageAsBase64(ImageSource source) async {
      await ScreenSecurity.enableSecureMode();
      try {
        final x = await _picker.pickImage(
          source: source, imageQuality: 60, maxWidth: 600, maxHeight: 600,
        );
        if (x == null) {
          await ScreenSecurity.disableSecureMode();
          return null;
        }
        final raw = await x.readAsBytes();
        final cap = raw.length > 200 * 1024
            ? Uint8List.fromList(raw.sublist(0, 200 * 1024))
            : raw;
        await ScreenSecurity.disableSecureMode();
        return base64Encode(cap);
      } catch (e) {
        await ScreenSecurity.disableSecureMode();
        return null;
      }
  }

  // ── Attach / change image for an existing case ───────────────────────────────
  Future<void> _attachImage(AdoptionCase c) async {
    final d = dark(context);
    final source = await showModalBottomSheet<ImageSource?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ImageSourceSheet(d: d),
    );
    if (source == null) return;
    final b64 = await _pickImageAsBase64(source);
    if (b64 == null) return;
    setState(() => c.imagePath = b64);
    await AdoptSt.save(_cases);
  }


  // ── Add new case ─────────────────────────────────────────────────────────────
  Future<void> _addCase() async {
    final emojis = ['🐶','🐱','🐰','🐹','🐾','🦴','🐕','🐈','🐇','🦮'];
    final nameCtrl = TextEditingController();
    String  selEmoji  = emojis[0];
    String? b64Image;
    final d = dark(context);

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: AC.card(d),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('New Adoption Case',
              style: TextStyle(color: AC.sb(d), fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [

            // ── Photo picker ──────────────────────────────────────────────
            GestureDetector(
              onTap: () async {
                final source = await showModalBottomSheet<ImageSource?>(
                  context: ctx,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _ImageSourceSheet(d: d),
                );
                if (source == null) return;
                final x = await _picker.pickImage(
                  source: source, imageQuality: 60, maxWidth: 600, maxHeight: 600,
                );
                if (x == null) return;
                final raw = await x.readAsBytes();
                final cap = raw.length > 200 * 1024
                    ? Uint8List.fromList(raw.sublist(0, 200 * 1024))
                    : raw;
                setSt(() => b64Image = base64Encode(cap));
              },
              child: Container(
                height: 110, width: double.infinity,
                decoration: BoxDecoration(
                  color: AC.cream(d),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AC.blush(d), width: 1.5),
                ),
                child: b64Image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.memory(base64Decode(b64Image!), fit: BoxFit.cover),
                      )
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_a_photo_outlined, color: AC.peach(d), size: 30),
                        const SizedBox(height: 6),
                        Text('Add photo (optional)',
                            style: TextStyle(fontSize: 12, color: AC.lt(d))),
                      ]),
              ),
            ),
            const SizedBox(height: 14),

            // ── Emoji row ─────────────────────────────────────────────────
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: emojis.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final e   = emojis[i];
                  final sel = selEmoji == e;
                  return GestureDetector(
                    onTap: () => setSt(() => selEmoji = e),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: sel ? AC.peach(d).withOpacity(0.3) : AC.cream(d),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel ? AC.peach(d) : Colors.transparent, width: 2),
                      ),
                      child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // ── Name field ────────────────────────────────────────────────
            TextField(
              controller: nameCtrl,
              style: TextStyle(color: AC.mt(d)),
              decoration: InputDecoration(
                hintText: 'Animal name (e.g. Brownie)',
                hintStyle: TextStyle(color: AC.lt(d), fontSize: 13),
                filled: true, fillColor: AC.cream(d),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
            ),
          ])),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: AC.lt(d))),
            ),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx);
              },
              child: Text('Add',
                  style: TextStyle(color: AC.peach(d), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (nameCtrl.text.trim().isEmpty) return;

    final nc = AdoptionCase(
      id:        '${DateTime.now().millisecondsSinceEpoch}',
      name:      nameCtrl.text.trim(),
      emoji:     selEmoji,
      addedAt:   DateTime.now(),
      imagePath: b64Image,   // ← saved image
    );
    setState(() => _cases.insert(0, nc));
    await AdoptSt.save(_cases);
    _tab.animateTo(1);
  }

  Future<void> _deleteCase(AdoptionCase c) async {
    setState(() => _cases.remove(c));
    await AdoptSt.save(_cases);
  }

  Future<void> _toggleStep(AdoptionCase c, int idx) async {
    setState(() => c.steps[idx] = !c.steps[idx]);
    await AdoptSt.save(_cases);
  }

  // ── Case detail bottom sheet ─────────────────────────────────────────────────
  void _openCaseDetail(AdoptionCase c) {
    final d = dark(context);
    showModalBottomSheet(
      context:  context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => DraggableScrollableSheet(
          initialChildSize: 0.90,
          maxChildSize:     0.97,
          minChildSize:     0.55,
          expand: false,
          builder: (_, sc) => Container(
            decoration: BoxDecoration(
              color: AC.card(d),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: ListView(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [

                // handle
                Center(child: Container(
                  width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2)),
                )),

                // ── Animal photo ──────────────────────────────────────────
                GestureDetector(
                  onTap: () async {
                    final source = await showModalBottomSheet<ImageSource?>(
                      context: ctx,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _ImageSourceSheet(d: d),
                    );
                    if (source == null) return;
                    final b64 = await _pickImageAsBase64(source);
                    if (b64 == null) return;
                    setSt(() => c.imagePath = b64);
                    setState(() {});
                    await AdoptSt.save(_cases);
                  },
                  child: Container(
                    height: 180, width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AC.cream(d),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: c.imagePath != null ? AC.sage(d) : AC.blush(d),
                        width: 2),
                    ),
                    child: c.imageBytes != null
                        ? Stack(fit: StackFit.expand, children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.memory(c.imageBytes!, fit: BoxFit.cover),
                            ),
                            Positioned(
                              bottom: 10, right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(12)),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.edit, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text('Change photo',
                                      style: TextStyle(color: Colors.white, fontSize: 11)),
                                ]),
                              ),
                            ),
                          ])
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_a_photo_outlined,
                                color: AC.peach(d), size: 34),
                            const SizedBox(height: 8),
                            Text('Tap to add a photo',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AC.lt(d),
                                    fontStyle: FontStyle.italic)),
                          ]),
                  ),
                ),

                // ── Header row ────────────────────────────────────────────
                Row(children: [
                  Text(c.emoji, style: const TextStyle(fontSize: 36)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(c.name,
                        style: TextStyle(fontSize: 22,
                            fontWeight: FontWeight.bold, color: AC.sb(d))),
                    Text('${c.completedCount}/6 steps complete',
                        style: TextStyle(fontSize: 13, color: AC.lt(d))),
                  ])),
                  if (c.isComplete) Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.green.withOpacity(0.4), width: 1.5)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('✅', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text('Done!',
                          style: TextStyle(fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 14),

                // ── Animated progress bar ─────────────────────────────────
                _AnimatedProgressBar(
                  progress: c.progress,
                  isComplete: c.isComplete,
                  d: d,
                ),
                const SizedBox(height: 6),
                Text(
                  c.isComplete
                      ? '🎉 All steps completed! Your pet is fully registered.'
                      : '${((c.progress) * 100).toInt()}% complete — ${6 - c.completedCount} step${6 - c.completedCount == 1 ? "" : "s"} remaining',
                  style: TextStyle(
                    fontSize: 12,
                    color: c.isComplete ? Colors.green : AC.lt(d),
                    fontWeight: c.isComplete ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Instruction ───────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AC.sky(d).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Text('ℹ️', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(
                      'Tap the checkbox to mark a step done. Tap the step title to see details.',
                      style: TextStyle(fontSize: 12, color: AC.mt(d), height: 1.4),
                    )),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── Steps with checkboxes ─────────────────────────────────
                ...List.generate(_stepInfo.length, (i) {
                  final s    = _stepInfo[i];
                  final done = c.steps[i];
                  final col  = _stepColors[i % _stepColors.length];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: done
                          ? col.withOpacity(0.85)
                          : col.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: done
                            ? Colors.green.withOpacity(0.55)
                            : col.withOpacity(0.6),
                        width: done ? 2 : 1.5,
                      ),
                    ),
                    child: Theme(
                      data: Theme.of(ctx).copyWith(
                          dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        // ── Tappable checkbox on the left ─────────────────
                        leading: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            setSt(() => c.steps[i] = !c.steps[i]);
                            setState(() {});
                            await AdoptSt.save(_cases);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: done
                                  ? Colors.green
                                  : Colors.white.withOpacity(0.65),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: done
                                    ? Colors.green.shade700
                                    : AC.lt(d),
                                width: 2,
                              ),
                              boxShadow: done
                                  ? [BoxShadow(
                                      color: Colors.green.withOpacity(0.35),
                                      blurRadius: 8,
                                    )]
                                  : null,
                            ),
                            child: done
                                ? const Icon(Icons.check_rounded,
                                    color: Colors.white, size: 18)
                                : Center(child: Text(
                                    s.n,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AC.lt(d),
                                    ),
                                  )),
                          ),
                        ),

                        // ── Title ─────────────────────────────────────────
                        title: Row(children: [
                          Text(s.i, style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(
                            s.t,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AC.sb(d),
                              decoration: done
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          )),
                        ]),

                        // ── Details (expanded) ────────────────────────────
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        children: [
                          Text(s.d,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: AC.mt(d),
                                  height: 1.6)),
                        ],
                      ),
                    ),
                  );
                }),

                // ── Completion banner ─────────────────────────────────────
                if (c.isComplete)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.green.withOpacity(0.15),
                        Colors.teal.withOpacity(0.1),
                      ]),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.green.withOpacity(0.4), width: 2),
                    ),
                    child: Column(children: [
                      const Text('🎉', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 8),
                      Text('Adoption Complete!',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AC.sb(d))),
                      const SizedBox(height: 4),
                      Text(
                        '${c.name} is officially part of the family. '
                        'Remember annual check-ups and vaccine boosters!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13, color: AC.mt(d), height: 1.5),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => setState(() {}));
  }

  // ════════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext ctx) {
    final arg = ModalRoute.of(ctx)?.settings.arguments as ImageArg?;
    final d   = dark(ctx);
    final sb  = AC.sb(d);

    return Scaffold(
      body: Container(
        decoration: gbg(d),
        child: SafeArea(child: Column(children: [

          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.arrow_back_ios_new_rounded), color: sb,
              ),
              Text('Adopt an Animal',
                  style: TextStyle(fontSize: 22,
                      fontWeight: FontWeight.bold, color: sb)),
              const Spacer(),
              GestureDetector(
                onTap: _addCase,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AC.peach(d),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text('Track',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ]),
                ),
              ),
            ]),
          ),

          // ── Tab bar ───────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            decoration: BoxDecoration(
                color: AC.card(d), borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tab,
              labelColor: Colors.white,
              unselectedLabelColor: AC.lt(d),
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold),
              indicator: BoxDecoration(
                  color: AC.peach(d),
                  borderRadius: BorderRadius.circular(10)),
              tabs: [
                const Tab(text: '📖 Guide'),
                Tab(text: '📋 My Cases (${_cases.length})'),
              ],
            ),
          ),

          // ── Tab views ─────────────────────────────────────────────────────
          Expanded(child: TabBarView(controller: _tab, children: [

            // ══ GUIDE TAB ═══════════════════════════════════════════════════
            ListView(padding: const EdgeInsets.all(20), children: [
              if (arg != null && arg.has)
                Container(
                  height: 180, margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                        color: AC.peach(d).withOpacity(0.3),
                        blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: bImg(arg)),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: AC.blush(d).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  const Text('🐶', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Tap a step to expand details.',
                        style: TextStyle(
                            fontSize: 13,
                            color: AC.mt(d),
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text('Use "+ Track" to track progress per animal.',
                        style: TextStyle(fontSize: 12, color: AC.lt(d))),
                  ])),
                ]),
              ),
              ...List.generate(_stepInfo.length, (i) {
                final s   = _stepInfo[i];
                final col = _stepColors[i % _stepColors.length];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                      color: col, borderRadius: BorderRadius.circular(18)),
                  child: Theme(
                    data: Theme.of(ctx)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Text(s.i,
                          style: const TextStyle(fontSize: 26)),
                      title: Text(s.t,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: sb)),
                      subtitle: Text(s.n,
                          style: TextStyle(
                              fontSize: 10,
                              color: AC.lt(d),
                              letterSpacing: 1)),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Text(s.d,
                            style: TextStyle(
                                fontSize: 13,
                                color: AC.mt(d),
                                height: 1.6)),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
            ]),

            // ══ MY CASES TAB ════════════════════════════════════════════════
            _loading
                ? Center(child: CircularProgressIndicator(color: AC.peach(d)))
                : _cases.isEmpty
                    ? Center(child: Column(
                        mainAxisSize: MainAxisSize.min, children: [
                        const Text('🐾', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('No adoption cases yet',
                            style: TextStyle(
                                fontSize: 16,
                                color: sb,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "+ Track" to start tracking an animal',
                          style: TextStyle(
                              fontSize: 13,
                              color: AC.lt(d),
                              fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _addCase,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: AC.peach(d),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                                mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.add, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Track New Animal',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ]),
                          ),
                        ),
                      ]))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cases.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final c   = _cases[i];
                          final col =
                              _stepColors[i % _stepColors.length];
                          return GestureDetector(
                            onTap: () => _openCaseDetail(c),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: col.withOpacity(0.35),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: c.isComplete
                                      ? Colors.green.withOpacity(0.5)
                                      : col,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(children: [

                                // ── Thumbnail or emoji ────────────────────
                                Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(
                                    color: col.withOpacity(0.4),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: c.imageBytes != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(11),
                                          child: Image.memory(
                                            c.imageBytes!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      : Center(child: Text(c.emoji,
                                          style: const TextStyle(
                                              fontSize: 30))),
                                ),
                                const SizedBox(width: 12),

                                // ── Info + progress ───────────────────────
                                Expanded(child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                  Row(children: [
                                    Expanded(child: Text(c.name,
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: sb))),
                                    if (c.isComplete)
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text('✅ Done',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green,
                                                fontWeight:
                                                    FontWeight.bold)),
                                      ),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${c.completedCount}/6 steps · '
                                    '${(c.progress * 100).toInt()}%',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: c.isComplete
                                            ? Colors.green
                                            : AC.lt(d),
                                        fontWeight: c.isComplete
                                            ? FontWeight.bold
                                            : FontWeight.normal),
                                  ),
                                  const SizedBox(height: 6),
                                  // mini progress bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: c.progress,
                                      minHeight: 6,
                                      backgroundColor:
                                          Colors.white.withOpacity(0.4),
                                      valueColor: AlwaysStoppedAnimation<
                                              Color>(
                                          c.isComplete
                                              ? Colors.green
                                              : AC.peach(d)),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // mini step dots
                                  Row(children:
                                      List.generate(6, (si) => Container(
                                        width: 20, height: 20,
                                        margin: const EdgeInsets.only(
                                            right: 3),
                                        decoration: BoxDecoration(
                                          color: c.steps[si]
                                              ? Colors.green.withOpacity(0.8)
                                              : Colors.white.withOpacity(0.5),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(child: Text(
                                          _stepInfo[si].i,
                                          style: TextStyle(
                                            fontSize: 7,
                                            color: c.steps[si]
                                                ? Colors.white
                                                : AC.lt(d),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )),
                                      ))),
                                ])),

                                // ── Delete button ─────────────────────────
                                GestureDetector(
                                  onTap: () => _deleteCase(c),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.redAccent.withOpacity(0.6),
                                    size: 20,
                                  ),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
          ])),
        ])),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED PROGRESS BAR WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedProgressBar extends StatefulWidget {
  final double progress;
  final bool   isComplete;
  final bool   d;
  const _AnimatedProgressBar({
    required this.progress,
    required this.isComplete,
    required this.d,
  });
  @override State<_AnimatedProgressBar> createState() =>
      _AnimatedProgressBarState();
}

class _AnimatedProgressBarState extends State<_AnimatedProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0, end: widget.progress)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedProgressBar old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _anim = Tween<double>(begin: old.progress, end: widget.progress)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl
        ..reset()
        ..forward();
    }
  }


  Widget _buildStatusBadge(AdoptionCase c, bool d) {
    if (c.isComplete) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.4), width: 1),
        ),
        child: const Text(
          'Complete ✓',
          style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (c.completedCount == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF0E6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8A87C), width: 1),
        ),
        child: const Text(
          'Action needed — vet check overdue',
          style: TextStyle(
            fontSize: 11,
            color: Color(0xFFB85D0A),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final nextStep = c.steps.indexWhere((s) => !s) + 1;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8AB4F8), width: 1),
      ),
      child: Text(
        'In progress — step $nextStep of 6',
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF1A56C4),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext ctx) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LinearProgressIndicator(
          value:      _anim.value,
          minHeight:  14,
          backgroundColor: AC.blush(widget.d).withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.isComplete ? Colors.green : AC.peach(widget.d),
          ),
        ),
      ),
      const SizedBox(height: 4),
      Row(children: [
        ...List.generate(6, (i) {
          final filled = _anim.value >= (i + 1) / 6 - 0.01;
          return Expanded(child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 5 ? 3 : 0, top: 2),
            decoration: BoxDecoration(
              color: filled
                  ? (widget.isComplete ? Colors.green : AC.peach(widget.d))
                  : AC.blush(widget.d).withOpacity(0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          ));
        }),
      ]),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// IMAGE SOURCE PICKER SHEET  (shared helper)
// ─────────────────────────────────────────────────────────────────────────────
class _ImageSourceSheet extends StatelessWidget {
  final bool d;
  const _ImageSourceSheet({required this.d});

  @override
  Widget build(BuildContext ctx) => Container(
    margin: const EdgeInsets.all(16),
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
    decoration: BoxDecoration(
      color: AC.card(d),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text('Add Photo', style: TextStyle(
          fontSize: 17, fontWeight: FontWeight.bold, color: AC.sb(d))),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(child: GestureDetector(
          onTap: () => Navigator.pop(ctx, ImageSource.camera),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AC.sky(d).withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AC.sky(d), width: 1.5),
            ),
            child: Column(children: [
              Icon(Icons.camera_alt_outlined, color: AC.sb(d), size: 28),
              const SizedBox(height: 6),
              Text('Camera', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AC.sb(d))),
            ]),
          ),
        )),
        const SizedBox(width: 12),
        Expanded(child: GestureDetector(
          onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: AC.sage(d).withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AC.sage(d), width: 1.5),
            ),
            child: Column(children: [
              Icon(Icons.photo_library_outlined, color: AC.sb(d), size: 28),
              const SizedBox(height: 6),
              Text('Gallery', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AC.sb(d))),
            ]),
          ),
        )),
      ]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Text('Cancel',
            style: TextStyle(
                fontSize: 14, color: AC.lt(d), fontWeight: FontWeight.w500)),
      ),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _Stp helper class  (keep this — same as before)
// ─────────────────────────────────────────────────────────────────────────────
class _Stp {
  final String n, i, t, d;
  final Color?  c;
  const _Stp(this.n, this.i, this.t, this.d, this.c);
}

// ─────────────────────────────────────────────────────────────────────────────
// REPORT SCREEN  ← OVERFLOW FIX (LayoutBuilder + fixed-height sections)
// ─────────────────────────────────────────────────────────────────────────────
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override State<ReportScreen> createState() => _ReportS();
}

class _ReportS extends State<ReportScreen> {
  LatLng?         _loc;
  bool            _locating = true;
  String          _locErr   = '';
  double          _radius   = 10.0;
  List<OrgPin>    _orgs     = [];
  bool            _fetching = false;
  OrgPin?         _sel;
  MapFilter       _filter   = MapFilter.all;
  final _sc   = TextEditingController();
  bool            _showS    = false;
  bool            _searching = false;
  List<OrgPin>    _sRes     = [];
  List<String>    _hist     = [];
  List<String>    _sugg     = [];

  @override
  void initState() {
   super.initState();
   ScreenSecurity.enableSecureMode();
   _init();
  }

  @override
  void dispose() {
   ScreenSecurity.disableSecureMode();
   _sc.dispose();
   super.dispose();
  }

  Future<void> _init() async {
    final h = await St.hist();
    setState(() => _hist = h);
    await _getLoc();
  }

  Future<void> _getLoc() async {
    setState(() { _locating = true; _locErr = ''; });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() { _locating = false; _locErr = 'Location services disabled.'; });
        return;
      }
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        setState(() { _locating = false; _locErr = 'Location permission denied.'; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() { _loc = LatLng(pos.latitude, pos.longitude); _locating = false; });
      await _fetchOrgs();
    } catch (e) {
      setState(() { _locating = false; _locErr = 'Could not get location: $e'; });
    }
  }

  Future<void> _fetchOrgs() async {
    if (_loc == null) return;
    setState(() => _fetching = true);
    final o = await fetchOrgs(_loc!, _radius, _filter);
    setState(() { _orgs = o; _fetching = false; });
  }

  Future<void> _onQ(String q) async {
    if (q.trim().length < 2) { setState(() => _sugg = []); return; }
    final s = await suggest(q);
    setState(() => _sugg = s);
  }

  Future<void> _doSearch(String q) async {
    if (q.trim().isEmpty) return;
    _sc.text = q;
    FocusScope.of(context).unfocus();
    await St.addHist(q);
    final h = await St.hist();
    setState(() { _searching = true; _hist = h; _sugg = []; });
    final r = await searchNom(q, _loc);
    setState(() { _sRes = r; _searching = false; });
  }

  Future<void> _email(OrgPin o) async {
    final sub  = Uri.encodeComponent('Animal Report - ALAG-AP');
    final body = Uri.encodeComponent(
      'Hello,\n\nReporting a stray animal at (${_loc?.latitude.toStringAsFixed(5)}, ${_loc?.longitude.toStringAsFixed(5)}).\n\nVia ALAG-AP.\n\nThank you.',
    );
    final u = Uri.parse('mailto:?subject=$sub&body=$body');
    if (await canLaunchUrl(u)) await launchUrl(u);
    else _snack('Could not open email.');
  }

  Future<void> _sms(OrgPin o) async {
    final body = Uri.encodeComponent(
      'Hi! Found stray animal near ${_loc?.latitude.toStringAsFixed(5)},${_loc?.longitude.toStringAsFixed(5)}. Via ALAG-AP.',
    );
    final u = Uri.parse('sms:${o.phone ?? ''}?body=$body');
    if (await canLaunchUrl(u)) await launchUrl(u);
    else _snack('SMS not supported on web.');
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _sheet(OrgPin o) {
    setState(() => _sel = o);
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (_) => _OrgSheet(
        org: o, d: dark(context),
        onEmail: () { Navigator.pop(context); _email(o); },
        onSMS:   () { Navigator.pop(context); _sms(o);   },
        onWeb:   o.website != null ? () { Navigator.pop(context); launchUrl(Uri.parse(o.website!), mode: LaunchMode.externalApplication); } : null,
      ),
    );
  }

  List<OrgPin> get _disp => _showS && _sRes.isNotEmpty ? _sRes : _orgs;

  @override
  Widget build(BuildContext ctx) {
    final arg = ModalRoute.of(ctx)?.settings.arguments as ImageArg?;
    final d   = dark(ctx);
    final sb  = AC.sb(d);
    final lt  = AC.lt(d);

    // ── Fixed-height sections ─────────────────────────────────────────────────
    const double kHeaderH  = 50.0;
    const double kRadiusH  = 44.0;
    const double kFilterH  = 50.0;
    const double kOrgListH = 185.0;
    final double kSearchH  = _showS
        ? (_sugg.isNotEmpty || _hist.isNotEmpty ? 162.0 : 106.0)
        : 0.0;
    final double kPhotoH   = (arg != null && arg.has) ? 80.0 : 0.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: gbg(d),
        child: SafeArea(child: LayoutBuilder(builder: (ctx2, cons) {
          final availH = cons.maxHeight;
          final usedH  = kHeaderH + kSearchH + kPhotoH + kRadiusH + kFilterH + kOrgListH;
          final mapH   = (availH - usedH).clamp(80.0, double.infinity);

          return Column(children: [

            // ── HEADER ──────────────────────────────────────────────────────
            SizedBox(height: kHeaderH, child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(children: [
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded), color: sb,
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                Text('Report Animal', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: sb)),
                const Spacer(),
                IconButton(
                  icon: Icon(_showS ? Icons.close : Icons.search, color: sb),
                  padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                  onPressed: () => setState(() {
                    _showS = !_showS;
                    if (!_showS) { _sRes = []; _sc.clear(); _sugg = []; }
                  }),
                ),
              ]),
            )),

            // ── SEARCH BAR ───────────────────────────────────────────────
            if (_showS) SizedBox(height: kSearchH, child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                  controller: _sc,
                  style: TextStyle(color: AC.mt(d), fontSize: 13),
                  onChanged: _onQ,
                  onSubmitted: _doSearch,
                  decoration: InputDecoration(
                    hintText: 'Search shelters, vets, barangay...',
                    hintStyle: TextStyle(color: lt, fontSize: 12),
                    prefixIcon: Icon(Icons.search, color: lt, size: 18),
                    suffixIcon: _searching
                        ? Padding(padding: const EdgeInsets.all(10),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AC.peach(d))))
                        : null,
                    filled: true, fillColor: AC.card(d),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                SizedBox(height: 50, child: _sugg.isNotEmpty
                    ? ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _sugg.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) => GestureDetector(
                          onTap: () => _doSearch(_sugg[i]),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AC.sky(d).withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.location_on, size: 12, color: sb),
                              const SizedBox(width: 4),
                              Text(_sugg[i], style: TextStyle(fontSize: 11, color: sb)),
                            ]),
                          ),
                        ),
                      )
                    : (_hist.isNotEmpty && _sRes.isEmpty)
                        ? ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _hist.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 6),
                            itemBuilder: (_, i) => GestureDetector(
                              onTap: () => _doSearch(_hist[i]),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AC.blush(d).withOpacity(0.4), borderRadius: BorderRadius.circular(20)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.history, size: 12, color: sb),
                                  const SizedBox(width: 4),
                                  Text(_hist[i], style: TextStyle(fontSize: 11, color: sb)),
                                ]),
                              ),
                            ),
                          )
                        : const SizedBox.shrink()),
              ]),
            )),

            // ── PHOTO STRIP ──────────────────────────────────────────────
            if (arg != null && arg.has)
              SizedBox(height: kPhotoH, child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: ClipRRect(borderRadius: BorderRadius.circular(12), child: bImg(arg)),
              )),

            // ── RADIUS SLIDER ────────────────────────────────────────────
            SizedBox(height: kRadiusH, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Text('Radius:', style: TextStyle(fontSize: 11, color: lt)),
                const SizedBox(width: 6),
                Expanded(child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    value: _radius, min: 10, max: 100, divisions: 9,
                    activeColor: AC.peach(d), inactiveColor: AC.blush(d).withOpacity(0.4),
                    onChanged: (v) => setState(() => _radius = v),
                    onChangeEnd: (_) => _fetchOrgs(),
                  ),
                )),
                Text('${_radius.toInt()} km', style: TextStyle(fontSize: 11, color: lt, fontWeight: FontWeight.bold)),
                if (_fetching) Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AC.peach(d))),
                ),
              ]),
            )),

            // ── FILTER CHIPS ─────────────────────────────────────────────
            SizedBox(height: kFilterH, child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              itemCount: MapFilter.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final f   = MapFilter.values[i];
                final sel = _filter == f;
                return GestureDetector(
                  onTap: () { setState(() => _filter = f); _fetchOrgs(); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel ? AC.peach(d) : AC.card(d),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? AC.peach(d) : AC.blush(d), width: 1.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(f.emoji, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(f.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Colors.white : sb)),
                    ]),
                  ),
                );
              },
            )),

            // ── MAP ──────────────────────────────────────────────────────
            SizedBox(height: mapH, child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _locating ? _lw(d) : _locErr.isNotEmpty ? _ew(d)
                    : FlutterMap(
                        options: MapOptions(
                          initialCenter: _loc!,
                          initialZoom: 14 - math.log(_radius / 10) / math.log(2),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                            subdomains: const ['a','b','c','d'],
                            userAgentPackageName: 'com.alagap.app',
                            maxZoom: 20,
                          ),
                          RichAttributionWidget(animationConfig: const ScaleRAWA(), attributions: [
                            TextSourceAttribution('© OpenStreetMap contributors',
                              onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright'), mode: LaunchMode.externalApplication)),
                            TextSourceAttribution('© CARTO',
                              onTap: () => launchUrl(Uri.parse('https://carto.com/attributions'), mode: LaunchMode.externalApplication)),
                          ]),
                          MarkerLayer(markers: [
                            Marker(point: _loc!, width: 40, height: 40, child: Container(
                              decoration: BoxDecoration(
                                color: AC.peach(d), shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [BoxShadow(color: AC.peach(d).withOpacity(0.5), blurRadius: 10)],
                              ),
                              child: const Icon(Icons.person_pin_rounded, color: Colors.white, size: 20),
                            )),
                            ..._disp.map((o) => Marker(
                              point: o.pos, width: 46, height: 46,
                              child: GestureDetector(
                                onTap: () => _sheet(o),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: _sel == o ? AC.sb(d) : o.type.pc(d),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: _sel == o ? Colors.white : AC.peach(d), width: 2),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
                                  ),
                                  child: Center(child: Text(o.type.emoji, style: const TextStyle(fontSize: 20))),
                                ),
                              ),
                            )),
                          ]),
                        ],
                      ),
              ),
            )),

            // ── ORG LIST (strictly bounded, no overflow) ─────────────────
            SizedBox(
              height: kOrgListH,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
                    child: Text(
                      _showS && _sRes.isNotEmpty
                          ? 'Search Results'
                          : 'Nearby (${_disp.length})',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: sb),
                    ),
                  ),
                  Expanded(
                    child: _locating
                        ? const SizedBox()
                        : _disp.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'No organizations found. Try increasing radius or changing filter.',
                                    style: TextStyle(fontSize: 11, color: lt),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                scrollDirection: Axis.horizontal,
                                itemCount: _disp.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 8),
                                itemBuilder: (_, i) {
                                  final o   = _disp[i];
                                  final sel = _sel == o;
                                  return GestureDetector(
                                    onTap: () => _sheet(o),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 112,
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? o.type.pc(d).withOpacity(0.9)
                                            : o.type.pc(d).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(13),
                                        border: Border.all(
                                          color: sel ? AC.sb(d).withOpacity(0.5) : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(o.type.emoji, style: const TextStyle(fontSize: 18)),
                                          const SizedBox(height: 3),
                                          Text(o.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: sb)),
                                          Text(o.type.label,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 9, color: lt)),
                                          Text(o.dist, style: TextStyle(fontSize: 9, color: lt)),
                                          const SizedBox(height: 3),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(8)),
                                            child: Text('Contact',
                                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: sb)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),

          ]); // end Column
        })),
      ),
    );
  }

  Widget _lw(bool d) => Container(
    color: AC.sky(d).withOpacity(0.2),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(color: AC.peach(d)),
      const SizedBox(height: 12),
      Text('Getting your location...', style: TextStyle(color: AC.mt(d))),
    ])),
  );

  Widget _ew(bool d) => Container(
    color: AC.blush(d).withOpacity(0.3),
    child: Center(child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('📍', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(_locErr, textAlign: TextAlign.center, style: TextStyle(color: AC.mt(d))),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _getLoc,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: AC.peach(d), borderRadius: BorderRadius.circular(20)),
            child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    )),
  );
}

// Org bottom sheet
class _OrgSheet extends StatelessWidget {
  final OrgPin     org;
  final bool       d;
  final VoidCallback onEmail, onSMS;
  final VoidCallback? onWeb;
  const _OrgSheet({required this.org, required this.d, required this.onEmail, required this.onSMS, this.onWeb});

  @override
  Widget build(BuildContext ctx) {
    final sb = AC.sb(d);
    final lt = AC.lt(d);
    final mt = AC.mt(d);
    return Container(
      margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AC.card(d), borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 20),
        Row(children: [
          Container(width: 56, height: 56,
            decoration: BoxDecoration(color: org.type.pc(d), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(org.type.emoji, style: const TextStyle(fontSize: 28)))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(org.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: sb), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text(org.type.label, style: TextStyle(fontSize: 13, color: lt)),
            Text('📍 ${org.dist} away', style: TextStyle(fontSize: 12, color: lt)),
            if (org.phone != null) Text('📞 ${org.phone}', style: TextStyle(fontSize: 11, color: mt)),
          ])),
        ]),
        const SizedBox(height: 20),
        Text('Send animal report via:', style: TextStyle(fontSize: 14, color: mt, fontWeight: FontWeight.w500)),
        const SizedBox(height: 14),
        IntrinsicHeight(child: Row(children: [
          Expanded(child: _CBtn(icon: Icons.email_rounded,    label: 'Email',   col: AC.sky(d),  d: d, t: onEmail)),
          const SizedBox(width: 10),
          Expanded(child: _CBtn(icon: Icons.sms_rounded,     label: 'SMS',     col: AC.sage(d), d: d, t: onSMS)),
          if (onWeb != null) ...[
            const SizedBox(width: 10),
            Expanded(child: _CBtn(icon: Icons.language_rounded, label: 'Website', col: AC.lav(d),  d: d, t: onWeb!)),
          ],
        ])),
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _CBtn extends StatelessWidget {
  final IconData icon; final String label; final Color col; final bool d; final VoidCallback t;
  const _CBtn({required this.icon, required this.label, required this.col, required this.d, required this.t});
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: t,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: col.withOpacity(0.35), borderRadius: BorderRadius.circular(16), border: Border.all(color: col, width: 1.5)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: AC.sb(d), size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: AC.sb(d), fontSize: 12), textAlign: TextAlign.center),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SMALL SHARED WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _AC extends StatefulWidget {
  final String emoji, label, sub;
  final Color  color;
  final VoidCallback onTap;
  const _AC({required this.emoji, required this.label, required this.sub, required this.color, required this.onTap});
  @override State<_AC> createState() => _ACS();
}

class _ACS extends State<_AC> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double>   _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _s = Tween(begin: 1.0, end: .95).animate(_c);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext ctx) {
    final d = dark(ctx);
    return GestureDetector(
      onTapDown:   (_) => _c.forward(),
      onTapUp:     (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: ()  => _c.reverse(),
      child: ScaleTransition(scale: _s, child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: widget.color, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(widget.label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AC.sb(d))),
          const SizedBox(height: 3),
          Text(widget.sub,   style: TextStyle(fontSize: 11, color: AC.mt(d))),
        ]),
      )),
    );
  }
}

class _HC extends StatelessWidget {
  final String emoji, title, desc;
  final Color  color;
  final bool   d;
  const _HC({required this.emoji, required this.title, required this.desc, required this.color, required this.d});
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Text(emoji, style: const TextStyle(fontSize: 26)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: AC.sb(d), fontSize: 14)),
        const SizedBox(height: 2),
        Text(desc,  style: TextStyle(fontSize: 11, color: AC.mt(d))),
      ])),
    ]),
  );
}

class _AbBtn extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _AbBtn({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext ctx) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: color.withOpacity(0.4), borderRadius: BorderRadius.circular(14), border: Border.all(color: color, width: 1.5)),
      child: Column(children: [
        Icon(icon,  color: AC.sb(false), size: 26),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AC.sb(false))),
      ]),
    ),
  );
}

class _SC extends StatelessWidget {
  final String label, val, emoji;
  final Color  col;
  final bool   d;
  const _SC({required this.label, required this.val, required this.emoji, required this.col, required this.d});
  @override
  Widget build(BuildContext ctx) => Container(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
    decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(16)),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 26)),
      const SizedBox(height: 6),
      Text(val,   style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AC.sb(d))),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontSize: 11, color: AC.lt(d))),
    ]),
  );
}