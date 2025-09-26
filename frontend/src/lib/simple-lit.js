export const html = (strings, ...values) => strings.reduce((acc, str, idx) => {
  const value = idx < values.length ? values[idx] : '';
  return acc + str + value;
}, '');

export const css = (...args) => html(...args);

export class LitElement extends HTMLElement {
  constructor() {
    super();
    if (!this.shadowRoot) {
      this.attachShadow({ mode: 'open' });
    }
    this.__updateTimer = null;
    this.__didFirstUpdate = false;
    this.__lastRender = null;
  }

  static get properties() {
    return {};
  }

  static get styles() {
    return null;
  }

  static get observedAttributes() {
    const props = this.properties ?? {};
    return Object.entries(props)
      .filter(([, options]) => (options?.attribute ?? true) !== false)
      .map(([key, options]) => typeof options?.attribute === 'string' ? options.attribute : key.toLowerCase());
  }

  attributeChangedCallback(name, oldValue, newValue) {
    if (oldValue === newValue) return;
    const props = this.constructor.properties ?? {};
    for (const [key, options] of Object.entries(props)) {
      const attrName = typeof options?.attribute === 'string' ? options.attribute : key.toLowerCase();
      if (attrName === name) {
        const type = options?.type ?? String;
        this[key] = type === Number ? Number(newValue) : type === Boolean ? newValue !== null && newValue !== 'false' : newValue;
        break;
      }
    }
    this.requestUpdate();
  }

  connectedCallback() {
    super.connectedCallback?.();
    this.requestUpdate();
  }

  setProperty(key, value) {
    if (this[key] === value) return;
    this[key] = value;
    this.requestUpdate();
  }

  requestUpdate() {
    clearTimeout(this.__updateTimer);
    this.__updateTimer = setTimeout(() => this.update(), 0);
  }

  update() {
    const template = this.render?.();
    if (template == null) return;
    const styles = this.constructor.styles;
    const htmlText = `${styles ? `<style>${styles}</style>` : ''}${template}`;
    const first = !this.__didFirstUpdate;
    if (htmlText !== this.__lastRender) {
      this.shadowRoot.innerHTML = htmlText;
      this.__lastRender = htmlText;
    }
    if (first) {
      this.__didFirstUpdate = true;
      this.firstUpdated?.();
    }
    this.updated?.();
  }
}
