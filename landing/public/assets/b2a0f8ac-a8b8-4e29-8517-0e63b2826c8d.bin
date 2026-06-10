/* ZapBook — Direction B · "Ember" (Material You lean)
   Tonal dark elevation, big rounded shapes, Material bottom-nav with the
   signature active-pill indicator. Denser, structured. */

// ── Material bottom navigation with active-pill indicator ──
function MNav({ active = 'home' }) {
  const items = [
    { id: 'home', label: 'Home', icon: 'home' },
    { id: 'circles', label: 'Circles', icon: 'circles' },
    { id: 'cheers', label: 'Cheers', icon: 'bell' },
    { id: 'library', label: 'Library', icon: 'book' },
    { id: 'you', label: 'You', icon: 'user' },
  ];
  return (
    <div style={{ flex: 'none', paddingBottom: SAFE_BOT, paddingTop: 10, background: ZB.s2,
      borderTop: `1px solid ${ZB.line}`, display: 'flex', justifyContent: 'space-around' }}>
      {items.map((it) => {
        const on = it.id === active;
        return (
          <div key={it.id} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, width: 62 }}>
            <div style={{ width: 54, height: 30, borderRadius: 999, display: 'grid', placeItems: 'center',
              background: on ? ZB.orangeDim : 'transparent', border: on ? `1px solid ${ZB.orangeLine}` : '1px solid transparent' }}>
              <Icon name={it.icon} size={20} color={on ? ZB.orangeSoft : ZB.t3} sw={on ? 2.1 : 1.85} />
            </div>
            <span style={{ font: `${on ? 600 : 500} 10.5px/1 ${FONT_BODY}`, color: on ? ZB.t1 : ZB.t3 }}>{it.label}</span>
          </div>
        );
      })}
    </div>
  );
}

const eTitle = { font: `700 28px/1.05 ${FONT_DISPLAY}`, letterSpacing: '-0.02em', color: ZB.t1, margin: 0 };
const eCard = { background: ZB.s2, border: `1px solid ${ZB.line}`, borderRadius: 26 };

// ─────────────────── EMBER · HOME / LIBRARY ───────────────────
function EmberHome() {
  return (
    <Screen style={{ background: ZB.bg }}>
      <div style={{ flex: 1, overflow: 'hidden', padding: `${SAFE_TOP + 8}px 20px 8px` }}>
        {/* header */}
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 18 }}>
          <div>
            <div style={{ font: `600 13px/1 ${FONT_BODY}`, letterSpacing: '0.04em', color: ZB.t3, textTransform: 'uppercase', marginBottom: 8 }}>Tuesday evening</div>
            <h1 style={eTitle}>Your shelf</h1>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 7, padding: '8px 12px', borderRadius: 999,
            background: ZB.orangeDim, border: `1px solid ${ZB.orangeLine}` }}>
            <Icon name="flame" size={17} color={ZB.orangeSoft} sw={2.1} />
            <span style={{ font: `700 15px/1 ${FONT_MONO}`, color: ZB.orangeSoft }}>12</span>
          </div>
        </div>

        {/* continue reading hero */}
        <div style={{ ...eCard, padding: 16, display: 'flex', gap: 16, marginBottom: 16 }}>
          <Cover w={86} h={120} hue="orange" title="Alice" author="L. Carroll" slot="cv-alice-hero" img="covers/alice.png" />
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
            <div style={{ font: `600 11px/1 ${FONT_BODY}`, letterSpacing: '0.05em', textTransform: 'uppercase', color: ZB.orangeSoft, marginBottom: 7 }}>Continue</div>
            <div style={{ font: `700 19px/1.15 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>Alice's Adventures in Wonderland</div>
            <div style={{ font: `500 13px/1 ${FONT_BODY}`, color: ZB.t2, marginTop: 6 }}>Ch. 1 · Down the Rabbit-Hole</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginTop: 9 }}>
              <Icon name="circles" size={13} color={ZB.purpleSoft} sw={2} />
              <span style={{ font: `500 11.5px/1 ${FONT_BODY}`, color: ZB.purpleSoft }}>with Mr. Lee's Class · 47 reading</span>
            </div>
            <div style={{ marginTop: 'auto', display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{ flex: 1, height: 8, borderRadius: 999, background: ZB.s4, overflow: 'hidden' }}>
                <div style={{ width: '38%', height: '100%', background: ZB.orange, borderRadius: 999 }} />
              </div>
              <div style={{ width: 44, height: 44, borderRadius: 999, background: ZB.orange, display: 'grid', placeItems: 'center', flex: 'none' }}>
                <Icon name="play" size={19} color="#241500" />
              </div>
            </div>
          </div>
        </div>

        {/* stat tiles */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 10, marginBottom: 20 }}>
          {[
            { v: '12', l: 'day streak', c: ZB.orangeSoft },
            { v: '48k', l: 'sats earned', c: ZB.t1 },
            { v: '6', l: 'books done', c: ZB.purpleSoft },
          ].map((s, i) => (
            <div key={i} style={{ background: ZB.s1, border: `1px solid ${ZB.line}`, borderRadius: 18, padding: '14px 12px' }}>
              <div style={{ font: `700 24px/1 ${FONT_DISPLAY}`, color: s.c, fontVariantNumeric: 'tabular-nums', letterSpacing: '-0.02em' }}>{s.v}</div>
              <div style={{ font: `500 11.5px/1.2 ${FONT_BODY}`, color: ZB.t3, marginTop: 6 }}>{s.l}</div>
            </div>
          ))}
        </div>

        {/* shelf */}
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 14 }}>
          <div style={{ font: `700 17px/1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>Up next</div>
          <div style={{ font: `600 13px/1 ${FONT_BODY}`, color: ZB.orangeSoft }}>Browse</div>
        </div>
        <div style={{ display: 'flex', gap: 14 }}>
          {[
            { t: 'Peter Pan', a: 'J. M. Barrie', h: 'purple', img: 'covers/peterpan.png' },
            { t: 'The Jungle Book', a: 'Kipling', h: 'mint', img: 'covers/jungle.png' },
            { t: 'Treasure Island', a: 'Stevenson', h: 'sky', img: 'covers/treasure.png' },
          ].map((b, i) => (
            <div key={i} style={{ width: 100 }}>
              <Cover w={100} h={140} hue={b.h} title={b.t} author={b.a} slot={`cv-shelf-${i}`} img={b.img} />
            </div>
          ))}
        </div>
      </div>
      <MNav active="home" />
    </Screen>
  );
}

// ─────────────────── EMBER · READING CIRCLE ───────────────────
// A circle = a group (1–100) reading ONE book together. Anyone can zap anyone.
function EmberCircle() {
  const readers = [
    { name: 'Wren', emoji: '🦊', page: 18, total: 24, you: false },
    { name: 'You', emoji: '🌿', page: 9, total: 24, you: true },
    { name: 'Theo', emoji: '🐙', page: 7, total: 24, you: false },
    { name: 'Mei', emoji: '🪐', page: 4, total: 24, you: false },
  ];
  return (
    <Screen style={{ background: ZB.bg }}>
      <div style={{ flex: 1, overflow: 'hidden', padding: `${SAFE_TOP + 8}px 20px 8px` }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 18 }}>
          <div>
            <div style={{ font: `600 13px/1 ${FONT_BODY}`, letterSpacing: '0.04em', color: ZB.purpleSoft, textTransform: 'uppercase', marginBottom: 8 }}>Reading together</div>
            <h1 style={eTitle}>Mr. Lee's Class</h1>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '8px 12px', borderRadius: 999,
            background: ZB.purpleDim, border: `1px solid ${ZB.purpleLine}` }}>
            <Icon name="circles" size={16} color={ZB.purpleSoft} sw={2} />
            <span style={{ font: `700 14px/1 ${FONT_MONO}`, color: ZB.purpleSoft }}>47</span>
          </div>
        </div>

        {/* the shared book */}
        <div style={{ ...eCard, padding: 16, marginBottom: 20, display: 'flex', gap: 15, alignItems: 'center' }}>
          <Cover w={62} h={88} hue="orange" title="Alice" author="Carroll" r={12} slot="cv-alice-circle" img="covers/alice.png" />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ font: `600 11px/1 ${FONT_BODY}`, letterSpacing: '0.05em', textTransform: 'uppercase', color: ZB.purpleSoft, marginBottom: 7 }}>The circle is reading</div>
            <div style={{ font: `700 18px/1.1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>Alice in Wonderland</div>
            <div style={{ font: `500 12.5px/1 ${FONT_BODY}`, color: ZB.t2, marginTop: 7 }}>47 reading · finish by Sunday</div>
          </div>
        </div>

        {/* readers, sorted by progress — anyone can zap anyone */}
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 12 }}>
          <div style={{ font: `700 17px/1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>Readers</div>
          <div style={{ font: `500 12px/1 ${FONT_BODY}`, color: ZB.t3 }}>by progress</div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {readers.map((r, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 13, padding: '11px 12px 11px 14px', borderRadius: 18,
              background: r.you ? ZB.purpleDim : ZB.s1, border: `1px solid ${r.you ? ZB.purpleLine : ZB.line}` }}>
              <Ava emoji={r.emoji} size={40} ring={r.you ? ZB.purpleLine : ZB.line2} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                  <span style={{ font: `700 15.5px/1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>{r.name}</span>
                  {r.you && <span style={{ font: `600 10px/1 ${FONT_BODY}`, color: ZB.purpleSoft, padding: '3px 6px', borderRadius: 999, background: 'rgba(165,107,255,0.16)' }}>YOU</span>}
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 9, marginTop: 8 }}>
                  <div style={{ flex: 1, height: 6, borderRadius: 999, background: ZB.s4, overflow: 'hidden' }}>
                    <div style={{ width: `${(r.page / r.total) * 100}%`, height: '100%', background: r.you ? ZB.purple : ZB.orange, borderRadius: 999 }} />
                  </div>
                  <span style={{ font: `500 11px/1 ${FONT_MONO}`, color: ZB.t3, whiteSpace: 'nowrap' }}>p.{r.page}</span>
                </div>
              </div>
              {/* zap-this-reader button — anyone can zap anyone */}
              {!r.you && (
                <div style={{ width: 42, height: 42, borderRadius: 14, flex: 'none', display: 'grid', placeItems: 'center',
                  background: ZB.orangeDim, border: `1px solid ${ZB.orangeLine}` }}>
                  <Bolt size={19} color={ZB.orangeSoft} />
                </div>
              )}
            </div>
          ))}
        </div>
        <div style={{ textAlign: 'center', font: `500 12.5px/1 ${FONT_BODY}`, color: ZB.t3, marginTop: 14 }}>+ 43 more reading along</div>
      </div>

      <MNav active="circles" />
    </Screen>
  );
}

// ─────────────────── EMBER · READER (Alice) ───────────────────
function EmberReader() {
  return (
    <Screen style={{ background: '#15110B' }}>
      {/* top app bar */}
      <div style={{ flex: 'none', paddingTop: SAFE_TOP, background: ZB.s1, borderBottom: `1px solid ${ZB.line}` }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '12px 18px' }}>
          <Icon name="chevron" size={22} color={ZB.t2} style={{ transform: 'rotate(180deg)' }} />
          <div style={{ flex: 1 }}>
            <div style={{ font: `700 15px/1.1 ${FONT_DISPLAY}`, color: ZB.t1 }}>Down the Rabbit-Hole</div>
            <div style={{ font: `500 11.5px/1 ${FONT_BODY}`, color: ZB.t3, marginTop: 4 }}>Chapter 1 · Alice in Wonderland</div>
          </div>
          <Icon name="bookmark" size={20} color={ZB.orangeSoft} />
        </div>
      </div>

      {/* page */}
      <div style={{ flex: 1, overflow: 'hidden', padding: '26px 26px 0' }}>
        <p style={{ margin: 0, font: `400 19px/1.72 ${FONT_BODY}`, color: '#E7DECB', textIndent: 0 }}>
          <span style={{ float: 'left', font: `700 58px/0.82 ${FONT_DISPLAY}`, color: ZB.orange, padding: '4px 10px 0 0', letterSpacing: '-0.02em' }}>A</span>
          lice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it,
          <span style={{ color: ZB.t2 }}> “and what is the use of a book,”</span> thought Alice <span style={{ color: ZB.t2 }}>“without pictures or conversations?”</span>
        </p>
        <p style={{ margin: '20px 0 0', font: `400 19px/1.72 ${FONT_BODY}`, color: '#E7DECB' }}>
          So she was considering in her own mind whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies, when suddenly a White Rabbit with pink eyes ran close by her.
        </p>
      </div>

      {/* floating celebration pill — non-blocking, sits above the controls */}
      <div style={{ position: 'absolute', left: 16, right: 16, bottom: 116, zIndex: 6 }}>
        <Pill emoji="👏" text="Fatima finished Chapter 6" count={3} />
      </div>

      {/* reading controls */}
      <div style={{ flex: 'none', paddingBottom: SAFE_BOT, background: ZB.s1, borderTop: `1px solid ${ZB.line}` }}>
        <div style={{ padding: '14px 22px 6px' }}>
          <div style={{ height: 6, borderRadius: 999, background: ZB.s4, overflow: 'hidden' }}>
            <div style={{ width: '38%', height: '100%', background: ZB.orange, borderRadius: 999 }} />
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 9, font: `500 12px/1 ${FONT_MONO}`, color: ZB.t3 }}>
            <span>page 9 / 24</span><span>5 min to milestone</span>
          </div>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-around', padding: '8px 22px 12px' }}>
          {[['text', 'Aa'], ['sun', null], ['clock', null], ['bookmark', null]].map(([ic], i) => (
            <div key={i} style={{ width: 44, height: 44, borderRadius: 14, display: 'grid', placeItems: 'center', background: ZB.s3, border: `1px solid ${ZB.line}` }}>
              <Icon name={ic} size={20} color={ZB.t2} />
            </div>
          ))}
        </div>
      </div>
    </Screen>
  );
}

// ─────────────────── EMBER · ZAP MOMENT ───────────────────
function EmberZap() {
  return (
    <Screen style={{ background: ZB.bg }}>
      <div style={{ position: 'absolute', inset: 0, background: `radial-gradient(80% 50% at 50% 32%, ${ZB.orangeDim}, transparent 70%)` }} />
      <div style={{ position: 'relative', flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: `${SAFE_TOP}px 30px 0`, textAlign: 'center' }}>
        {/* big expressive shape */}
        <div style={{ width: 150, height: 150, borderRadius: 48, background: ZB.orange, display: 'grid', placeItems: 'center', marginBottom: 36,
          boxShadow: `0 0 0 12px ${ZB.orangeDim}, 0 24px 60px -10px rgba(247,147,26,0.5)` }}>
          <Bolt size={78} color="#241500" />
        </div>
        <div style={{ font: `700 13px/1 ${FONT_BODY}`, letterSpacing: '0.14em', textTransform: 'uppercase', color: ZB.orangeSoft, marginBottom: 18 }}>Milestone passed</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginBottom: 18 }}>
          <span style={{ font: `700 76px/1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.04em', fontVariantNumeric: 'tabular-nums' }}>+2,100</span>
          <span style={{ font: `700 26px/1 ${FONT_DISPLAY}`, color: ZB.orange }}>sats</span>
        </div>
        <div style={{ font: `400 17px/1.5 ${FONT_BODY}`, color: ZB.t2, maxWidth: 280 }}>
          Zapped by <span style={{ color: ZB.t1, fontWeight: 600 }}>Grandpa 🦊</span> for finishing the Rabbit-Hole quiz — 2 of 2 correct.
        </div>

        <div style={{ marginTop: 30, display: 'flex', gap: 9 }}>
          {[1, 2].map((n) => (
            <div key={n} style={{ display: 'flex', alignItems: 'center', gap: 7, padding: '8px 13px', borderRadius: 999, background: ZB.s2, border: `1px solid ${ZB.line}` }}>
              <Icon name="check" size={15} color="#3DCB89" sw={2.4} />
              <span style={{ font: `600 12.5px/1 ${FONT_BODY}`, color: ZB.t2 }}>Question {n}</span>
            </div>
          ))}
        </div>
      </div>

      <div style={{ position: 'relative', flex: 'none', padding: `0 24px ${SAFE_BOT + 18}px` }}>
        <div style={{ height: 56, borderRadius: 18, background: ZB.orange, display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 12 }}>
          <span style={{ font: `700 16px/1 ${FONT_BODY}`, color: '#241500' }}>Keep reading</span>
        </div>
        <div style={{ height: 52, borderRadius: 18, background: 'transparent', border: `1px solid ${ZB.line2}`, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ font: `600 15px/1 ${FONT_BODY}`, color: ZB.t2 }}>View wallet</span>
        </div>
      </div>
    </Screen>
  );
}

Object.assign(window, { EmberHome, EmberCircle, EmberReader, EmberZap, MNav, eCard, eTitle });
