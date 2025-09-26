import { LitElement, html, css } from '../lib/simple-lit.js';

const MAX_POINTS = 8;

export class ScoreTrack extends LitElement {
  static properties = {
    you: { type: Number },
    opponent: { type: Number }
  };

  static styles = css`
    :host {
      display: inline-block;
      color: white;
      font-family: 'Segoe UI', sans-serif;
    }
    .label {
      font-size: 0.65rem;
      opacity: 0.8;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      margin-bottom: 0.35rem;
      display: flex;
      justify-content: space-between;
    }
    .track {
      display: grid;
      grid-template-columns: repeat(8, 1fr);
      gap: 4px;
    }
    .pip {
      width: 18px;
      height: 12px;
      border-radius: 999px;
      background: rgba(255,255,255,0.18);
      box-shadow: inset 0 0 4px rgba(0,0,0,0.45);
      transition: background 120ms ease, transform 150ms ease;
    }
    .pip.filled-you {
      background: linear-gradient(135deg, #2563eb, #38bdf8);
    }
    .pip.filled-opponent {
      background: linear-gradient(135deg, #ef4444, #f97316);
    }
  `;

  constructor() {
    super();
    this.you = 0;
    this.opponent = 0;
  }

  renderPips(filled, cls) {
    return Array.from({ length: MAX_POINTS }, (_, idx) => {
      const filledClass = idx < filled ? `filled-${cls}` : '';
      return `<div class="pip ${filledClass}"></div>`;
    }).join('');
  }

  render() {
    return html`
      <div class="label"><span>You</span><span>Opponent</span></div>
      <div class="track" aria-label="Your score">${this.renderPips(this.you, 'you')}</div>
      <div class="track" aria-label="Opponent score">${this.renderPips(this.opponent, 'opponent')}</div>
    `;
  }
}

customElements.define('score-track', ScoreTrack);
