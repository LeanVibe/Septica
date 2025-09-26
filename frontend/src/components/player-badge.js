import { LitElement, html, css } from '../lib/simple-lit.js';

export class PlayerBadge extends LitElement {
  static properties = {
    name: { type: String },
    country: { type: String },
    active: { type: Boolean },
    you: { type: Boolean },
    avatar: { type: String }
  };

  static styles = css`
    :host {
      display: inline-flex;
      align-items: center;
      gap: 0.6rem;
      font-family: 'Segoe UI', sans-serif;
      color: white;
    }
    .avatar {
      position: relative;
      width: 52px;
      height: 52px;
      border-radius: 50%;
      overflow: hidden;
      background: rgba(0,0,0,0.35);
    }
    .avatar img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
    }
    .ring {
      pointer-events: none;
      position: absolute;
      inset: -4px;
      border-radius: 50%;
      border: 4px solid transparent;
      transition: border-color 120ms ease;
    }
    .ring.active {
      border-color: #34d399;
      box-shadow: 0 0 12px rgba(52,211,153,0.7);
    }
    .info {
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
      line-height: 1.1;
    }
    .name {
      font-weight: 600;
      font-size: 0.95rem;
      letter-spacing: 0.03em;
    }
    .you {
      background: rgba(37,99,235,0.8);
      color: white;
      border-radius: 9999px;
      padding: 0 0.4rem;
      margin-left: 0.4rem;
      font-size: 0.65rem;
      letter-spacing: 0.06em;
      text-transform: uppercase;
    }
    .flag {
      width: 18px;
      height: 12px;
      border-radius: 2px;
      overflow: hidden;
      box-shadow: 0 0 4px rgba(0,0,0,0.35);
      background: rgba(255,255,255,0.1);
    }
    .fallback-avatar {
      width: 100%;
      height: 100%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 1.25rem;
      background: rgba(255,255,255,0.12);
    }
  `;

  constructor() {
    super();
    this.name = '';
    this.country = '';
    this.active = false;
    this.you = false;
    this.avatar = '';
  }

  render() {
    const initials = (this.name || '?').trim().split(/\s+/).map(part => part[0]?.toUpperCase() ?? '').join('').slice(0,2) || '?';
    return html`
      <div class="avatar">
        ${this.avatar ? `<img src="${this.avatar}" alt="${this.name}">` : `<div class="fallback-avatar">${initials}</div>`}
        <div class="ring ${this.active ? 'active' : ''}"></div>
      </div>
      <div class="info">
        <div class="name">${this.name || 'Opponent'}${this.you ? `<span class="you">You</span>` : ''}</div>
        ${this.country ? `<div class="flag"><img src="https://flagcdn.com/24x18/${this.country.toLowerCase()}.png" width="18" height="12" alt="${this.country}"></div>` : ''}
      </div>
    `;
  }
}

customElements.define('player-badge', PlayerBadge);
