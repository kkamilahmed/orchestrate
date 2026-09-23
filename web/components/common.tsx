'use client';

import { useEffect, useRef, type ReactNode } from 'react';
import { AILabel, AILabelContent } from '@carbon/react';
import { ChatBot } from '@carbon/icons-react';

export const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

export function UserMessage({ text }: { text: string }) {
  return (
    <div className="msg msg--user">
      <div className="msg__bubble">{text}</div>
    </div>
  );
}

export function AssistantMessage({ children, scrollOnMount = false }: { children: ReactNode; scrollOnMount?: boolean }) {
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (scrollOnMount && ref.current) scrollToElement(ref.current);
  }, [scrollOnMount]);
  return (
    <div className="msg msg--assistant" ref={ref}>
      <div className="msg__avatar" aria-hidden="true">
        <ChatBot size={24} />
      </div>
      <div className="msg__body">{children}</div>
    </div>
  );
}

// Carbon for AI: the AI label, with an explanation popover.
export function AiBadge({ title, children }: { title: string; children?: ReactNode }) {
  return (
    <AILabel size="xs" autoAlign aria-label="AI explained">
      <AILabelContent>
        <div className="ai-explain">
          <p className="ai-explain__eyebrow">AI explained</p>
          <p className="ai-explain__title">{title}</p>
          <div className="ai-explain__body">{children}</div>
        </div>
      </AILabelContent>
    </AILabel>
  );
}

export function scroller(): HTMLElement | null {
  return document.getElementById('scroller');
}

export function scrollToElement(el: HTMLElement) {
  const sc = scroller();
  if (!sc) return;
  const top = el.getBoundingClientRect().top - sc.getBoundingClientRect().top + sc.scrollTop - 24;
  sc.scrollTo({ top, behavior: 'smooth' });
}

export function scrollToBottom(force = false) {
  const sc = scroller();
  if (!sc) return;
  if (force || sc.scrollHeight - sc.scrollTop - sc.clientHeight < 280) sc.scrollTop = sc.scrollHeight;
}

// Numbers in agent steps come from real query results; they are highlighted.
export function HighlightNumbers({ text }: { text: string }) {
  const parts = text.split(/(\b\d+(?:[.,]\d+)?%?)/);
  return (
    <>
      {parts.map((p, i) => (i % 2 ? <strong key={i}>{p}</strong> : p))}
    </>
  );
}

export function relativeTime(iso: string, short = false) {
  const diff = (Date.now() - new Date(iso).getTime()) / 1000;
  if (diff < 45) return 'just now';
  const mins = Math.round(diff / 60);
  if (mins < 60) return short ? `${mins}m` : `${mins} min ago`;
  const hours = Math.round(mins / 60);
  if (hours < 24) return short ? `${hours}h` : `${hours} hr ago`;
  const days = Math.round(hours / 24);
  return short ? `${days}d` : `${days} day${days === 1 ? '' : 's'} ago`;
}
