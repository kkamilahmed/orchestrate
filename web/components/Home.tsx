'use client';

import { useEffect, useState } from 'react';
import { ClickableTile, Tag } from '@carbon/react';
import { ArrowRight, Checkmark, Time } from '@carbon/icons-react';
import type { AppState, Signal } from '@/lib/types';
import { iconFor } from '@/lib/icons';
import { AiBadge } from './common';

const SEVERITY: Record<Signal['severity'], { type: 'red' | 'blue' | 'gray'; label: string }> = {
  high: { type: 'red', label: 'High priority' },
  medium: { type: 'blue', label: 'Medium' },
  low: { type: 'gray', label: 'Low' },
};

function greeting() {
  const h = new Date().getHours();
  return h < 12 ? 'Good morning' : h < 18 ? 'Good afternoon' : 'Good evening';
}

type Props = {
  state: AppState;
  onSignal: (s: Signal) => void;
  onSuggestion: (prompt: string) => void;
};

export default function Home({ state, onSignal, onSuggestion }: Props) {
  // Time-of-day greeting and date are client-only, so render them after mount.
  const [now, setNow] = useState<{ greet: string; date: string } | null>(null);
  useEffect(() => {
    setNow({ greet: greeting(), date: new Date().toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' }) });
  }, []);

  const n = state.signals.length;
  const signalCols = n === 4 ? 4 : Math.min(3, Math.max(1, n));

  return (
    <section className="home" key={state.industry.slug}>
      <div className="home__eyebrow">{now?.date || ' '}</div>
      <h1 className="home__greeting">
        {now?.greet || 'Hello'}, {state.user?.first_name}
      </h1>
      <p className="home__sub">
        I reviewed {state.stats.records} {state.industry.record_noun} overnight. Here&apos;s what needs your attention today.
      </p>

      <div className="section-head">
        <h2>Today&apos;s signals</h2>
        <AiBadge title="How signals are found">
          <p>
            Each signal is a named query over your {state.industry.record_noun}, their recent events and your products. Counts are computed live
            from the database every time this page loads.
          </p>
        </AiBadge>
        <span className="section-head__meta">
          <Time size={16} /> Live from your systems
        </span>
      </div>

      {n === 0 ? (
        <p className="empty-note">No signals right now.</p>
      ) : (
        <div className="grid" style={{ ['--cols' as string]: signalCols }}>
          {state.signals.map((s, i) => {
            const sev = SEVERITY[s.severity] || SEVERITY.low;
            const flow = state.assistants.find((a) => a.slug === s.flow_slug);
            const FlowIcon = iconFor(flow?.icon);
            return (
              <ClickableTile
                key={s.id}
                className="signal"
                style={{ animationDelay: `${80 + i * 60}ms` }}
                onClick={(e: React.SyntheticEvent) => {
                  e.preventDefault();
                  onSignal(s);
                }}
                href="#"
              >
                <div className="signal__top">
                  <Tag type={sev.type} size="sm">
                    {sev.label}
                  </Tag>
                  {s.actioned > 0 && (
                    <Tag type="green" size="sm" renderIcon={Checkmark}>
                      {`${s.actioned} done`}
                    </Tag>
                  )}
                  <FlowIcon size={20} className="signal__icon" />
                </div>
                <div className="signal__count">{s.count}</div>
                <p className="signal__title">{s.title.replace(/^\d+\s*/, '')}</p>
                <p className="signal__desc">{s.description}</p>
                <div className="signal__cta">
                  <span>{flow ? flow.title : 'Open'}</span>
                  <ArrowRight size={16} />
                </div>
              </ClickableTile>
            );
          })}
        </div>
      )}

      <div className="section-head">
        <h2>Suggested actions</h2>
      </div>
      <div className="grid" style={{ ['--cols' as string]: Math.min(3, state.suggestions.length || 1) }}>
        {state.suggestions.map((sg, i) => {
          const Icon = iconFor(sg.icon);
          return (
            <ClickableTile
              key={sg.id}
              className="suggestion"
              style={{ animationDelay: `${260 + i * 60}ms` }}
              href="#"
              onClick={(e: React.SyntheticEvent) => {
                e.preventDefault();
                onSuggestion(sg.prompt);
              }}
            >
              <Icon size={20} className="suggestion__icon" />
              <div>
                <div className="suggestion__title">{sg.title}</div>
                <div className="suggestion__prompt">{sg.prompt}</div>
              </div>
            </ClickableTile>
          );
        })}
      </div>
    </section>
  );
}
