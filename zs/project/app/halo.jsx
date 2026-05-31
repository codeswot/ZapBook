/* ZapBook — Direction A · "Halo" (Liquid Glass lean)
   Frosted translucent panels over colored glow, floating glass dock,
   refractive depth, airy. */

// ── glass surface ──
function Glass({ children, style = {}, r = 26, blur = 20, tint = 0.06, hi = 0.20 }) {
  return (
    <div style={{ position: 'relative', borderRadius: r, overflow: 'hidden', ...style }}>
      <div style={{ position: 'absolute', inset: 0, borderRadius: r,
        backdropFilter: `blur(${blur}px) saturate(165%)`, WebkitBackdropFilter: `blur(${blur}px) saturate(165%)`,
        background: `rgba(255,250,240,${tint})` }} />
      <div style={{ position: 'absolute', inset: 0, borderRadius: r, pointerEvents: 'none',
        border: '1px solid rgba(255,250,240,0.14)',
        boxShadow: `inset 1.2px 1.2px 0 rgba(255,255,255,${hi}), inset -1px -1.5px 1px rgba(255,255,255,0.05)` }} />
      <div style={{ position: 'relative' }}>{children}</div>
    </div>
  );
}

// ── ambient background (flat, no gradient — solid dark) ──
function GlowBG({ children, accent = 'orange' }) {
  return (
    <div style={{ position: 'absolute', inset: 0, background: ZB.bg, overflow: 'hidden' }}>
      {children}
    </div>
  );
}

// ── floating glass dock ──
function HaloDock({ active = 'home' }) {
  const items = [['home', 'home'], ['circles', 'circles'], ['book', 'library'], ['user', 'you']];
  return (
    <div style={{ position: 'absolute', left: '50%', bottom: SAFE_BOT + 8, transform: 'translateX(-50%)', zIndex: 8 }}>
      <Glass r={999} blur={22} tint={0.10} style={{ padding: '9px 12px' }}>
        <div style={{ display: 'flex', gap: 6 }}>
          {items.map(([ic, id]) => {
            const on = id === active;
            return (
              <div key={id} style={{ width: 52, height: 52, borderRadius: 999, display: 'grid', placeItems: 'center',
                background: on ? ZB.orange : 'transparent' }}>
                <Icon name={ic} size={23} color={on ? '#241500' : ZB.t2} sw={on ? 2.2 : 1.9} />
              </div>
            );
          })}
        </div>
      </Glass>
    </div>
  );
}

const hTitle = { font: `700 30px/1.02 ${FONT_DISPLAY}`, letterSpacing: '-0.025em', color: ZB.t1, margin: 0 };

// ─────────────────── HALO · HOME / LIBRARY ───────────────────
function HaloHome() {
  return (
    <Screen>
      <GlowBG accent="orange" />
      <div style={{ position: 'relative', flex: 1, overflow: 'hidden', padding: `${SAFE_TOP + 12}px 22px 0` }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 22 }}>
          <div>
            <div style={{ font: `500 14px/1 ${FONT_BODY}`, color: ZB.t2, marginBottom: 9 }}>Good evening, Wren</div>
            <h1 style={hTitle}>Tonight's read</h1>
          </div>
          <Glass r={999} style={{ padding: '9px 13px' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
              <Icon name="flame" size={17} color={ZB.orangeSoft} sw={2.1} />
              <span style={{ font: `700 15px/1 ${FONT_MONO}`, color: ZB.t1 }}>12</span>
            </div>
          </Glass>
        </div>

        {/* continue glass hero */}
        <Glass r={28} blur={16} style={{ marginBottom: 18 }}>
          <div style={{ padding: 18, display: 'flex', gap: 18 }}>
            <Cover w={92} h={130} hue="orange" title="Alice" author="L. Carroll" r={16} />
            <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
              <div style={{ font: `700 20px/1.12 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>Alice's Adventures in Wonderland</div>
              <div style={{ font: `500 13px/1 ${FONT_BODY}`, color: ZB.t2, marginTop: 7 }}>Ch. 1 · Down the Rabbit-Hole</div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginTop: 9 }}>
                <Icon name="circles" size={13} color={ZB.purpleSoft} sw={2} />
                <span style={{ font: `500 11.5px/1 ${FONT_BODY}`, color: ZB.purpleSoft }}>with Mr. Lee's Class · 47 reading</span>
              </div>
              <div style={{ marginTop: 'auto', display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{ flex: 1 }}>
                  <div style={{ height: 7, borderRadius: 999, background: 'rgba(255,255,255,0.12)', overflow: 'hidden' }}>
                    <div style={{ width: '38%', height: '100%', background: ZB.orange, borderRadius: 999 }} />
                  </div>
                  <div style={{ font: `500 11px/1 ${FONT_MONO}`, color: ZB.t3, marginTop: 8 }}>38% · 9 min left</div>
                </div>
                <Glass r={999} tint={0.14} hi={0.3} style={{ width: 48, height: 48 }}>
                  <div style={{ width: 48, height: 48, display: 'grid', placeItems: 'center' }}>
                    <Icon name="play" size={20} color={ZB.orangeSoft} />
                  </div>
                </Glass>
              </div>
            </div>
          </div>
        </Glass>

        {/* sats balance strip */}
        <Glass r={20} tint={0.05} style={{ marginBottom: 26 }}>
          <div style={{ padding: '15px 18px', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <Bolt size={26} color={ZB.orange} />
              <div>
                <div style={{ font: `700 22px/1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.02em', fontVariantNumeric: 'tabular-nums' }}>48,250</div>
                <div style={{ font: `500 11.5px/1 ${FONT_BODY}`, color: ZB.t3, marginTop: 6 }}>sats earned reading</div>
              </div>
            </div>
            <Icon name="chevron" size={20} color={ZB.t3} />
          </div>
        </Glass>

        {/* shelf */}
        <div style={{ font: `700 18px/1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em', marginBottom: 15 }}>On your shelf</div>
        <div style={{ display: 'flex', gap: 16 }}>
          {[
            { t: 'Peter Pan', a: 'Barrie', h: 'purple' },
            { t: 'The Jungle Book', a: 'Kipling', h: 'mint' },
            { t: 'Treasure Island', a: 'Stevenson', h: 'sky' },
          ].map((b, i) => (
            <Cover key={i} w={104} h={146} hue={b.h} title={b.t} author={b.a} r={18} />
          ))}
        </div>
      </div>
      <HaloDock active="home" />
    </Screen>
  );
}

// ─────────────────── HALO · READING CIRCLE ───────────────────
// A circle = 1–100 people reading ONE book together. Anyone can zap anyone.
function HaloCircle() {
  const readers = [
    { name: 'Wren', emoji: '🦊', page: 18, total: 24, you: false },
    { name: 'You', emoji: '🌿', page: 9, total: 24, you: true },
    { name: 'Theo', emoji: '🐙', page: 7, total: 24, you: false },
    { name: 'Mei', emoji: '🪐', page: 4, total: 24, you: false },
  ];
  return (
    <Screen>
      <GlowBG accent="purple" />
      <div style={{ position: 'relative', flex: 1, overflow: 'hidden', padding: `${SAFE_TOP + 12}px 22px 0` }}>
        <div style={{ marginBottom: 18 }}>
          <div style={{ font: `600 13px/1 ${FONT_BODY}`, letterSpacing: '0.04em', textTransform: 'uppercase', color: ZB.purpleSoft, marginBottom: 10 }}>Reading together · 47 readers</div>
          <h1 style={hTitle}>Mr. Lee's Class</h1>
        </div>

        {/* the shared book */}
        <Glass r={26} blur={16} style={{ marginBottom: 20 }}>
          <div style={{ padding: 16, display: 'flex', gap: 16, alignItems: 'center' }}>
            <Cover w={66} h={94} hue="orange" title="Alice" author="Carroll" r={13} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ font: `600 11px/1 ${FONT_BODY}`, letterSpacing: '0.05em', textTransform: 'uppercase', color: ZB.purpleSoft, marginBottom: 8 }}>The circle is reading</div>
              <div style={{ font: `700 19px/1.1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>Alice in Wonderland</div>
              <div style={{ font: `500 12.5px/1 ${FONT_BODY}`, color: ZB.t2, marginTop: 7 }}>everyone's on this one · finish by Sunday</div>
            </div>
          </div>
        </Glass>

        {/* readers — anyone can zap anyone */}
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 14 }}>
          <div style={{ font: `700 18px/1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>Readers</div>
          <div style={{ font: `500 12px/1 ${FONT_BODY}`, color: ZB.t3 }}>by progress</div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 9 }}>
          {readers.map((r, i) => (
            <Glass key={i} r={20} tint={r.you ? 0.10 : 0.045} hi={r.you ? 0.26 : 0.16}>
              <div style={{ padding: '10px 11px 10px 14px', display: 'flex', alignItems: 'center', gap: 13 }}>
                <Ava emoji={r.emoji} size={40} ring={r.you ? ZB.purpleLine : ZB.line2} />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                    <span style={{ font: `700 15.5px/1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>{r.name}</span>
                    {r.you && <span style={{ font: `600 10px/1 ${FONT_BODY}`, color: ZB.purpleSoft, padding: '3px 6px', borderRadius: 999, background: 'rgba(165,107,255,0.18)' }}>YOU</span>}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 9, marginTop: 8 }}>
                    <div style={{ flex: 1, height: 6, borderRadius: 999, background: 'rgba(255,255,255,0.12)', overflow: 'hidden' }}>
                      <div style={{ width: `${(r.page / r.total) * 100}%`, height: '100%', background: r.you ? ZB.purpleSoft : ZB.orange, borderRadius: 999 }} />
                    </div>
                    <span style={{ font: `500 11px/1 ${FONT_MONO}`, color: ZB.t3, whiteSpace: 'nowrap' }}>p.{r.page}</span>
                  </div>
                </div>
                {!r.you && (
                  <Glass r={14} tint={0.16} hi={0.3} style={{ width: 42, height: 42, flex: 'none' }}>
                    <div style={{ width: 42, height: 42, display: 'grid', placeItems: 'center', background: 'rgba(247,147,26,0.26)' }}>
                      <Bolt size={19} color={ZB.orangeSoft} />
                    </div>
                  </Glass>
                )}
              </div>
            </Glass>
          ))}
        </div>
        <div style={{ textAlign: 'center', font: `500 12.5px/1 ${FONT_BODY}`, color: ZB.t3, marginTop: 15 }}>+ 43 more reading along</div>
      </div>

      <HaloDock active="circles" />
    </Screen>
  );
}

// ─────────────────── HALO · READER (Alice) ───────────────────
function HaloReader() {
  return (
    <Screen style={{ background: '#15110B' }}>
      {/* faint top glow */}
      <div style={{ position: 'absolute', top: -60, left: '50%', transform: 'translateX(-50%)', width: 300, height: 200, borderRadius: 999, background: 'rgba(247,147,26,0.14)', filter: 'blur(70px)' }} />

      {/* page content (immersive) */}
      <div style={{ position: 'relative', flex: 1, overflow: 'hidden', padding: `${SAFE_TOP + 26}px 30px 0` }}>
        <div style={{ font: `600 12px/1 ${FONT_BODY}`, letterSpacing: '0.16em', textTransform: 'uppercase', color: ZB.orangeSoft, marginBottom: 14 }}>Chapter One</div>
        <div style={{ font: `700 26px/1.1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.02em', marginBottom: 26 }}>Down the Rabbit-Hole</div>
        <p style={{ margin: 0, font: `400 19.5px/1.74 ${FONT_BODY}`, color: '#EADFCB' }}>
          Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do: once or twice she had peeped into the book her sister was reading, but it had no pictures or conversations in it,
          <span style={{ color: ZB.t2 }}> “and what is the use of a book,”</span> thought Alice <span style={{ color: ZB.t2 }}>“without pictures or conversations?”</span>
        </p>
        <p style={{ margin: '20px 0 0', font: `400 19.5px/1.74 ${FONT_BODY}`, color: '#EADFCB' }}>
          So she was considering in her own mind whether the pleasure of making a daisy-chain would be worth the trouble of getting up and picking the daisies.
        </p>
      </div>

      {/* floating top bar */}
      <div style={{ position: 'absolute', top: SAFE_TOP - 2, left: 16, right: 16, zIndex: 6 }}>
        <Glass r={999} blur={20} tint={0.08} style={{ padding: '7px 8px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 38, height: 38, borderRadius: 999, display: 'grid', placeItems: 'center' }}>
              <Icon name="chevron" size={20} color={ZB.t2} style={{ transform: 'rotate(180deg)' }} />
            </div>
            <div style={{ flex: 1, font: `600 13px/1 ${FONT_MONO}`, color: ZB.t2 }}>page 9 / 24</div>
            <div style={{ width: 38, height: 38, borderRadius: 999, display: 'grid', placeItems: 'center' }}>
              <Icon name="bookmark" size={18} color={ZB.orangeSoft} />
            </div>
          </div>
        </Glass>
      </div>

      {/* floating control pill */}
      <div style={{ position: 'absolute', left: '50%', bottom: SAFE_BOT + 8, transform: 'translateX(-50%)', zIndex: 6 }}>
        <Glass r={999} blur={22} tint={0.10} hi={0.24} style={{ padding: '8px 10px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
            {['text', 'sun', 'search'].map((ic, i) => (
              <div key={i} style={{ width: 46, height: 46, borderRadius: 999, display: 'grid', placeItems: 'center' }}>
                <Icon name={ic} size={20} color={ZB.t2} />
              </div>
            ))}
            <div style={{ width: 1, height: 26, background: 'rgba(255,255,255,0.14)', margin: '0 4px' }} />
            <div style={{ display: 'flex', alignItems: 'center', gap: 7, padding: '0 16px 0 12px', height: 46, borderRadius: 999, background: ZB.orangeDim }}>
              <Icon name="flame" size={16} color={ZB.orangeSoft} sw={2.1} />
              <span style={{ font: `600 13px/1 ${FONT_MONO}`, color: ZB.orangeSoft }}>5 min</span>
            </div>
          </div>
        </Glass>
      </div>
    </Screen>
  );
}

// ─────────────────── HALO · ZAP MOMENT ───────────────────
function HaloZap() {
  return (
    <Screen>
      <GlowBG accent="orange" />
      {/* concentric ray rings */}
      <div style={{ position: 'absolute', top: 250, left: '50%', transform: 'translate(-50%,-50%)', width: 420, height: 420 }}>
        {[0, 1, 2].map((i) => (
          <div key={i} style={{ position: 'absolute', inset: `${i * 64}px`, borderRadius: 999, border: '1.5px solid rgba(247,147,26,0.30)' }} />
        ))}
      </div>

      <div style={{ position: 'relative', flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: `${SAFE_TOP}px 28px 0`, textAlign: 'center' }}>
        <Glass r={999} tint={0.12} hi={0.32} blur={10} style={{ width: 138, height: 138, marginBottom: 34 }}>
          <div style={{ width: 138, height: 138, display: 'grid', placeItems: 'center', background: 'rgba(247,147,26,0.28)' }}>
            <Bolt size={70} color={ZB.orangeSoft} />
          </div>
        </Glass>

        <div style={{ font: `600 13px/1 ${FONT_BODY}`, letterSpacing: '0.16em', textTransform: 'uppercase', color: ZB.orangeSoft, marginBottom: 18 }}>Milestone passed</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 10, marginBottom: 22 }}>
          <span style={{ font: `700 74px/1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.04em', fontVariantNumeric: 'tabular-nums' }}>+2,100</span>
          <span style={{ font: `700 26px/1 ${FONT_DISPLAY}`, color: ZB.orangeSoft }}>sats</span>
        </div>

        <Glass r={20} tint={0.06} style={{ width: '100%', maxWidth: 320 }}>
          <div style={{ padding: '15px 18px', display: 'flex', alignItems: 'center', gap: 13, textAlign: 'left' }}>
            <Ava emoji="🦊" size={42} />
            <div style={{ flex: 1 }}>
              <div style={{ font: `600 15px/1.3 ${FONT_BODY}`, color: ZB.t1 }}>Zapped by Grandpa</div>
              <div style={{ font: `500 12.5px/1.3 ${FONT_BODY}`, color: ZB.t3, marginTop: 4 }}>Rabbit-Hole quiz · 2 of 2 correct</div>
            </div>
            <Icon name="check" size={20} color="#3DCB89" sw={2.4} />
          </div>
        </Glass>
      </div>

      <div style={{ position: 'relative', flex: 'none', padding: `0 26px ${SAFE_BOT + 18}px`, display: 'flex', flexDirection: 'column', gap: 12 }}>
        <Glass r={18} tint={0.16} hi={0.34}>
          <div style={{ height: 56, background: 'rgba(247,147,26,0.32)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <span style={{ font: `700 16px/1 ${FONT_BODY}`, color: ZB.t1 }}>Keep reading</span>
          </div>
        </Glass>
        <Glass r={18} tint={0.05}>
          <div style={{ height: 52, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <span style={{ font: `600 15px/1 ${FONT_BODY}`, color: ZB.t2 }}>View wallet</span>
          </div>
        </Glass>
      </div>
    </Screen>
  );
}

Object.assign(window, { HaloHome, HaloCircle, HaloReader, HaloZap });
