/* ZapBook — Ember · onboarding flow.
   Welcome → 1 Nostr identity → 2 Lightning wallet → 3 AI model → 4 Library
   (empty → first book → soft "start a circle?" prompt). Dark Material You.
   Nostr steps lean purple; sats/wallet leans orange. */

// ── stepper ──
function Stepper({ step, total = 4 }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
      <div style={{ flex: 1, display: 'flex', gap: 6 }}>
        {Array.from({ length: total }).map((_, i) => (
          <div key={i} style={{ flex: 1, height: 6, borderRadius: 999,
            background: i < step ? ZB.orange : i === step ? ZB.orangeDim : ZB.s3,
            border: i === step ? `1px solid ${ZB.orangeLine}` : '1px solid transparent' }} />
        ))}
      </div>
      <span style={{ font: `600 12.5px/1 ${FONT_MONO}`, color: ZB.t3, whiteSpace: 'nowrap' }}>{step + 1} of {total}</span>
    </div>
  );
}

// ── onboarding shell: top stepper, scrollable body, pinned footer ──
function OB({ step, accent = 'orange', icon, iconEmoji, over, title, desc, children, primary, secondary, back = true }) {
  const tint = accent === 'purple' ? ZB.purpleDim : ZB.orangeDim;
  const line = accent === 'purple' ? ZB.purpleLine : ZB.orangeLine;
  const soft = accent === 'purple' ? ZB.purpleSoft : ZB.orangeSoft;
  return (
    <Screen style={{ background: ZB.bg }}>
      <div style={{ flex: 'none', paddingTop: SAFE_TOP }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14, padding: '10px 20px 18px' }}>
          {back && <div style={{ width: 34, height: 34, borderRadius: 999, flex: 'none', background: ZB.s2, border: `1px solid ${ZB.line}`, display: 'grid', placeItems: 'center' }}>
            <Icon name="chevron" size={18} color={ZB.t2} style={{ transform: 'rotate(180deg)' }} />
          </div>}
          <div style={{ flex: 1 }}><Stepper step={step} /></div>
        </div>
      </div>

      <div style={{ flex: 1, overflow: 'hidden', padding: '12px 24px 0' }}>
        <div style={{ width: 76, height: 76, borderRadius: 24, background: tint, border: `1px solid ${line}`, display: 'grid', placeItems: 'center', marginBottom: 24 }}>
          {iconEmoji ? <span style={{ fontSize: 36 }}>{iconEmoji}</span> : <Icon name={icon} size={36} color={soft} sw={1.9} />}
        </div>
        {over && <div style={{ font: `700 12px/1 ${FONT_BODY}`, letterSpacing: '0.13em', textTransform: 'uppercase', color: soft, marginBottom: 12 }}>{over}</div>}
        <h1 style={{ font: `700 31px/1.08 ${FONT_DISPLAY}`, letterSpacing: '-0.025em', color: ZB.t1, margin: 0 }}>{title}</h1>
        <p style={{ font: `400 16.5px/1.5 ${FONT_BODY}`, color: ZB.t2, margin: '14px 0 0', maxWidth: 360 }}>{desc}</p>
        <div style={{ marginTop: 26 }}>{children}</div>
      </div>

      <div style={{ flex: 'none', padding: `16px 22px ${SAFE_BOT + 14}px`, display: 'flex', flexDirection: 'column', gap: 11 }}>
        {primary}
        {secondary}
      </div>
    </Screen>
  );
}

// ─────────────── WELCOME ───────────────
function OBWelcome() {
  return (
    <Screen style={{ background: ZB.bg }}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: `${SAFE_TOP}px 30px 0`, textAlign: 'center' }}>
        <div style={{ width: 96, height: 96, borderRadius: 30, background: ZB.orange, display: 'grid', placeItems: 'center', marginBottom: 34 }}>
          <Bolt size={50} color="#241500" />
        </div>
        <div style={{ font: `700 40px/1 ${FONT_DISPLAY}`, letterSpacing: '-0.03em', color: ZB.t1 }}>Zap<span style={{ fontWeight: 800 }}>Book</span></div>
        <p style={{ font: `400 19px/1.5 ${FONT_BODY}`, color: ZB.t2, margin: '20px 0 0', maxWidth: 320 }}>
          Read books together. Prove you read them. Get zapped real sats by your circle.
        </p>
        <div style={{ display: 'flex', gap: 18, marginTop: 34 }}>
          {[['📖', 'Read'], ['✓', 'Prove'], ['⚡', 'Get zapped']].map((s, i) => (
            <div key={i} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 9 }}>
              <div style={{ width: 50, height: 50, borderRadius: 16, background: ZB.s2, border: `1px solid ${ZB.line}`, display: 'grid', placeItems: 'center', fontSize: 22 }}>{s[0]}</div>
              <span style={{ font: `500 12px/1 ${FONT_BODY}`, color: ZB.t3 }}>{s[1]}</span>
            </div>
          ))}
        </div>
      </div>
      <div style={{ flex: 'none', padding: `0 24px ${SAFE_BOT + 16}px`, display: 'flex', flexDirection: 'column', gap: 11 }}>
        <Button variant="primary" size="lg" full iconR="arrowR">Get started</Button>
        <Button variant="ghost" size="md" full>I already have a key</Button>
      </div>
    </Screen>
  );
}

// ─────────────── STEP 1 · NOSTR IDENTITY ───────────────
function OBIdentity() {
  return (
    <OB step={0} accent="purple" icon="key" over="Step 1 · Identity" title="Your Nostr identity"
      desc="Your account is a key that belongs to you — no email, no password, no company holding it."
      primary={<Button variant="purple" size="lg" full iconR="arrowR">I've saved my key</Button>}
      secondary={<Button variant="ghost" size="md" full icon="download">Import an existing nsec</Button>}>

      {/* generate / import toggle */}
      <div style={{ display: 'flex', gap: 6, padding: 5, borderRadius: 14, background: ZB.s2, border: `1px solid ${ZB.line}`, marginBottom: 18 }}>
        <div style={{ flex: 1, textAlign: 'center', padding: '10px 0', borderRadius: 10, background: ZB.s4, border: `1px solid ${ZB.line2}`, font: `700 14px/1 ${FONT_BODY}`, color: ZB.t1 }}>Generate new</div>
        <div style={{ flex: 1, textAlign: 'center', padding: '10px 0', borderRadius: 10, font: `600 14px/1 ${FONT_BODY}`, color: ZB.t3 }}>Import nsec</div>
      </div>

      {/* generated public key */}
      <div style={{ background: ZB.s2, border: `1px solid ${ZB.line}`, borderRadius: 18, padding: 16, marginBottom: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
          <span style={{ font: `600 12px/1 ${FONT_BODY}`, letterSpacing: '0.05em', textTransform: 'uppercase', color: ZB.purpleSoft }}>Your public key</span>
          <div style={{ display: 'flex', gap: 7 }}>
            <div style={{ width: 30, height: 30, borderRadius: 9, background: ZB.s3, border: `1px solid ${ZB.line}`, display: 'grid', placeItems: 'center' }}><Icon name="copy" size={15} color={ZB.t2} /></div>
            <div style={{ width: 30, height: 30, borderRadius: 9, background: ZB.s3, border: `1px solid ${ZB.line}`, display: 'grid', placeItems: 'center' }}><Icon name="refresh" size={15} color={ZB.t2} /></div>
          </div>
        </div>
        <div style={{ font: `500 13.5px/1.5 ${FONT_MONO}`, color: ZB.t1, wordBreak: 'break-all' }}>npub1q8s7f<span style={{ color: ZB.t3 }}>x4k2m9v0pe3rt6yu7c5l8wd2na6hg4</span>j0zq</div>
      </div>

      <Banner tone="warning" title="Save your secret key">Write down or store your nsec somewhere safe. If you lose it, nobody — including us — can get your account back.</Banner>
    </OB>
  );
}

// ─────────────── STEP 2 · LIGHTNING WALLET ───────────────
function OBWallet() {
  return (
    <OB step={1} accent="orange" icon="wallet" over="Step 2 · Wallet" title="Where your sats land"
      desc="Connect a Lightning address so the sats you earn reading can be zapped straight to you."
      primary={<Button variant="primary" size="lg" full iconR="arrowR">Connect wallet</Button>}
      secondary={<Button variant="ghost" size="md" full>Skip — set up later</Button>}>

      <Input label="Lightning address (lud16)" value="wren@walletofsatoshi.com" icon="wallet" />

      <div style={{ marginTop: 14 }}>
        <Banner tone="info" title="No wallet yet?">Any Lightning address works — Wallet of Satoshi, Alby, Phoenix, and more. You can always add it later from settings.</Banner>
      </div>

      {/* quick providers */}
      <div style={{ marginTop: 18 }}>
        <div style={{ font: `600 11.5px/1 ${FONT_BODY}`, letterSpacing: '0.06em', textTransform: 'uppercase', color: ZB.t3, marginBottom: 11 }}>Popular wallets</div>
        <div style={{ display: 'flex', gap: 9 }}>
          {['Wallet of Satoshi', 'Alby', 'Phoenix'].map((p, i) => (
            <div key={i} style={{ flex: 1, textAlign: 'center', padding: '11px 6px', borderRadius: 13, background: ZB.s2, border: `1px solid ${ZB.line}`, font: `600 12px/1.2 ${FONT_BODY}`, color: ZB.t2 }}>{p}</div>
          ))}
        </div>
      </div>
    </OB>
  );
}

// ─────────────── STEP 3 · AI MODEL ───────────────
function OBModel() {
  return (
    <OB step={2} accent="purple" icon="cpu" over="Step 3 · On-device AI" title="Reading checks, on your phone"
      desc="ZapBook uses a small AI model to turn books into clean pages and write the milestone quizzes — running entirely on your device."
      primary={<Button variant="purple" size="lg" full icon="download">Download model · 1.1 GB</Button>}
      secondary={<Button variant="ghost" size="md" full>Skip for now</Button>}>

      {/* model card */}
      <div style={{ background: ZB.s2, border: `1px solid ${ZB.line}`, borderRadius: 18, padding: 16, marginBottom: 14 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{ width: 48, height: 48, borderRadius: 14, flex: 'none', background: ZB.purpleDim, border: `1px solid ${ZB.purpleLine}`, display: 'grid', placeItems: 'center' }}>
            <Icon name="sparkle" size={24} color={ZB.purpleSoft} fill />
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ font: `700 17px/1.1 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>Gemma 3n · 4B</div>
            <div style={{ font: `500 12.5px/1 ${FONT_MONO}`, color: ZB.t3, marginTop: 6 }}>1.1 GB · runs offline</div>
          </div>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '7px 11px', borderRadius: 999, background: 'rgba(61,203,137,0.13)', border: '1px solid rgba(61,203,137,0.34)' }}>
            <Icon name="check" size={13} color="#5BD79B" sw={2.6} />
            <span style={{ font: `600 11.5px/1 ${FONT_BODY}`, color: '#5BD79B' }}>Supported</span>
          </div>
        </div>
      </div>

      <Banner tone="info" title="Nothing leaves your device">Books, quizzes, and your reading are processed locally. ZapBook never uploads them.</Banner>
    </OB>
  );
}

// ─────────────── STEP 4 · EMPTY LIBRARY ───────────────
function OBLibraryEmpty() {
  return (
    <Screen style={{ background: ZB.bg }}>
      <div style={{ flex: 'none', paddingTop: SAFE_TOP, padding: `${SAFE_TOP}px 20px 0` }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
          <h1 style={{ font: `700 28px/1.05 ${FONT_DISPLAY}`, letterSpacing: '-0.02em', color: ZB.t1, margin: 0 }}>Your shelf</h1>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 6, padding: '8px 12px', borderRadius: 999, background: 'rgba(61,203,137,0.13)', border: '1px solid rgba(61,203,137,0.34)' }}>
            <Icon name="check" size={14} color="#5BD79B" sw={2.6} />
            <span style={{ font: `600 12px/1 ${FONT_BODY}`, color: '#5BD79B' }}>All set</span>
          </div>
        </div>
      </div>

      {/* empty state */}
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '0 36px', textAlign: 'center' }}>
        {/* ghost shelf */}
        <div style={{ display: 'flex', gap: 14, marginBottom: 30 }}>
          {[0, 1, 2].map((i) => (
            <div key={i} style={{ width: 64, height: 92, borderRadius: 12, background: ZB.s1, border: `1.5px dashed ${ZB.line2}`, opacity: i === 1 ? 1 : 0.5 }} />
          ))}
        </div>
        <div style={{ font: `700 22px/1.2 ${FONT_DISPLAY}`, color: ZB.t1, letterSpacing: '-0.01em' }}>Your shelf is empty</div>
        <p style={{ font: `400 15.5px/1.5 ${FONT_BODY}`, color: ZB.t3, margin: '12px 0 0', maxWidth: 280 }}>
          Add a book to start reading — drop an ePub, paste a link, or pick a free classic.
        </p>
        <div style={{ marginTop: 26 }}>
          <Button variant="primary" size="lg" icon="plus">Add your first book</Button>
        </div>
      </div>

      <MNav active="library" />
    </Screen>
  );
}

// ─────────────── AFTER FIRST BOOK · SOFT CIRCLE PROMPT ───────────────
function OBCirclePrompt() {
  return (
    <Screen style={{ background: ZB.bg }}>
      {/* library with the first book, dimmed behind the sheet */}
      <div style={{ position: 'absolute', inset: 0, padding: `${SAFE_TOP}px 20px 0`, opacity: 0.5 }}>
        <h1 style={{ font: `700 28px/1.05 ${FONT_DISPLAY}`, letterSpacing: '-0.02em', color: ZB.t1, margin: '0 0 22px' }}>Your shelf</h1>
        <div style={{ display: 'flex', gap: 14 }}>
          <Cover w={100} h={140} hue="orange" title="Alice" author="Carroll" img="covers/alice.png" />
        </div>
      </div>

      <Sheet>
        <div style={{ padding: '8px 24px 4px', textAlign: 'center', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <div style={{ width: 76, height: 76, borderRadius: 24, background: ZB.purpleDim, border: `1px solid ${ZB.purpleLine}`, display: 'grid', placeItems: 'center', marginBottom: 20 }}>
            <Icon name="circles" size={34} color={ZB.purpleSoft} sw={1.9} />
          </div>
          <div style={{ font: `700 12px/1 ${FONT_BODY}`, letterSpacing: '0.12em', textTransform: 'uppercase', color: ZB.purpleSoft, marginBottom: 12 }}>Nice — first book added</div>
          <h2 style={{ font: `700 26px/1.12 ${FONT_DISPLAY}`, letterSpacing: '-0.02em', color: ZB.t1, margin: 0, maxWidth: 320 }}>Start a reading circle with Alice in Wonderland?</h2>
          <p style={{ font: `400 15.5px/1.5 ${FONT_BODY}`, color: ZB.t2, margin: '14px 0 0', maxWidth: 320 }}>
            Invite up to 100 people to read it together. Anyone in the circle can zap anyone who hits a milestone.
          </p>
        </div>
        <div style={{ padding: '22px 22px 4px', display: 'flex', flexDirection: 'column', gap: 11 }}>
          <Button variant="purple" size="lg" full icon="circles">Yes, create a circle</Button>
          <Button variant="ghost" size="md" full>Not now — just read</Button>
        </div>
      </Sheet>
    </Screen>
  );
}

Object.assign(window, { OBWelcome, OBIdentity, OBWallet, OBModel, OBLibraryEmpty, OBCirclePrompt });
