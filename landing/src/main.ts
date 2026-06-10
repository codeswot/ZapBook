import './style.css';
import {
  createIcons,
  Moon,
  Sun,
  BookOpen,
  Zap,
  Globe,
  Database,
  Lock,
  Users,
  Sticker,
  BadgeHelp,
  ArrowLeft,
  ArrowRight,
  Brain
} from 'lucide';

const icons = {
  Moon,
  Sun,
  BookOpen,
  Zap,
  Globe,
  Database,
  Lock,
  Users,
  Sticker,
  BadgeHelp,
  ArrowLeft,
  ArrowRight,
  Brain
};

createIcons({ icons });

const deckPrev = document.getElementById('deck-prev');
const deckNext = document.getElementById('deck-next');
const deckProgress = document.getElementById('deck-progress');
const slides = document.querySelectorAll('.deck-slide');
const navLinks = document.querySelectorAll('.nav-links a');

let currentSlide = 0;

function updateProgress() {
  if (deckProgress && slides.length) {
    deckProgress.textContent = `Page ${currentSlide + 1} of ${slides.length}`;
  }
  navLinks.forEach(link => {
    const href = link.getAttribute('href');
    if (href === `#${slides[currentSlide].id}`) {
      link.classList.add('active');
    } else {
      link.classList.remove('active');
    }
  });
}

function scrollToSlide(index: number) {
  if (index >= 0 && index < slides.length) {
    slides[index].scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
}

if (deckPrev) {
  deckPrev.addEventListener('click', () => {
    if (currentSlide > 0) {
      scrollToSlide(currentSlide - 1);
    }
  });
}

if (deckNext) {
  deckNext.addEventListener('click', () => {
    if (currentSlide < slides.length - 1) {
      scrollToSlide(currentSlide + 1);
    }
  });
}

document.addEventListener('keydown', (e) => {
  const target = e.target as HTMLElement;
  if (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA') return;
  if (e.key === 'ArrowRight' || e.key === ' ') {
    if (currentSlide < slides.length - 1) {
      scrollToSlide(currentSlide + 1);
      e.preventDefault();
    }
  } else if (e.key === 'ArrowLeft') {
    if (currentSlide > 0) {
      scrollToSlide(currentSlide - 1);
      e.preventDefault();
    }
  }
});

const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const idx = Array.from(slides).indexOf(entry.target);
      if (idx !== -1) {
        currentSlide = idx;
        updateProgress();
      }
    }
  });
}, {
  threshold: 0.3
});

slides.forEach(slide => observer.observe(slide));
updateProgress();
