'use client';

import { useEffect, useState } from 'react';
import { InlineLoading } from '@carbon/react';
import { CheckmarkFilled } from '@carbon/icons-react';
import { AiBadge, AssistantMessage, HighlightNumbers, scrollToBottom, sleep } from './common';
import { iconFor } from '@/lib/icons';

const STEP_MS = { full: 800, compact: 520 };

// How long the animation takes, so a caller can wait for it before streaming the answer.
export function stepsDuration(count: number, compact: boolean) {
  return count * (compact ? STEP_MS.compact : STEP_MS.full) + 250;
}

type Props = {
  title: string;
  icon: string;
  steps: string[];
  compact?: boolean;
  animate?: boolean;
  onDone?: () => void;
};

export default function AgentSteps({ title, icon, steps, compact = false, animate = true, onDone }: Props) {
  const [done, setDone] = useState(animate ? 0 : steps.length);
  const Icon = iconFor(icon);

  useEffect(() => {
    if (!animate) return;
    let cancelled = false;
    (async () => {
      for (let i = 0; i < steps.length; i++) {
        await sleep(compact ? STEP_MS.compact : STEP_MS.full);
        if (cancelled) return;
        setDone(i + 1);
        scrollToBottom();
      }
      await sleep(250);
      if (!cancelled) onDone?.();
    })();
    return () => {
      cancelled = true;
    };
    // Runs once per mount: the steps are fixed for a flow run.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const visible = steps.slice(0, Math.min(steps.length, done + 1));
  return (
    <AssistantMessage scrollOnMount>
      <div className="card">
        <div className="card__head">
          <Icon size={20} className="card__head-icon" />
          <div>
            <h3 className="card__title">{title}</h3>
            <p className="card__subtitle">
              {done >= steps.length ? `Completed ${steps.length} step${steps.length === 1 ? '' : 's'}` : 'Agent is working'}
            </p>
          </div>
          <div className="card__head-right">
            <AiBadge title="Agent steps">
              <p>Each step runs a named query against your systems. The numbers shown are the real query results, not estimates.</p>
            </AiBadge>
          </div>
        </div>
        <ul className="steps">
          {visible.map((text, i) => {
            const isDone = i < done;
            return (
              <li key={i} className={`step${isDone ? ' is-done' : ''}`}>
                <span className="step__icon">
                  {isDone ? <CheckmarkFilled size={20} className="step__check" /> : <InlineLoading className="step__spinner" aria-label="Working" />}
                </span>
                <span>
                  <HighlightNumbers text={isDone ? text : `${text}...`} />
                </span>
              </li>
            );
          })}
        </ul>
      </div>
    </AssistantMessage>
  );
}
