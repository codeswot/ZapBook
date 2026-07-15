# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.7] - 2026-06-21

### Added

- **Cheers:** Long-pressing a milestone now offers **Post as note** — publish it to Nostr as a public note (kind 1) so it shows up on Damus, Primal, and other clients. Opens an editable sheet pre-filled with the milestone message; post as is or tweak it first.
- **Cheers:** Copy, Share, and Post now share one uniform ZapBook message (first- or third-person, with book title and links) instead of ad-hoc text.

### Changed

- **Performance:** Resolved major scroll freezing and Application Not Responding (ANR) crashes in the reader by replacing memory-bloating page caching with highly efficient, on-demand SQLite database reads.
- **UX:** Share to Circle sheet now cleanly dismisses immediately upon sharing and completes the background process silently, only surfacing toasts when an error occurs.
- **UX:** Replaced jarring white screen spinner with a seamless, continuous shimmer loading effect while preparing books for reading.
- **UI:** Limited book titles on book cover cards to a maximum of 3 lines with ellipsis for improved consistency across varying title lengths.
