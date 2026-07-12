import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zapbook/theme/semantic_colors.dart';

void main() {
  group('SemanticColors', () {
    test('copyWith creates new instance with updated values', () {
      const original = SemanticColors.light;
      final updated = original.copyWith(
        transparent: Colors.red,
        white: Colors.blue,
        black: Colors.green,
        positive: Colors.yellow,
        bitcoinDark: Colors.purple,
        paper: Colors.orange,
        paper2: Colors.pink,
        paper3: Colors.teal,
        paper4: Colors.cyan,
        mist: Colors.brown,
        hairline: Colors.indigo,
        hairline2: Colors.lime,
        ink: Colors.amber,
        ink2: Colors.grey,
        slate: Colors.blueGrey,
        slate2: Colors.lightBlue,
        plum: Colors.lightGreen,
        plum2: Colors.deepOrange,
        plum3: Colors.deepPurple,
        plumTint: Colors.redAccent,
        plumTint2: Colors.blueAccent,
        sky: Colors.greenAccent,
        skyTint: Colors.yellowAccent,
        mint: Colors.purpleAccent,
        mint2: Colors.orangeAccent,
        mintTint: Colors.pinkAccent,
        coral: Colors.tealAccent,
        coralTint: Colors.cyanAccent,
        butter: Colors.limeAccent,
        butterTint: Colors.amberAccent,
        tomato: Colors.indigoAccent,
        tomatoTint: Colors.lightBlueAccent,
        bgElev: Colors.lightGreenAccent,
        bitcoin: Colors.deepOrangeAccent,
        bitcoin2: Colors.deepPurpleAccent,
        bitcoin3: Colors.black12,
        bitcoinSoft: Colors.black26,
        bitcoinTint: Colors.black38,
        bitcoinTint2: Colors.black45,
        nostr: Colors.black54,
        nostr2: Colors.black87,
        nostr3: Colors.white10,
        nostrTint: Colors.white12,
        nostrTint2: Colors.white24,
        night: Colors.white30,
        night2: Colors.white38,
      );

      expect(updated.transparent, Colors.red);
      expect(updated.white, Colors.blue);
      expect(updated.black, Colors.green);
      expect(updated.positive, Colors.yellow);
      expect(updated.bitcoinDark, Colors.purple);
      expect(updated.paper, Colors.orange);
      expect(updated.paper2, Colors.pink);
      expect(updated.paper3, Colors.teal);
      expect(updated.paper4, Colors.cyan);
      expect(updated.mist, Colors.brown);
      expect(updated.hairline, Colors.indigo);
      expect(updated.hairline2, Colors.lime);
      expect(updated.ink, Colors.amber);
      expect(updated.ink2, Colors.grey);
      expect(updated.slate, Colors.blueGrey);
      expect(updated.slate2, Colors.lightBlue);
      expect(updated.plum, Colors.lightGreen);
      expect(updated.plum2, Colors.deepOrange);
      expect(updated.plum3, Colors.deepPurple);
      expect(updated.plumTint, Colors.redAccent);
      expect(updated.plumTint2, Colors.blueAccent);
      expect(updated.sky, Colors.greenAccent);
      expect(updated.skyTint, Colors.yellowAccent);
      expect(updated.mint, Colors.purpleAccent);
      expect(updated.mint2, Colors.orangeAccent);
      expect(updated.mintTint, Colors.pinkAccent);
      expect(updated.coral, Colors.tealAccent);
      expect(updated.coralTint, Colors.cyanAccent);
      expect(updated.butter, Colors.limeAccent);
      expect(updated.butterTint, Colors.amberAccent);
      expect(updated.tomato, Colors.indigoAccent);
      expect(updated.tomatoTint, Colors.lightBlueAccent);
      expect(updated.bgElev, Colors.lightGreenAccent);
      expect(updated.bitcoin, Colors.deepOrangeAccent);
      expect(updated.bitcoin2, Colors.deepPurpleAccent);
      expect(updated.bitcoin3, Colors.black12);
      expect(updated.bitcoinSoft, Colors.black26);
      expect(updated.bitcoinTint, Colors.black38);
      expect(updated.bitcoinTint2, Colors.black45);
      expect(updated.nostr, Colors.black54);
      expect(updated.nostr2, Colors.black87);
      expect(updated.nostr3, Colors.white10);
      expect(updated.nostrTint, Colors.white12);
      expect(updated.nostrTint2, Colors.white24);
      expect(updated.night, Colors.white30);
      expect(updated.night2, Colors.white38);
    });

    test('copyWith returns identical instance when fields are null', () {
      const original = SemanticColors.light;
      final updated = original.copyWith();

      expect(updated.transparent, original.transparent);
      expect(updated.white, original.white);
      expect(updated.black, original.black);
    });

    test('lerp interpolates between two SemanticColors', () {
      const light = SemanticColors.light;
      const dark = SemanticColors.dark;

      final middle = light.lerp(dark, 0.5);

      expect(
        middle.transparent,
        Color.lerp(light.transparent, dark.transparent, 0.5),
      );
      expect(middle.white, Color.lerp(light.white, dark.white, 0.5));
      expect(middle.paper, Color.lerp(light.paper, dark.paper, 0.5));
      expect(middle.hairline, Color.lerp(light.hairline, dark.hairline, 0.5));
      expect(middle.ink, Color.lerp(light.ink, dark.ink, 0.5));
      expect(middle.sky, Color.lerp(light.sky, dark.sky, 0.5));
      expect(middle.coral, Color.lerp(light.coral, dark.coral, 0.5));
      expect(middle.bitcoin, Color.lerp(light.bitcoin, dark.bitcoin, 0.5));
      expect(middle.nostr, Color.lerp(light.nostr, dark.nostr, 0.5));
    });

    test('lerp with non-SemanticColors returns this', () {
      const light = SemanticColors.light;
      final result = light.lerp(null, 0.5);

      expect(result, same(light));
    });
  });
}
