/* ZapBook — Ember · the zap-reaction system + the quiz→reward flow.
   Reaction = amount (👍100 · 👏500 · 🔥1k · 🚀2.1k · 🏆5k) + 🎁 gift wrap.
   Flow: milestone trigger → quiz → submit to circle → circle notified → zap. */

const REACTIONS = [
  { emoji: '👍', label: 'Nice', sats: '100' },
  { emoji: '👏', label: 'Clap', sats: '500' },
  { emoji: '🔥', label: 'Fire', sats: '1k' },
  { emoji: '🚀', label: 'Boost', sats: '2.1k' },
  { emoji: '🏆', label: 'Champ', sats: '5k' },
];

const sysHead = (over, title) => (
  <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '4px 20px 18px' }}>
    <div>
      <div style={{ font: `600 12px/1 ${FONT_BODY}`, letterSpacing: '0.05em', textTransform: 'uppercase', color: ZB.orangeSoft, marginBottom: 8 }}>{over}</div>
      <div style={{ font: `700 24px/1.05 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.02em' }}>{title}</div>
    </div>
    <div style={{ width: 34, height: 34, borderRadius: 999, background: ZB.s3, border: `1px solid ${ZB.line}`, display: 'grid', placeItems: 'center' }}>
      <Icon name="x" size={17} color={ZB.t2} sw={2.2} />
    </div>
  </div>
);

// ─────────────────── ZAP SHEET — reaction = amount + gift wrap ───────────────────
function ZapSheet() {
  return (
    <Screen style={{ background: ZB.bg }}>
      <Sheet>
        {/* target */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 13, padding: '8px 20px 4px' }}>
          <Ava emoji="🦊" size={48} />
          <div style={{ flex: 1 }}>
            <div style={{ font: `700 20px/1.05 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>Zap Wren</div>
            <div style={{ font: `500 13px/1.2 ${FONT_BODY}`, color: ZB.t2, marginTop: 5 }}>passed the Chapter 1 quiz · 3 of 3</div>
          </div>
        </div>

        <div style={{ font: `500 12.5px/1 ${FONT_BODY}`, color: ZB.t3, padding: '16px 20px 11px' }}>Tap a reaction — the sats send instantly</div>
        {/* reaction row */}
        <div style={{ display: 'flex', gap: 9, padding: '0 18px' }}>
          {REACTIONS.map((r, i) => (
            <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, padding: '12px 2px',
              borderRadius: 16, background: i === 2 ? ZB.orangeDim : ZB.s2, border: `1px solid ${i === 2 ? ZB.orangeLine : ZB.line}` }}>
              <span style={{ fontSize: 26, lineHeight: 1 }}>{r.emoji}</span>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 2, font: `700 11px/1 ${FONT_MONO}`, color: i === 2 ? ZB.orangeSoft : ZB.t2 }}>
                <Bolt size={9} color={i === 2 ? ZB.orangeSoft : ZB.t3} />{r.sats}
              </span>
            </div>
          ))}
        </div>

        {/* gift wrap — flexible amount + note */}
        <div style={{ padding: '14px 18px 4px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '15px 16px', borderRadius: 18,
            background: ZB.s2, border: `1px dashed ${ZB.purpleLine}` }}>
            <div style={{ width: 44, height: 44, borderRadius: 13, flex: 'none', display: 'grid', placeItems: 'center', background: ZB.purpleDim, border: `1px solid ${ZB.purpleLine}` }}>
              <span style={{ fontSize: 22 }}>🎁</span>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ font: `700 15px/1.1 ${FONT_DISPLAY}`, color: ZB.t1 }}>Gift wrap</div>
              <div style={{ font: `500 12.5px/1.2 ${FONT_BODY}`, color: ZB.t3, marginTop: 5 }}>Choose any amount + add a note</div>
            </div>
            <Icon name="chevron" size={19} color={ZB.t3} />
          </div>
        </div>

        {/* balance footer */}
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '16px 22px 6px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
            <Bolt size={17} color={ZB.t3} />
            <span style={{ font: `500 13px/1 ${FONT_BODY}`, color: ZB.t3 }}>Your balance</span>
          </div>
          <span style={{ font: `700 15px/1 ${FONT_MONO}`, color: ZB.t1, fontVariantNumeric: 'tabular-nums' }}>48,250 sats</span>
        </div>
      </Sheet>
    </Screen>
  );
}

// ─────────────────── QUIZ · MILESTONE TRIGGER ───────────────────
function QuizAlert() {
  return (
    <Screen style={{ background: ZB.bg }}>
      <Sheet>
        <div style={{ padding: '14px 24px 6px', textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <div style={{ width: 88, height: 88, borderRadius: 28, background: ZB.orangeDim, border: `1px solid ${ZB.orangeLine}`, display: 'grid', placeItems: 'center', marginBottom: 22 }}>
            <Icon name="bookmark" size={38} color={ZB.orangeSoft} />
          </div>
          <div style={{ font: `700 12px/1 ${FONT_BODY}`, letterSpacing: '0.14em', textTransform: 'uppercase', color: ZB.orangeSoft, marginBottom: 14 }}>Checkpoint reached</div>
          <div style={{ font: `700 27px/1.12 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.02em', maxWidth: 320 }}>You finished Down the Rabbit-Hole</div>
          <div style={{ font: `400 16px/1.5 ${FONT_BODY}`, color: ZB.t2, marginTop: 16, maxWidth: 320 }}>
            Answer 3 quick questions to prove it. Pass, and your circle gets to cheer you on with zaps.
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: 9, marginTop: 22, padding: '9px 15px', borderRadius: 999, background: ZB.s2, border: `1px solid ${ZB.line}` }}>
            <Icon name="clock" size={15} color={ZB.t3} sw={2} />
            <span style={{ font: `500 12.5px/1 ${FONT_BODY}`, color: ZB.t3 }}>about 1 minute · from memory</span>
          </div>
        </div>

        <div style={{ padding: '24px 22px 4px', display: 'flex', flexDirection: 'column', gap: 11 }}>
          <Button variant="primary" size="lg" full iconR="arrowR">Start the 3 questions</Button>
          <Button variant="ghost" size="md" full>Remind me in 10 minutes</Button>
        </div>
      </Sheet>
    </Screen>
  );
}

// ─────────────────── QUIZ · QUESTION ───────────────────
function QuizQuestion() {
  const opts = [
    { t: 'There were no pictures or conversations in her sister\u2019s book', on: true },
    { t: 'The White Rabbit was running late', on: false },
    { t: 'She had finished all her daisy-chains', on: false },
    { t: 'It was nearly time for tea', on: false },
  ];
  return (
    <Screen style={{ background: ZB.bg }}>
      {/* top */}
      <div style={{ flex: 'none', paddingTop: SAFE_TOP }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '8px 20px 0' }}>
          <div style={{ width: 34, height: 34, borderRadius: 999, background: ZB.s3, border: `1px solid ${ZB.line}`, display: 'grid', placeItems: 'center' }}>
            <Icon name="x" size={17} color={ZB.t2} sw={2.2} />
          </div>
          <div style={{ flex: 1, display: 'flex', gap: 6 }}>
            {[0, 1, 2].map((i) => (
              <div key={i} style={{ flex: 1, height: 6, borderRadius: 999, background: i <= 1 ? ZB.orange : ZB.s4 }} />
            ))}
          </div>
          <span style={{ font: `600 13px/1 ${FONT_MONO}`, color: ZB.t2 }}>2/3</span>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'hidden', padding: '30px 22px 0' }}>
        <div style={{ font: `600 12px/1 ${FONT_BODY}`, letterSpacing: '0.05em', textTransform: 'uppercase', color: ZB.orangeSoft, marginBottom: 16 }}>Chapter 1 · question 2</div>
        <div style={{ font: `700 25px/1.25 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.02em', marginBottom: 26 }}>Why had Alice grown tired before she saw the White Rabbit?</div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 11 }}>
          {opts.map((o, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '16px 16px', borderRadius: 18,
              background: o.on ? ZB.orangeDim : ZB.s2, border: `1.5px solid ${o.on ? ZB.orange : ZB.line}` }}>
              <div style={{ width: 26, height: 26, borderRadius: 999, flex: 'none', display: 'grid', placeItems: 'center',
                background: o.on ? ZB.orange : 'transparent', border: `1.5px solid ${o.on ? ZB.orange : ZB.line2}` }}>
                {o.on && <Icon name="check" size={15} color="#241500" sw={2.6} />}
              </div>
              <span style={{ font: `${o.on ? 600 : 500} 15px/1.35 ${FONT_BODY}`, color: o.on ? ZB.t1 : ZB.t2 }}>{o.t}</span>
            </div>
          ))}
        </div>
      </div>

      <div style={{ flex: 'none', padding: `12px 22px ${SAFE_BOT + 16}px` }}>
        <Button variant="primary" size="lg" full iconR="arrowR">Submit answer</Button>
      </div>
    </Screen>
  );
}

// ─────────────────── QUIZ · SUBMITTED → SHARED TO CIRCLE ───────────────────
function QuizSubmitted() {
  return (
    <Screen style={{ background: ZB.bg }}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: `${SAFE_TOP}px 26px 0`, textAlign: 'center' }}>
        <div style={{ width: 116, height: 116, borderRadius: 36, background: 'rgba(61,203,137,0.14)', border: `1px solid rgba(61,203,137,0.34)`, display: 'grid', placeItems: 'center', marginBottom: 28 }}>
          <Icon name="check" size={58} color="#3DCB89" sw={2.4} />
        </div>
        <div style={{ font: `700 13px/1 ${FONT_BODY}`, letterSpacing: '0.14em', textTransform: 'uppercase', color: '#5BD79B', marginBottom: 14 }}>Quiz passed</div>
        <div style={{ font: `700 40px/1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.03em', marginBottom: 16 }}>3 of 3 correct</div>
        <div style={{ font: `400 16px/1.5 ${FONT_BODY}`, color: ZB.t2, maxWidth: 300 }}>
          Your result was shared with <span style={{ color: ZB.t1, fontWeight: 600 }}>Mr. Lee's Class</span>. They can zap you now.
        </div>

        {/* who was notified */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 0, marginTop: 26 }}>
          {['🦊', '🐙', '🪐', '🐢', '🍄'].map((e, i) => (
            <div key={i} style={{ marginLeft: i ? -10 : 0, width: 40, height: 40, borderRadius: 999, background: ZB.s3, border: '2px solid #0E0B07', display: 'grid', placeItems: 'center', fontSize: 19 }}>{e}</div>
          ))}
          <div style={{ marginLeft: -10, width: 40, height: 40, borderRadius: 999, background: ZB.s4, border: '2px solid #0E0B07', display: 'grid', placeItems: 'center', font: `700 12px/1 ${FONT_MONO}`, color: ZB.t2 }}>+42</div>
        </div>
      </div>

      <div style={{ flex: 'none', padding: `0 22px ${SAFE_BOT + 18}px` }}>
        <Banner tone="info" title="47 readers notified" style={{ marginBottom: 14 }}>Zaps and reactions will land in your wallet as they come in.</Banner>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 11 }}>
          <Button variant="primary" size="lg" full>Back to reading</Button>
          <Button variant="outline" size="md" full>See the circle</Button>
        </div>
      </div>
    </Screen>
  );
}

// ─────────────────── QUIZ · ANSWER REVEAL ───────────────────
function QuizReveal() {
  return (
    <Screen style={{ background: ZB.bg }}>
      <div style={{ flex: 'none', paddingTop: SAFE_TOP }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '8px 20px 0' }}>
          <div style={{ flex: 1, display: 'flex', gap: 6 }}>
            {[0, 1, 2].map((i) => (<div key={i} style={{ flex: 1, height: 6, borderRadius: 999, background: ZB.orange }} />))}
          </div>
          <span style={{ font: `600 13px/1 ${FONT_MONO}`, color: ZB.t2 }}>2/3</span>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'hidden', padding: '30px 22px 0' }}>
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '8px 14px', borderRadius: 999, background: 'rgba(61,203,137,0.13)', border: '1px solid rgba(61,203,137,0.34)', marginBottom: 22 }}>
          <Icon name="check" size={16} color="#5BD79B" sw={2.6} />
          <span style={{ font: `700 13px/1 ${FONT_BODY}`, color: '#5BD79B' }}>Correct</span>
        </div>
        <div style={{ font: `700 24px/1.28 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.02em', marginBottom: 24 }}>Why had Alice grown tired before she saw the White Rabbit?</div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '17px 16px', borderRadius: 18, background: 'rgba(61,203,137,0.13)', border: '1.5px solid rgba(61,203,137,0.42)', marginBottom: 11 }}>
          <div style={{ width: 26, height: 26, borderRadius: 999, flex: 'none', display: 'grid', placeItems: 'center', background: '#3DCB89' }}>
            <Icon name="check" size={15} color="#0E2418" sw={2.6} />
          </div>
          <span style={{ font: `600 15px/1.35 ${FONT_BODY}`, color: ZB.t1 }}>There were no pictures or conversations in her sister's book</span>
        </div>

        <div style={{ display: 'flex', gap: 11, padding: '14px 16px', borderRadius: 16, background: ZB.s2, border: `1px solid ${ZB.line}` }}>
          <span style={{ fontSize: 18, lineHeight: 1.3 }}>📖</span>
          <div style={{ font: `400 13.5px/1.5 ${FONT_BODY}`, color: ZB.t2 }}>The book opens with Alice bored on the riverbank — her sister's book had "no pictures or conversations."</div>
        </div>
      </div>

      <div style={{ flex: 'none', padding: `12px 22px ${SAFE_BOT + 16}px` }}>
        <Button variant="primary" size="lg" full iconR="arrowR">Next question</Button>
      </div>
    </Screen>
  );
}

// ─────────────────── CELEBRATION FEED — the circle's memory (dedicated tab) ───────────────────
function CelebrationFeed() {
  return (
    <Screen style={{ background: ZB.bg }}>
      <div style={{ flex: 1, overflow: 'hidden', padding: `${SAFE_TOP + 8}px 20px 8px` }}>
        <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', marginBottom: 16 }}>
          <div>
            <div style={{ font: `600 13px/1 ${FONT_BODY}`, letterSpacing: '0.04em', color: ZB.purpleSoft, textTransform: 'uppercase', marginBottom: 8 }}>Mr. Lee's Class</div>
            <h1 style={{ font: `700 28px/1.05 ${FONT_DISPLAY}`, letterSpacing: '-0.02em', color: ZB.t1, margin: 0 }}>Cheers</h1>
          </div>
          <div style={{ width: 40, height: 40, borderRadius: 999, background: ZB.s2, border: `1px solid ${ZB.line}`, display: 'grid', placeItems: 'center' }}>
            <Icon name="filter" size={18} color={ZB.t2} sw={2} />
          </div>
        </div>

        {/* filters */}
        <div style={{ display: 'flex', gap: 9, marginBottom: 16 }}>
          <Chip selected>All</Chip>
          <Chip>Milestones</Chip>
          <Chip>Zaps</Chip>
          <Chip>Mine</Chip>
        </div>

        {/* feed */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 11 }}>
          <CelebrationCard unread emoji="🍄" name="Fatima" action="finished Chapter 6" time="12m"
            book="Alice in Wonderland" score="3/3"
            reactions={[{ e: '👍', n: 3 }, { e: '👏', n: 5 }, { e: '🔥', n: 1 }]} />
          <CelebrationCard unread emoji="🦊" name="Wren" action="passed Chapter 2" time="2m ago"
            book="Alice in Wonderland" score="3/3"
            reactions={[{ e: '🚀', n: 1 }, { e: '👏', n: 2 }]} />
          <CelebrationCard emoji="🌿" name="You" action="passed Chapter 1" time="1h"
            book="Alice in Wonderland" score="3/3" showActions={false}
            reactions={[{ e: '🔥', n: 1 }, { e: '👏', n: 1 }, { e: '👍', n: 1 }]} />
        </div>
      </div>
      <MNav active="cheers" />
    </Screen>
  );
}

// ─────────────────── CELEBRATION HALF-SHEET — slides up from the pill ───────────────────
function CelebrationSheet() {
  return (
    <Screen style={{ background: ZB.bg }}>
      {/* hint of the reader behind */}
      <div style={{ position: 'absolute', inset: 0, padding: `${SAFE_TOP + 26}px 30px 0`, opacity: 0.5 }}>
        <div style={{ font: `400 19px/1.72 ${FONT_BODY}`, color: '#E7DECB' }}>Alice was beginning to get very tired of sitting by her sister on the bank, and of having nothing to do.</div>
      </div>
      <Sheet>
        <div style={{ padding: '6px 20px 0' }}>
          <div style={{ font: `600 12px/1 ${FONT_BODY}`, letterSpacing: '0.05em', textTransform: 'uppercase', color: ZB.orangeSoft, marginBottom: 14 }}>Cheer Fatima on</div>
          <CelebrationCard emoji="🍄" name="Fatima" action="finished Chapter 6" time="now"
            book="Alice in Wonderland" score="3/3" showActions={false}
            reactions={[{ e: '👍', n: 3 }, { e: '👏', n: 5 }]} />
        </div>

        <div style={{ font: `500 12.5px/1 ${FONT_BODY}`, color: ZB.t3, padding: '18px 20px 11px' }}>Tap to zap — sats send instantly</div>
        <div style={{ display: 'flex', gap: 9, padding: '0 18px' }}>
          {REACTIONS.map((r, i) => (
            <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6, padding: '12px 2px',
              borderRadius: 16, background: ZB.s2, border: `1px solid ${ZB.line}` }}>
              <span style={{ fontSize: 25, lineHeight: 1 }}>{r.emoji}</span>
              <span style={{ display: 'inline-flex', alignItems: 'center', gap: 2, font: `700 11px/1 ${FONT_MONO}`, color: ZB.t2 }}>
                <Bolt size={9} color={ZB.t3} />{r.sats}
              </span>
            </div>
          ))}
          <div style={{ width: 52, display: 'grid', placeItems: 'center', borderRadius: 16, background: ZB.purpleDim, border: `1px solid ${ZB.purpleLine}` }}>
            <span style={{ fontSize: 22 }}>🎁</span>
          </div>
        </div>

        <div style={{ padding: '20px 20px 4px' }}>
          <Button variant="ghost" size="md" full>Continue reading</Button>
        </div>
      </Sheet>
    </Screen>
  );
}

Object.assign(window, { ZapSheet, QuizAlert, QuizQuestion, QuizReveal, QuizSubmitted, CelebrationFeed, CelebrationSheet });
