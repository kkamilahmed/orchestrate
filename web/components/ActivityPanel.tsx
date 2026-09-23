'use client';

import { useEffect, useRef, useState } from 'react';
import { Button, HeaderPanel, InlineLoading, InlineNotification, Tag } from '@carbon/react';
import { Activity, Chat, Close, Document, Email, Phone, Task, Ticket, ToolKit } from '@carbon/icons-react';
import type { CarbonIconType } from '@carbon/icons-react';
import { api } from '@/lib/api';
import type { ActivityEntry } from '@/lib/types';
import { relativeTime } from './common';

const ACTIONS: Record<string, [CarbonIconType, (e: ActivityEntry) => string]> = {
  email_sent: [Email, (e) => `Email sent to ${e.record_name}`],
  sms_sent: [Phone, (e) => `Text sent to ${e.record_name}`],
  portal_message_sent: [Chat, (e) => `Portal message sent to ${e.record_name}`],
  work_order_created: [ToolKit, (e) => `Work order created for ${e.record_name}`],
  summary_shared: [Document, (e) => `Handover summary shared${Array.isArray(e.payload.records) ? ` (${e.payload.records.length} items)` : ''}`],
  task_created: [Task, (e) => `Follow-up task for ${e.record_name}`],
  ticket_opened: [Ticket, (e) => `Ticket #${e.id} opened${e.payload.queue ? ` in ${e.payload.queue}` : ''}`],
};

type Data = {
  entries: ActivityEntry[];
  tasks: { id: number; title: string; due_label: string; is_seed: boolean; record_name: string }[];
};

type Props = { open: boolean; version: number; industry: string; onClose: () => void };

export default function ActivityPanel({ open, version, industry, onClose }: Props) {
  const [data, setData] = useState<Data | null>(null);
  const [error, setError] = useState<string | null>(null);
  const seen = useRef<Set<number>>(new Set());
  const [fresh, setFresh] = useState<Set<number>>(new Set());

  useEffect(() => {
    seen.current = new Set();
    setData(null);
  }, [industry]);

  useEffect(() => {
    if (!open) return;
    let cancelled = false;
    api<Data>('/api/activity')
      .then((d) => {
        if (cancelled) return;
        const isFirstLoad = seen.current.size === 0;
        const newIds = new Set(d.entries.filter((e) => !e.is_seed && !seen.current.has(e.id)).map((e) => e.id));
        d.entries.forEach((e) => seen.current.add(e.id));
        setFresh(isFirstLoad ? new Set(d.entries.filter((e) => !e.is_seed).map((e) => e.id)) : newIds);
        setData(d);
        setError(null);
      })
      .catch((err) => !cancelled && setError(err.message));
    return () => {
      cancelled = true;
    };
  }, [open, version, industry]);

  return (
    <HeaderPanel expanded={open} aria-label="Activity" className="activity-panel" addFocusListeners={false}>
      <div className="panel-head">
        <div>
          <h2>Activity</h2>
          <p>
            Recorded in <code>activity_log</code> and <code>tasks</code>
          </p>
        </div>
        <Button kind="ghost" size="md" hasIconOnly renderIcon={Close} iconDescription="Close" tooltipPosition="left" onClick={onClose} />
      </div>
      <div className="panel-scroll">
        {error && <InlineNotification kind="error" lowContrast title="Could not load activity." subtitle={error} hideCloseButton />}
        {!data && !error && <InlineLoading description="Loading activity..." />}
        {data && (
          <>
            <div className="panel-section">Recent actions</div>
            {data.entries.length === 0 && <div className="entry-empty">No activity yet.</div>}
            {data.entries.map((e) => {
              const [Icon, title] = ACTIONS[e.action_type] || [Activity, () => e.action_type.replace(/_/g, ' ')];
              const p = e.payload || {};
              const detail = p.subject || p.title || (p.body ? `${String(p.body).slice(0, 90)}${String(p.body).length > 90 ? '...' : ''}` : p.summary || '');
              return (
                <div key={e.id} className={`entry${e.is_seed ? '' : ' is-new'}${fresh.has(e.id) ? ' is-fresh' : ''}`}>
                  <Icon size={20} className="entry__icon" />
                  <div className="entry__main">
                    <div className="entry__title">{title(e)}</div>
                    {detail && <div className="entry__detail">{detail}</div>}
                    <div className="entry__meta">
                      {!e.is_seed && (
                        <Tag type="blue" size="sm">
                          This session
                        </Tag>
                      )}
                      {p.facts_verified === true && (
                        <Tag type="green" size="sm">
                          Facts verified
                        </Tag>
                      )}
                      {p.facts_verified === false && (
                        <Tag type="red" size="sm">
                          Sent with flagged values
                        </Tag>
                      )}
                      <span>{[e.flow_title, relativeTime(e.created_at), `#${e.id}`].filter(Boolean).join(' · ')}</span>
                    </div>
                  </div>
                </div>
              );
            })}
            <div className="panel-section">Open tasks</div>
            {data.tasks.length === 0 && <div className="entry-empty">No open tasks.</div>}
            {data.tasks.map((t) => (
              <div key={t.id} className={`entry${t.is_seed ? '' : ' is-new'}`}>
                <Task size={20} className="entry__icon" />
                <div className="entry__main">
                  <div className="entry__title">{t.title}</div>
                  <div className="entry__meta">
                    <span>
                      Due {t.due_label} · {t.record_name}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </>
        )}
      </div>
    </HeaderPanel>
  );
}
