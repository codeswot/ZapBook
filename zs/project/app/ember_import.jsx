/* ZapBook — Ember · book import flow.
   Upload / link → on-device (Gemma) processing into structured pages +
   auto-generated milestone quizzes → confirm + set reward → shelf or circle. */

function ImportUpload() {
  return (
    <Screen style={{ background: ZB.bg }}>
      <div style={{ flex: 1, overflow: 'hidden', padding: `${SAFE_TOP + 8}px 20px 8px` }}>
        <div style={{ font: `600 13px/1 ${FONT_BODY}`, letterSpacing: '0.04em', color: ZB.orangeSoft, textTransform: 'uppercase', marginBottom: 8 }}>Library</div>
        <h1 style={{ font: `700 28px/1.05 ${FONT_DISPLAY}`, letterSpacing: '-0.02em', color: ZB.t1, margin: '0 0 22px' }}>Add a book</h1>

        {/* drop zone */}
        <div style={{ borderRadius: 24, border: `1.5px dashed ${ZB.line2}`, background: ZB.s1, padding: '38px 20px', textAlign: 'center', marginBottom: 18 }}>
          <div style={{ width: 64, height: 64, borderRadius: 20, margin: '0 auto 18px', display: 'grid', placeItems: 'center', background: ZB.orangeDim, border: `1px solid ${ZB.orangeLine}` }}>
            <Icon name="upload" size={28} color={ZB.orangeSoft} sw={2} />
          </div>
          <div style={{ font: `700 18px/1.2 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>Drop an ePub or PDF</div>
          <div style={{ font: `400 13.5px/1.5 ${FONT_BODY}`, color: ZB.t3, marginTop: 8, maxWidth: 260, marginInline: 'auto' }}>We turn it into clean, structured pages on your device.</div>
          <div style={{ marginTop: 18 }}><Button variant="tonal" size="md">Browse files</Button></div>
        </div>

        {/* link */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '0 0 18px' }}>
          <div style={{ flex: 1, height: 1, background: ZB.line }} />
          <span style={{ font: `500 12px/1 ${FONT_BODY}`, color: ZB.t3 }}>or paste a link</span>
          <div style={{ flex: 1, height: 1, background: ZB.line }} />
        </div>
        <div style={{ display: 'flex', gap: 10, marginBottom: 26 }}>
          <Input icon="link" placeholder="gutenberg.org/…" style={{ flex: 1 }} />
          <Button variant="primary" size="lg">Add</Button>
        </div>

        {/* suggestions */}
        <div style={{ font: `700 16px/1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em', marginBottom: 13 }}>Free to start with</div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {[['Alice in Wonderland', 'Lewis Carroll', 'orange', 'covers/alice.png'], ['The Wonderful Wizard of Oz', 'L. Frank Baum', 'mint', 'covers/oz.png']].map((b, i) => (
            <Row key={i} lead={<Cover w={38} h={54} hue={b[2]} img={b[3]} r={9} />} title={b[0]} sub={b[1]}
              trail={<div style={{ width: 36, height: 36, borderRadius: 999, background: ZB.s3, border: `1px solid ${ZB.line}`, display: 'grid', placeItems: 'center' }}><Icon name="plus" size={18} color={ZB.t2} sw={2.2} /></div>} />
          ))}
        </div>
      </div>
      <MNav active="library" />
    </Screen>
  );
}

function StepRow({ state, label, detail }) {
  const done = state === 'done', active = state === 'active';
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '13px 0' }}>
      <div style={{ width: 30, height: 30, borderRadius: 999, flex: 'none', display: 'grid', placeItems: 'center',
        background: done ? 'rgba(61,203,137,0.16)' : active ? ZB.orangeDim : ZB.s2,
        border: `1px solid ${done ? 'rgba(61,203,137,0.4)' : active ? ZB.orangeLine : ZB.line}` }}>
        {done ? <Icon name="check" size={15} color="#5BD79B" sw={2.6} />
          : active ? <Bolt size={14} color={ZB.orangeSoft} />
          : <div style={{ width: 7, height: 7, borderRadius: 999, background: ZB.t3 }} />}
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ font: `${active ? 700 : 600} 15px/1.1 ${FONT_BODY}`, color: done || active ? ZB.t1 : ZB.t3 }}>{label}</div>
        {active && detail && <div style={{ font: `500 12px/1 ${FONT_MONO}`, color: ZB.t3, marginTop: 6 }}>{detail}</div>}
      </div>
    </div>
  );
}

function ImportProcessing() {
  return (
    <Screen style={{ background: ZB.bg }}>
      <div style={{ flex: 1, overflow: 'hidden', padding: `${SAFE_TOP + 16}px 24px 8px`, display: 'flex', flexDirection: 'column' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginBottom: 28 }}>
          <Cover w={64} h={90} hue="orange" title="Alice" author="Carroll" r={12} img="covers/alice.png" />
          <div>
            <div style={{ font: `700 20px/1.1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>Alice in Wonderland</div>
            <div style={{ font: `500 13px/1 ${FONT_BODY}`, color: ZB.t2, marginTop: 7 }}>Lewis Carroll</div>
          </div>
        </div>

        <div style={{ font: `700 24px/1.1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.02em', marginBottom: 6 }}>Preparing your book</div>
        {/* on-device badge */}
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8, padding: '8px 13px', borderRadius: 999, background: ZB.purpleDim, border: `1px solid ${ZB.purpleLine}`, width: 'fit-content', marginTop: 14, marginBottom: 8 }}>
          <Icon name="cpu" size={15} color={ZB.purpleSoft} sw={2} />
          <span style={{ font: `600 12.5px/1 ${FONT_BODY}`, color: ZB.purpleSoft }}>Gemma · running on your device</span>
        </div>

        <div style={{ marginTop: 10 }}>
          <StepRow state="done" label="Read the file" />
          <StepRow state="done" label="Split into 12 chapters" />
          <StepRow state="active" label="Structuring pages" detail="page 41 of 64…" />
          <StepRow state="todo" label="Writing milestone quizzes" />
        </div>

        <div style={{ marginTop: 18 }}>
          <Progress value={0.64} />
        </div>

        <div style={{ marginTop: 'auto', marginBottom: 8 }}>
          <Banner tone="info" title="Stays on your device">Nothing is uploaded. The book and your reading never leave your phone.</Banner>
        </div>
      </div>
    </Screen>
  );
}

function ImportConfirm() {
  return (
    <Screen style={{ background: ZB.bg }}>
      <div style={{ flex: 1, overflow: 'hidden', padding: `${SAFE_TOP + 8}px 22px 8px` }}>
        <div style={{ font: `600 13px/1 ${FONT_BODY}`, letterSpacing: '0.04em', color: '#5BD79B', textTransform: 'uppercase', marginBottom: 14 }}>Ready</div>

        <div style={{ display: 'flex', gap: 18, marginBottom: 22 }}>
          <Cover w={96} h={134} hue="orange" title="Alice" author="Carroll" slot="imp-cover" img="covers/alice.png" />
          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <Input label="Title" value="Alice in Wonderland" />
            <Input label="Author" value="Lewis Carroll" />
          </div>
        </div>

        {/* stats */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 10, marginBottom: 18 }}>
          {[['12', 'chapters'], ['12', 'quizzes'], ['2h', 'to read']].map((s, i) => (
            <div key={i} style={{ background: ZB.s1, border: `1px solid ${ZB.line}`, borderRadius: 16, padding: '14px 12px' }}>
              <div style={{ font: `700 24px/1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.02em', fontVariantNumeric: 'tabular-nums' }}>{s[0]}</div>
              <div style={{ font: `500 11.5px/1.2 ${FONT_BODY}`, color: ZB.t3, marginTop: 6 }}>{s[1]}</div>
            </div>
          ))}
        </div>

        {/* reward per milestone */}
        <Card pad={16} r={20} style={{ marginBottom: 18 }}>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{ width: 42, height: 42, borderRadius: 13, display: 'grid', placeItems: 'center', background: ZB.orangeDim, border: `1px solid ${ZB.orangeLine}` }}>
                <Bolt size={19} color={ZB.orangeSoft} />
              </div>
              <div>
                <div style={{ font: `700 15px/1.1 ${FONT_DISPLAY}`, color: ZB.t1 }}>Reward per milestone</div>
                <div style={{ font: `500 12px/1 ${FONT_BODY}`, color: ZB.t3, marginTop: 6 }}>what a passed quiz earns</div>
              </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px', borderRadius: 12, background: ZB.s3, border: `1px solid ${ZB.line2}` }}>
              <span style={{ font: `700 15px/1 ${FONT_MONO}`, color: ZB.t1, fontVariantNumeric: 'tabular-nums' }}>2,100</span>
              <Icon name="pen" size={14} color={ZB.t3} sw={2} />
            </div>
          </div>
        </Card>
      </div>

      <div style={{ flex: 'none', padding: `0 22px ${SAFE_BOT + 18}px`, display: 'flex', flexDirection: 'column', gap: 11 }}>
        <Button variant="primary" size="lg" full>Add to my shelf</Button>
        <Button variant="purple" size="md" full icon="circles">Start a circle with this book</Button>
      </div>
    </Screen>
  );
}

Object.assign(window, { ImportUpload, ImportProcessing, ImportConfirm });
