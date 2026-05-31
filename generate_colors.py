import re

properties = [
    ("paper", 0xFFFBF8F2, 0xFF14110D),
    ("paper2", 0xFFF5F0E5, 0xFF1C1814),
    ("mist", 0xFFEFE9DF, 0xFF221E18),
    ("hairline", 0xFFE8E1D4, 0xFF2B2620),
    ("hairline2", 0xFFD9CFBC, 0xFF3A332B),
    ("ink", 0xFF1F1B16, 0xFFF4EFE6),
    ("ink2", 0xFF3A332C, 0xFFF4EFE6), # approximation
    ("slate", 0xFF6B6258, 0xFFA89E91),
    ("slate2", 0xFF9A9085, 0xFF76705F),
    
    ("plum", 0xFF6B4FC7, 0xFF9B7BFF),
    ("plum2", 0xFF5A3FB0, 0xFFB299FF),
    ("plum3", 0xFF432D8A, 0xFF9B7BFF), # approximation
    ("plumTint", 0xFFEFEAFB, 0xFF1F1838),
    ("plumTint2", 0xFFDDD1F6, 0xFF2E2455),
    
    ("sky", 0xFF4F8EFF, 0xFF4F8EFF),
    ("skyTint", 0xFFECF2FF, 0xFF161E2D),
    ("mint", 0xFF3DCB89, 0xFF3DCB89),
    ("mint2", 0xFF2DB174, 0xFF2DB174),
    ("mintTint", 0xFFEAF8F1, 0xFF142319),
    ("coral", 0xFFFF8062, 0xFFFF8062),
    ("coralTint", 0xFFFFF1EC, 0xFF2A1B14),
    ("butter", 0xFFF7C948, 0xFFF7C948),
    ("butterTint", 0xFFFEF7E2, 0xFF2A2210),
    ("tomato", 0xFFE5484D, 0xFFE5484D),
    ("tomatoTint", 0xFFFCEDEE, 0xFF2C1517),
    
    ("bgElev", 0xFFFFFFFF, 0xFF1A1612),
    
    ("bitcoin", 0xFFF7931A, 0xFFF7931A),
    ("bitcoin2", 0xFFE07B00, 0xFFE07B00),
    ("bitcoin3", 0xFFB45F00, 0xFFB45F00),
    ("bitcoinTint", 0xFFFDF0DD, 0xFF2A2210), # approximation dark tint
    ("bitcoinTint2", 0xFFF6D9AE, 0xFF3A2B15), # approximation dark tint
    
    ("nostr", 0xFF8E30EB, 0xFF8E30EB),
    ("nostr2", 0xFF7222C7, 0xFF7222C7),
    ("nostr3", 0xFF5A1AA0, 0xFF5A1AA0),
    ("nostrTint", 0xFFF2E8FD, 0xFF1F1838),
    ("nostrTint2", 0xFFDDC4F8, 0xFF2E2455),
    
    ("night", 0xFF15110C, 0xFF15110C),
    ("night2", 0xFF211A12, 0xFF211A12),
]

out = "import 'package:flutter/material.dart';\n\n"
out += "class SemanticColors extends ThemeExtension<SemanticColors> {\n"
for name, _, _ in properties:
    out += f"  final Color {name};\n"

out += "\n  const SemanticColors({\n"
for name, _, _ in properties:
    out += f"    required this.{name},\n"
out += "  });\n\n"

out += "  @override\n"
out += "  SemanticColors copyWith({\n"
for name, _, _ in properties:
    out += f"    Color? {name},\n"
out += "  }) {\n"
out += "    return SemanticColors(\n"
for name, _, _ in properties:
    out += f"      {name}: {name} ?? this.{name},\n"
out += "    );\n  }\n\n"

out += "  @override\n"
out += "  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {\n"
out += "    if (other is! SemanticColors) {\n"
out += "      return this;\n"
out += "    }\n"
out += "    return SemanticColors(\n"
for name, _, _ in properties:
    out += f"      {name}: Color.lerp({name}, other.{name}, t)!,\n"
out += "    );\n  }\n\n"

out += "  static const light = SemanticColors(\n"
for name, l, _ in properties:
    out += f"    {name}: Color(0x{l:08X}),\n"
out += "  );\n\n"

out += "  static const dark = SemanticColors(\n"
for name, _, d in properties:
    out += f"    {name}: Color(0x{d:08X}),\n"
out += "  );\n"
out += "}\n"

with open("lib/theme/semantic_colors.dart", "w") as f:
    f.write(out)

