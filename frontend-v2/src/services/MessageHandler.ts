export type MessagePayload = Record<string, unknown>;

export interface SocketMessage {
  type: string;
  payload?: MessagePayload;
  [key: string]: unknown;
}

export type MessageHandlerFn = (message: SocketMessage) => void;

export class MessageHandler {
  private handlers = new Map<string, MessageHandlerFn>();
  private onAnyHandler: MessageHandlerFn | null = null;

  setHandler(type: string, handler: MessageHandlerFn) {
    this.handlers.set(type, handler);
  }

  clearHandler(type: string) {
    this.handlers.delete(type);
  }

  setOnAny(handler: MessageHandlerFn | null) {
    this.onAnyHandler = handler;
  }

  handleRawMessage(data: string) {
    const messages = this.splitMessages(data);
    for (const raw of messages) {
      const trimmed = raw.trim();
      if (!trimmed) continue;
      try {
        const message = JSON.parse(trimmed) as SocketMessage;
        const handler = this.handlers.get(message.type);
        if (handler) handler(message);
        if (this.onAnyHandler) this.onAnyHandler(message);
      } catch (error) {
        // Ignore malformed messages
        // eslint-disable-next-line no-console
        console.error('Failed to parse websocket message', error);
      }
    }
  }

  private splitMessages(data: string): string[] {
    const messages: string[] = [];
    let remaining = data;

    while (remaining.trim()) {
      let depth = 0;
      let inString = false;
      let escaped = false;
      let messageEnd = -1;

      for (let i = 0; i < remaining.length; i += 1) {
        const char = remaining[i];

        if (escaped) {
          escaped = false;
          continue;
        }

        if (char === '\\') {
          escaped = true;
          continue;
        }

        if (char === '"') {
          inString = !inString;
          continue;
        }

        if (!inString) {
          if (char === '{') {
            depth += 1;
          } else if (char === '}') {
            depth -= 1;
            if (depth === 0) {
              messageEnd = i + 1;
              break;
            }
          }
        }
      }

      if (messageEnd > 0) {
        messages.push(remaining.slice(0, messageEnd));
        remaining = remaining.slice(messageEnd);
      } else {
        messages.push(remaining);
        break;
      }
    }

    return messages;
  }
}
