/* ZapBook — Design System reference page (Ember · Material You · dark).
   Reuses ds.jsx + components.jsx + ember.jsx (MNav). Renders <DSPage/>. */

const Sec = ({ n, title, desc, children }) => (
  <section style={{ marginTop: 72 }}>
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 14, marginBottom: desc ? 10 : 24 }}>
      <span style={{ font: `700 13px/1 ${FONT_MONO}`, color: ZB.orangeSoft }}>{n}</span>
      <h2 style={{ font: `700 30px/1 ${FONT_DISPLAY}`, letterSpacing: '-0.025em', color: ZB.t1, margin: 0 }}>{title}</h2>
    </div>
    {desc && <p style={{ font: `400 16px/1.5 ${FONT_BODY}`, color: ZB.t2, margin: '0 0 26px', maxWidth: 620 }}>{desc}</p>}
    {children}
  </section>
);

const Panel = ({ label, children, style = {} }) => (
  <div style={{ background: ZB.s1, border: `1px solid ${ZB.line}`, borderRadius: 20, padding: 22, ...style }}>
    {label && <div style={{ font: `600 11px/1 ${FONT_BODY}`, letterSpacing: '0.1em', textTransform: 'uppercase', color: ZB.t3, marginBottom: 18 }}>{label}</div>}
    {children}
  </div>
);

const Sw = ({ c, name, hex, ring }) => (
  <div>
    <div style={{ height: 72, borderRadius: 14, background: c, border: `1px solid ${ring || 'rgba(255,255,255,0.09)'}` }} />
    <div style={{ font: `600 13px/1 ${FONT_BODY}`, color: ZB.t1, marginTop: 11 }}>{name}</div>
    <div style={{ font: `500 12px/1 ${FONT_MONO}`, color: ZB.t3, marginTop: 5 }}>{hex}</div>
  </div>
);

const grid = (cols, gap = 16) => ({ display: 'grid', gridTemplateColumns: `repeat(${cols}, 1fr)`, gap });

function DSPage() {
  const mark = <svg viewBox="0 0 40 40" width="40" height="40"><rect x="2" y="2" width="36" height="36" rx="11" fill={ZB.orange} /><path d="M22 8.5 13.5 22.5H19l-1.2 9.5L26.5 18H21l1-9.5z" fill="#241500" /></svg>;

  return (
    <div style={{ minHeight: '100vh', background: ZB.bg, padding: '64px 0 120px' }}>
      <div style={{ maxWidth: 1120, margin: '0 auto', padding: '0 40px' }}>

        {/* header */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 18 }}>
          {mark}
          <div style={{ font: `700 24px/1 ${FONT_DISPLAY}`, letterSpacing: '-0.02em', color: ZB.t1 }}>Zap<span style={{ fontWeight: 800 }}>Book</span></div>
          <span style={{ marginLeft: 6, font: `600 12px/1 ${FONT_BODY}`, color: ZB.orangeSoft, background: ZB.orangeDim, border: `1px solid ${ZB.orangeLine}`, padding: '7px 12px', borderRadius: 999 }}>Ember · Material You</span>
        </div>
        <h1 style={{ font: `700 56px/1 ${FONT_DISPLAY}`, letterSpacing: '-0.035em', color: ZB.t1, margin: '0 0 16px' }}>Design system</h1>
        <p style={{ font: `400 19px/1.5 ${FONT_BODY}`, color: ZB.t2, margin: 0, maxWidth: 640 }}>
          A dark, tonal reading surface. Neutral warm greys carry the weight; Bitcoin orange and Nostr purple are accents only. Flat surfaces, hairline borders, no gradients.
        </p>

        {/* ── COLOR ── */}
        <Sec n="01" title="Color" desc="Elevation is built from tonal surface steps, not shadow. Accents are reserved for action, reward, and the social layer.">
          <Panel label="Surfaces" style={{ marginBottom: 16 }}>
            <div style={grid(5)}>
              <Sw c="#0E0B07" name="bg" hex="#0E0B07" />
              <Sw c="#16120D" name="surface 1" hex="#16120D" />
              <Sw c="#1F1A13" name="surface 2" hex="#1F1A13" />
              <Sw c="#29221A" name="surface 3" hex="#29221A" />
              <Sw c="#342B20" name="surface 4" hex="#342B20" />
            </div>
          </Panel>
          <div style={grid(2)}>
            <Panel label="Accents">
              <div style={grid(2)}>
                <Sw c={ZB.orange} name="Bitcoin orange" hex="#F7931A" ring="transparent" />
                <Sw c={ZB.purple} name="Nostr purple" hex="#A56BFF" ring="transparent" />
              </div>
            </Panel>
            <Panel label="Semantic / status">
              <div style={grid(4)}>
                <Sw c="#4F8EFF" name="Info" hex="#4F8EFF" ring="transparent" />
                <Sw c="#3DCB89" name="Success" hex="#3DCB89" ring="transparent" />
                <Sw c="#F7C948" name="Warning" hex="#F7C948" ring="transparent" />
                <Sw c="#E5484D" name="Error" hex="#E5484D" ring="transparent" />
              </div>
            </Panel>
          </div>
          <Panel label="Text on dark" style={{ marginTop: 16 }}>
            <div style={{ display: 'flex', gap: 40, flexWrap: 'wrap' }}>
              <div style={{ font: `600 22px/1.3 ${FONT_BODY}`, color: ZB.t1 }}>Primary — #F7F1E5</div>
              <div style={{ font: `600 22px/1.3 ${FONT_BODY}`, color: ZB.t2 }}>Secondary — #B9AF9D</div>
              <div style={{ font: `600 22px/1.3 ${FONT_BODY}`, color: ZB.t3 }}>Tertiary — #7F7666</div>
            </div>
          </Panel>
        </Sec>

        {/* ── TYPE ── */}
        <Sec n="02" title="Type" desc="Bricolage Grotesque for display & headings; Hanken Grotesque for body & UI; JetBrains Mono for sats, pages, and progress.">
          <Panel>
            {[
              ['Display', '40 / Bricolage 700', `700 40px/1 ${FONT_DISPLAY}`, 'Read together. Prove it.'],
              ['Heading', '28 / Bricolage 700', `700 28px/1.1 ${FONT_DISPLAY}`, 'Mr. Lee\u2019s Class'],
              ['Title', '20 / Bricolage 700', `700 20px/1.1 ${FONT_DISPLAY}`, 'Alice in Wonderland'],
              ['Body', '16 / Hanken 400', `400 16px/1.5 ${FONT_BODY}`, 'Anyone in the circle can zap anyone reading along.'],
              ['Label', '13 / Hanken 600', `600 13px/1 ${FONT_BODY}`, 'Reward per milestone'],
              ['Mono', '15 / JetBrains 600', `600 15px/1 ${FONT_MONO}`, '2,100 sats · page 41 / 64'],
            ].map((r, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'baseline', gap: 28, padding: '16px 0', borderTop: i ? `1px solid ${ZB.line}` : 'none' }}>
                <div style={{ width: 150, flex: 'none' }}>
                  <div style={{ font: `700 14px/1 ${FONT_BODY}`, color: ZB.t1 }}>{r[0]}</div>
                  <div style={{ font: `500 11px/1.3 ${FONT_MONO}`, color: ZB.t3, marginTop: 6 }}>{r[1]}</div>
                </div>
                <div style={{ font: r[2], color: ZB.t1, letterSpacing: r[0] === 'Display' ? '-0.03em' : '-0.01em' }}>{r[3]}</div>
              </div>
            ))}
          </Panel>
        </Sec>

        {/* ── BUTTONS ── */}
        <Sec n="03" title="Buttons" desc="Pill-shaped, Material-tonal. Primary is Bitcoin orange; purple drives social/circle actions.">
          <Panel>
            <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center', marginBottom: 18 }}>
              <Button variant="primary" icon="zap">Zap back</Button>
              <Button variant="purple" icon="circles">Start a circle</Button>
              <Button variant="tonal">React</Button>
              <Button variant="outline">See the circle</Button>
              <Button variant="ghost">Later</Button>
              <Button variant="danger">Leave circle</Button>
            </div>
            <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'center' }}>
              <Button variant="primary" size="sm">Small</Button>
              <Button variant="primary" size="md">Medium</Button>
              <Button variant="primary" size="lg" iconR="arrowR">Large</Button>
            </div>
          </Panel>
        </Sec>

        {/* ── CHIPS / PILLS / SATS ── */}
        <Sec n="04" title="Chips, pills & sats" desc="Filters, tags, and the tabular-mono sats unit with its bolt.">
          <div style={grid(2)}>
            <Panel label="Chips & filters">
              <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                <Chip selected>All</Chip>
                <Chip>Milestones</Chip>
                <Chip>Zaps</Chip>
                <Chip icon="flame" tone="warning" selected>12-day</Chip>
                <Chip icon="circles" tone="info">47 reading</Chip>
              </div>
            </Panel>
            <Panel label="Sats">
              <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap' }}>
                <Sats amount="2,100" />
                <Sats amount="12.4k" />
                <Sats amount="48,250" size={15} />
              </div>
            </Panel>
          </div>
        </Sec>

        {/* ── REACTIONS ── */}
        <Sec n="05" title="Zap reactions" desc="A reaction carries a fixed sat amount — one tap to send. Gift wrap covers any custom amount with a note.">
          <Panel>
            <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginBottom: 18 }}>
              <div style={{ width: 96 }}><Reaction emoji="👍" label="Nice" sats="100" /></div>
              <div style={{ width: 96 }}><Reaction emoji="👏" label="Clap" sats="500" /></div>
              <div style={{ width: 96 }}><Reaction emoji="🔥" label="Fire" sats="1k" accent={ZB.orangeSoft} /></div>
              <div style={{ width: 96 }}><Reaction emoji="🚀" label="Boost" sats="2.1k" /></div>
              <div style={{ width: 96 }}><Reaction emoji="🏆" label="Champ" sats="5k" /></div>
              <div style={{ width: 96 }}><Reaction emoji="🎁" label="Gift wrap" sats="any" accent={ZB.purpleSoft} /></div>
            </div>
          </Panel>
        </Sec>

        {/* ── ALERT BANNERS ── */}
        <Sec n="06" title="Alert banners" desc="Five tones, each a tinted surface with a matching hairline and icon tile. Used inline — never as a blocking takeover.">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <Banner tone="info" title="47 readers notified" onClose>Zaps and reactions will land in your wallet as they come in.</Banner>
            <Banner tone="success" title="Quiz passed — 3 of 3" onClose>Your result was shared with Mr. Lee's Class.</Banner>
            <Banner tone="warning" title="Checkpoint waiting" action={<Button variant="tonal" size="sm">Start the quiz</Button>}>You finished a chapter — answer 3 quick questions to unlock zaps.</Banner>
            <Banner tone="error" title="Couldn't send that zap" onClose>Your balance is below 100 sats. Top up to keep cheering.</Banner>
            <Banner tone="zap" title="Wren zapped you 🔥 1,000" onClose>For finishing the Rabbit-Hole quiz.</Banner>
          </div>
        </Sec>

        {/* ── INPUTS ── */}
        <Sec n="07" title="Inputs" desc="Filled fields on surface 2, with an orange focus hairline.">
          <Panel>
            <div style={grid(2)}>
              <Input label="Book title" value="Alice in Wonderland" />
              <Input label="Paste a link" placeholder="gutenberg.org/…" icon="link" />
              <Input label="Reward per milestone" value="2,100" suffix="sats" />
              <Input label="Circle name" placeholder="Mr. Lee's Class" />
            </div>
          </Panel>
        </Sec>

        {/* ── CARDS / ROWS / PROGRESS ── */}
        <Sec n="08" title="Cards, rows & progress">
          <div style={grid(2)}>
            <Panel label="List row">
              <Row lead={<Ava emoji="🦊" size={40} />} title="Wren" sub="page 18 · 12-day streak"
                trail={<Sats amount="12.4k" />} />
              <div style={{ height: 12 }} />
              <Row lead={<div style={{ width: 40, height: 40, borderRadius: 11, background: ZB.orangeDim, border: `1px solid ${ZB.orangeLine}`, display: 'grid', placeItems: 'center' }}><Bolt size={18} color={ZB.orangeSoft} /></div>}
                title="Reward per milestone" sub="what a passed quiz earns" trail={<Icon name="chevron" size={18} color={ZB.t3} />} />
            </Panel>
            <Panel label="Progress">
              <div style={{ marginBottom: 18 }}><div style={{ font: `500 12px/1 ${FONT_MONO}`, color: ZB.t3, marginBottom: 9 }}>reading · 64%</div><Progress value={0.64} /></div>
              <div style={{ marginBottom: 18 }}><div style={{ font: `500 12px/1 ${FONT_MONO}`, color: ZB.t3, marginBottom: 9 }}>quiz · 2 of 3</div><Progress value={0.66} color="#3DCB89" /></div>
              <div><div style={{ font: `500 12px/1 ${FONT_MONO}`, color: ZB.t3, marginBottom: 9 }}>circle · 38%</div><Progress value={0.38} color={ZB.purple} /></div>
            </Panel>
          </div>
        </Sec>

        {/* ── COVERS / AVATARS ── */}
        <Sec n="09" title="Book covers & avatars" desc="Covers carry a cover image whose edges feather and blend into the book surface. Drop-your-own art is supported. Avatars are a single picked emoji.">
          <Panel>
            <div style={{ display: 'flex', gap: 22, alignItems: 'flex-end', flexWrap: 'wrap' }}>
              <Cover w={104} h={146} hue="orange" title="Alice" author="Carroll" img="covers/alice.png" />
              <Cover w={104} h={146} hue="purple" title="Peter Pan" author="Barrie" img="covers/peterpan.png" />
              <Cover w={104} h={146} hue="mint" title="Oz" author="Baum" img="covers/oz.png" />
              <div style={{ display: 'flex', gap: 10, alignItems: 'center', marginLeft: 8 }}>
                {['🦊', '🐙', '🌿', '🪐', '🍄'].map((e, i) => <Ava key={i} emoji={e} size={48} />)}
              </div>
            </div>
          </Panel>
        </Sec>

        {/* ── PATTERNS ── */}
        <Sec n="10" title="Patterns" desc="The two surfaces that carry ZapBook's no-interrupt model: the floating pill and the persisted celebration card.">
          <div style={grid(2)}>
            <Panel label="Celebration pill (floating)">
              <Pill emoji="👏" text="Fatima finished Chapter 6" count={3} />
              <div style={{ height: 14 }} />
              <Pill emoji="🔥" text="Wren passed the quiz" />
            </Panel>
            <Panel label="Celebration card">
              <CelebrationCard unread emoji="🍄" name="Fatima" action="finished Chapter 6" time="12m"
                book="The Alchemist" score="3/3" reactions={[{ e: '👍', n: 3 }, { e: '👏', n: 5 }, { e: '🔥', n: 1 }]} />
            </Panel>
          </div>
        </Sec>

        {/* ── NAV ── */}
        <Sec n="11" title="Navigation" desc="Material bottom navigation with the active-pill indicator. Five tabs: Home, Circles, Cheers, Library, You.">
          <Panel label="Bottom nav">
            <div style={{ maxWidth: 402, margin: '0 auto', borderRadius: 20, overflow: 'hidden', border: `1px solid ${ZB.line}` }}>
              <MNav active="cheers" />
            </div>
          </Panel>
        </Sec>

      </div>
    </div>
  );
}

Object.assign(window, { DSPage });
