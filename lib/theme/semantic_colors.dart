import 'package:flutter/material.dart';

class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color transparent;
  final Color white;
  final Color black;
  final Color positive;
  final Color bitcoinDark;
  final Color paper;
  final Color paper2;
  final Color paper3;
  final Color paper4;
  final Color mist;
  final Color hairline;
  final Color hairline2;
  final Color ink;
  final Color ink2;
  final Color slate;
  final Color slate2;
  final Color plum;
  final Color plum2;
  final Color plum3;
  final Color plumTint;
  final Color plumTint2;
  final Color sky;
  final Color skyTint;
  final Color mint;
  final Color mint2;
  final Color mintTint;
  final Color coral;
  final Color coralTint;
  final Color butter;
  final Color butterTint;
  final Color tomato;
  final Color tomatoTint;
  final Color bgElev;
  final Color bitcoin;
  final Color bitcoin2;
  final Color bitcoin3;
  final Color bitcoinSoft;
  final Color bitcoinTint;
  final Color bitcoinTint2;
  final Color nostr;
  final Color nostr2;
  final Color nostr3;
  final Color nostrTint;
  final Color nostrTint2;
  final Color night;
  final Color night2;

  const SemanticColors({
    required this.transparent,
    required this.white,
    required this.black,
    required this.positive,
    required this.bitcoinDark,
    required this.paper,
    required this.paper2,
    required this.paper3,
    required this.paper4,
    required this.mist,
    required this.hairline,
    required this.hairline2,
    required this.ink,
    required this.ink2,
    required this.slate,
    required this.slate2,
    required this.plum,
    required this.plum2,
    required this.plum3,
    required this.plumTint,
    required this.plumTint2,
    required this.sky,
    required this.skyTint,
    required this.mint,
    required this.mint2,
    required this.mintTint,
    required this.coral,
    required this.coralTint,
    required this.butter,
    required this.butterTint,
    required this.tomato,
    required this.tomatoTint,
    required this.bgElev,
    required this.bitcoin,
    required this.bitcoin2,
    required this.bitcoin3,
    required this.bitcoinSoft,
    required this.bitcoinTint,
    required this.bitcoinTint2,
    required this.nostr,
    required this.nostr2,
    required this.nostr3,
    required this.nostrTint,
    required this.nostrTint2,
    required this.night,
    required this.night2,
  });

  @override
  SemanticColors copyWith({
    Color? transparent,
    Color? white,
    Color? black,
    Color? positive,
    Color? bitcoinDark,
    Color? paper,
    Color? paper2,
    Color? paper3,
    Color? paper4,
    Color? mist,
    Color? hairline,
    Color? hairline2,
    Color? ink,
    Color? ink2,
    Color? slate,
    Color? slate2,
    Color? plum,
    Color? plum2,
    Color? plum3,
    Color? plumTint,
    Color? plumTint2,
    Color? sky,
    Color? skyTint,
    Color? mint,
    Color? mint2,
    Color? mintTint,
    Color? coral,
    Color? coralTint,
    Color? butter,
    Color? butterTint,
    Color? tomato,
    Color? tomatoTint,
    Color? bgElev,
    Color? bitcoin,
    Color? bitcoin2,
    Color? bitcoin3,
    Color? bitcoinSoft,
    Color? bitcoinTint,
    Color? bitcoinTint2,
    Color? nostr,
    Color? nostr2,
    Color? nostr3,
    Color? nostrTint,
    Color? nostrTint2,
    Color? night,
    Color? night2,
  }) {
    return SemanticColors(
      transparent: transparent ?? this.transparent,
      white: white ?? this.white,
      black: black ?? this.black,
      positive: positive ?? this.positive,
      bitcoinDark: bitcoinDark ?? this.bitcoinDark,
      paper: paper ?? this.paper,
      paper2: paper2 ?? this.paper2,
      paper3: paper3 ?? this.paper3,
      paper4: paper4 ?? this.paper4,
      mist: mist ?? this.mist,
      hairline: hairline ?? this.hairline,
      hairline2: hairline2 ?? this.hairline2,
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      slate: slate ?? this.slate,
      slate2: slate2 ?? this.slate2,
      plum: plum ?? this.plum,
      plum2: plum2 ?? this.plum2,
      plum3: plum3 ?? this.plum3,
      plumTint: plumTint ?? this.plumTint,
      plumTint2: plumTint2 ?? this.plumTint2,
      sky: sky ?? this.sky,
      skyTint: skyTint ?? this.skyTint,
      mint: mint ?? this.mint,
      mint2: mint2 ?? this.mint2,
      mintTint: mintTint ?? this.mintTint,
      coral: coral ?? this.coral,
      coralTint: coralTint ?? this.coralTint,
      butter: butter ?? this.butter,
      butterTint: butterTint ?? this.butterTint,
      tomato: tomato ?? this.tomato,
      tomatoTint: tomatoTint ?? this.tomatoTint,
      bgElev: bgElev ?? this.bgElev,
      bitcoin: bitcoin ?? this.bitcoin,
      bitcoin2: bitcoin2 ?? this.bitcoin2,
      bitcoin3: bitcoin3 ?? this.bitcoin3,
      bitcoinSoft: bitcoinSoft ?? this.bitcoinSoft,
      bitcoinTint: bitcoinTint ?? this.bitcoinTint,
      bitcoinTint2: bitcoinTint2 ?? this.bitcoinTint2,
      nostr: nostr ?? this.nostr,
      nostr2: nostr2 ?? this.nostr2,
      nostr3: nostr3 ?? this.nostr3,
      nostrTint: nostrTint ?? this.nostrTint,
      nostrTint2: nostrTint2 ?? this.nostrTint2,
      night: night ?? this.night,
      night2: night2 ?? this.night2,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) {
      return this;
    }
    return SemanticColors(
      transparent: Color.lerp(transparent, other.transparent, t)!,
      white: Color.lerp(white, other.white, t)!,
      black: Color.lerp(black, other.black, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      bitcoinDark: Color.lerp(bitcoinDark, other.bitcoinDark, t)!,
      paper: Color.lerp(paper, other.paper, t)!,
      paper2: Color.lerp(paper2, other.paper2, t)!,
      paper3: Color.lerp(paper3, other.paper3, t)!,
      paper4: Color.lerp(paper4, other.paper4, t)!,
      mist: Color.lerp(mist, other.mist, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      hairline2: Color.lerp(hairline2, other.hairline2, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      slate: Color.lerp(slate, other.slate, t)!,
      slate2: Color.lerp(slate2, other.slate2, t)!,
      plum: Color.lerp(plum, other.plum, t)!,
      plum2: Color.lerp(plum2, other.plum2, t)!,
      plum3: Color.lerp(plum3, other.plum3, t)!,
      plumTint: Color.lerp(plumTint, other.plumTint, t)!,
      plumTint2: Color.lerp(plumTint2, other.plumTint2, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      skyTint: Color.lerp(skyTint, other.skyTint, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      mint2: Color.lerp(mint2, other.mint2, t)!,
      mintTint: Color.lerp(mintTint, other.mintTint, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      coralTint: Color.lerp(coralTint, other.coralTint, t)!,
      butter: Color.lerp(butter, other.butter, t)!,
      butterTint: Color.lerp(butterTint, other.butterTint, t)!,
      tomato: Color.lerp(tomato, other.tomato, t)!,
      tomatoTint: Color.lerp(tomatoTint, other.tomatoTint, t)!,
      bgElev: Color.lerp(bgElev, other.bgElev, t)!,
      bitcoin: Color.lerp(bitcoin, other.bitcoin, t)!,
      bitcoin2: Color.lerp(bitcoin2, other.bitcoin2, t)!,
      bitcoin3: Color.lerp(bitcoin3, other.bitcoin3, t)!,
      bitcoinSoft: Color.lerp(bitcoinSoft, other.bitcoinSoft, t)!,
      bitcoinTint: Color.lerp(bitcoinTint, other.bitcoinTint, t)!,
      bitcoinTint2: Color.lerp(bitcoinTint2, other.bitcoinTint2, t)!,
      nostr: Color.lerp(nostr, other.nostr, t)!,
      nostr2: Color.lerp(nostr2, other.nostr2, t)!,
      nostr3: Color.lerp(nostr3, other.nostr3, t)!,
      nostrTint: Color.lerp(nostrTint, other.nostrTint, t)!,
      nostrTint2: Color.lerp(nostrTint2, other.nostrTint2, t)!,
      night: Color.lerp(night, other.night, t)!,
      night2: Color.lerp(night2, other.night2, t)!,
    );
  }

  static const light = SemanticColors(
    transparent: Colors.transparent,
    white: Colors.white,
    black: Colors.black,
    positive: Color(0xFF5BD79B),
    bitcoinDark: Color(0xFF241500),
    paper: Color(0xFFFBF8F2),
    paper2: Color(0xFFF5F0E5),
    paper3: Color(0xFFEFE9DF),
    paper4: Color(0xFFE8E1D4),
    mist: Color(0xFFEFE9DF),
    hairline: Color(0xFFE8E1D4),
    hairline2: Color(0xFFD9CFBC),
    ink: Color(0xFF1F1B16),
    ink2: Color(0xFF3A332C),
    slate: Color(0xFF6B6258),
    slate2: Color(0xFF9A9085),
    plum: Color(0xFF6B4FC7),
    plum2: Color(0xFF5A3FB0),
    plum3: Color(0xFF432D8A),
    plumTint: Color(0xFFEFEAFB),
    plumTint2: Color(0xFFDDD1F6),
    sky: Color(0xFF4F8EFF),
    skyTint: Color(0xFFECF2FF),
    mint: Color(0xFF3DCB89),
    mint2: Color(0xFF2DB174),
    mintTint: Color(0xFFEAF8F1),
    coral: Color(0xFFFF8062),
    coralTint: Color(0xFFFFF1EC),
    butter: Color(0xFFF7C948),
    butterTint: Color(0xFFFEF7E2),
    tomato: Color(0xFFE5484D),
    tomatoTint: Color(0xFFFCEDEE),
    bgElev: Color(0xFFFFFFFF),
    bitcoin: Color(0xFFF7931A),
    bitcoin2: Color(0xFFE07B00),
    bitcoin3: Color(0xFFB45F00),
    bitcoinSoft: Color(0xFFFFB867),
    bitcoinTint: Color(0xFFFDF0DD),
    bitcoinTint2: Color(0xFFF6D9AE),
    nostr: Color(0xFF8E30EB),
    nostr2: Color(0xFF7222C7),
    nostr3: Color(0xFF5A1AA0),
    nostrTint: Color(0xFFF2E8FD),
    nostrTint2: Color(0xFFDDC4F8),
    night: Color(0xFF15110C),
    night2: Color(0xFF211A12),
  );

  static const dark = SemanticColors(
    transparent: Colors.transparent,
    white: Colors.white,
    black: Colors.black,
    positive: Color(0xFF5BD79B),
    bitcoinDark: Color(0xFF241500),
    paper: Color(0xFF14110D),
    paper2: Color(0xFF1C1814),
    paper3: Color(0xFF29221A),
    paper4: Color(0xFF342B20),
    mist: Color(0xFF221E18),
    hairline: Color(0xFF2B2620),
    hairline2: Color(0xFF3A332B),
    ink: Color(0xFFF4EFE6),
    ink2: Color(0xFFF4EFE6),
    slate: Color(0xFFA89E91),
    slate2: Color(0xFF76705F),
    plum: Color(0xFF9B7BFF),
    plum2: Color(0xFFB299FF),
    plum3: Color(0xFF9B7BFF),
    plumTint: Color(0xFF1F1838),
    plumTint2: Color(0xFF2E2455),
    sky: Color(0xFF4F8EFF),
    skyTint: Color(0xFF161E2D),
    mint: Color(0xFF3DCB89),
    mint2: Color(0xFF2DB174),
    mintTint: Color(0xFF142319),
    coral: Color(0xFFFF8062),
    coralTint: Color(0xFF2A1B14),
    butter: Color(0xFFF7C948),
    butterTint: Color(0xFF2A2210),
    tomato: Color(0xFFE5484D),
    tomatoTint: Color(0xFF2C1517),
    bgElev: Color(0xFF1A1612),
    bitcoin: Color(0xFFF7931A),
    bitcoin2: Color(0xFFE07B00),
    bitcoin3: Color(0xFFB45F00),
    bitcoinSoft: Color(0xFFFFB867),
    bitcoinTint: Color(0xFF2A2210),
    bitcoinTint2: Color(0xFF3A2B15),
    nostr: Color(0xFF8E30EB),
    nostr2: Color(0xFF7222C7),
    nostr3: Color(0xFF5A1AA0),
    nostrTint: Color(0xFF1F1838),
    nostrTint2: Color(0xFF2E2455),
    night: Color(0xFF15110C),
    night2: Color(0xFF211A12),
  );
}
