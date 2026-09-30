'use client';

import { useCallback, useEffect, useLayoutEffect, useRef, useState } from 'react';
import { Button, Dropdown, InlineLoading, InlineNotification, Tab, TabList, Tabs, Tag, TextArea, TextInput } from '@carbon/react';
import { Chat, CheckmarkFilled, Document, Email, Locked, Misuse, Phone, Renew, Send, Time, ToolKit, WarningAltFilled } from '@carbon/icons-react';
import type { CarbonIconType } from '@carbon/icons-react';
import { api, streamPost } from '@/lib/api';
import type { ApproveResult, FactCheck, FactOverrides, FlowStart, ReviewItem } from '@/lib/types';
import { AiBadge, AssistantMessage, scrollToBottom } from './common';

type DraftStatus = 'pending' | 'streaming' | 'done' | 'error';

type Draft = ReviewItem & {
  body: string;
  status: DraftStatus;
  check: FactCheck | null;
  source: 'live' | 'offline' | null;
  contentType: string;
  error?: string;
};

type Props = {
  data: FlowStart;
  items: ReviewItem[];
  productId: number | null;
  followUpDays: number;
  overrides: FactOverrides;
  chatId: () => number | null;
  model: string;
  locked: false | { text: string; cancelled?: boolean };
  onApproved: (results: ApproveResult[], approvedBy: string) => void;
  onCancel: () => void;
  onFallback: () => void;
};

const CONTENT_TYPES = ['Email', 'SMS', 'Portal message', 'Work order', 'Handover summary'];
const CONTENT_ICONS: Record<string, CarbonIconType> = { SMS: Phone, 'Portal message': Chat, 'Work order': ToolKit, 'Handover summary': Document };

// "SMS" stays upper case; everything else reads naturally in lower case ("Draft work order to ...").
function contentNoun(type: string) {
  return /^[A-Z]{2,}$/.test(type) ? type : type.toLowerCase();
}

export default function DraftsCard({ data, items, productId, followUpDays, overrides, chatId, model, locked, onApproved, onCancel, onFallback }: Props) {
  const flow = data.flow;
  const [drafts, setDrafts] = useState<Draft[]>(() =>
    items.map((it) => ({ ...it, body: '', status: 'pending', check: null, source: null, contentType: flow.content_type }))
  );
  const [current, setCurrent] = useState(0);
  const [sending, setSending] = useState(false);
  const [sendError, setSendError] = useState<string | null>(null);
  const draftsRef = useRef(drafts);
  draftsRef.current = drafts;
  const aborters = useRef<AbortController[]>([]);
  const checkTimer = useRef<ReturnType<typeof setTimeout>>(undefined);
  const bodyRef = useRef<HTMLTextAreaElement>(null);

  const update = useCallback((i: number, patch: Partial<Draft> | ((d: Draft) => Partial<Draft>)) => {
    setDrafts((prev) => prev.map((d, j) => (j === i ? { ...d, ...(typeof patch === 'function' ? patch(d) : patch) } : d)));
  }, []);

  const base = { product_id: productId, follow_up_days: followUpDays, overrides };

  const generate = useCallback(
    async (i: number) => {
      const item = draftsRef.current[i];
      update(i, { status: 'streaming', body: '', check: null, error: undefined });
      const controller = new AbortController();
      aborters.current.push(controller);
      let body = '';
      try {
        await streamPost(
          `/api/flows/${flow.slug}/draft`,
          { ...base, record_ids: item.record_ids, prompt: item.prompt },
          {
            meta: (m) => {
              update(i, { source: m.source });
              if (m.fallback) onFallback();
            },
            token: (d) => {
              body += d.t;
              update(i, { body });
              scrollToBottom();
            },
            done: (d) => update(i, { body: d.text, source: d.source, check: d.check, status: 'done' }),
            error: (d) => update(i, { status: 'error', error: d.message }),
          },
          controller.signal
        );
        update(i, (d) => (d.status === 'streaming' ? { status: 'done' } : {}));
      } catch (err: any) {
        if (controller.signal.aborted) return;
        update(i, { status: 'error', error: err.message });
      }
    },
    // eslint-disable-next-line react-hooks/exhaustive-deps
    [flow.slug, productId, followUpDays]
  );

  // Draft every recipient in turn when the card appears.
  useEffect(() => {
    let stopped = false;
    (async () => {
      for (let i = 0; i < items.length && !stopped; i++) await generate(i);
    })();
    return () => {
      stopped = true;
      aborters.current.forEach((a) => a.abort());
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Cancelling the flow stops any draft still streaming.
  const cancelled = Boolean(locked && locked.cancelled);
  useEffect(() => {
    if (cancelled) aborters.current.forEach((a) => a.abort());
  }, [cancelled]);

  const draft = drafts[current];

  // The body grows with its content so the whole draft is readable on a projector.
  useLayoutEffect(() => {
    const ta = bodyRef.current;
    if (!ta) return;
    ta.style.height = 'auto';
    ta.style.height = `${ta.scrollHeight + 2}px`;
  }, [draft.body, current]);

  const editBody = (value: string) => {
    update(current, { body: value });
    clearTimeout(checkTimer.current);
    const i = current;
    checkTimer.current = setTimeout(async () => {
      try {
        const check = await api<FactCheck>(`/api/flows/${flow.slug}/check`, { ...base, record_ids: drafts[i].record_ids, text: value });
        update(i, { check });
      } catch {
        /* keep the previous result */
      }
    }, 350);
  };

  const busy = drafts.some((d) => d.status === 'streaming' || d.status === 'pending');
  const ready = drafts.filter((d) => d.status === 'done' && d.body.trim());
  const issues = drafts.filter((d) => d.check && !d.check.ok).length;
  const doneCount = drafts.filter((d) => d.status === 'done' || d.status === 'error').length;
  const multi = drafts.length > 1;

  const send = async () => {
    setSending(true);
    setSendError(null);
    try {
      const res = await api<{ results: ApproveResult[] }>(`/api/flows/${flow.slug}/approve`, {
        ...base,
        chat_id: chatId(),
        items: ready.map((d) => ({ record_ids: d.record_ids, to: d.to, cc: d.cc, subject: d.subject, body: d.body, content_type: d.contentType, source: d.source })),
      });
      onApproved(res.results, ready.map((d) => d.title).join(', '));
    } catch (err: any) {
      setSendError(err.message);
      setSending(false);
    }
  };

  const statusText = busy
    ? `Drafting ${Math.min(doneCount + 1, drafts.length)} of ${drafts.length}...`
    : issues
      ? `${issues} draft${issues === 1 ? '' : 's'} flagged. You decide what gets sent.`
      : 'Review, edit, then approve.';

  const tabIcon = (d: Draft) => {
    if (d.status === 'pending') return <Time size={16} />;
    if (d.status === 'streaming') return <InlineLoading className="tab-spinner" aria-label="Drafting" />;
    if (d.status === 'error') return <Misuse size={16} className="warn" />;
    return d.check && !d.check.ok ? <WarningAltFilled size={16} className="warn" /> : <CheckmarkFilled size={16} className="ok" />;
  };

  const contentTypes = CONTENT_TYPES.includes(draft.contentType) ? CONTENT_TYPES : [draft.contentType, ...CONTENT_TYPES];
  const HeadIcon = CONTENT_ICONS[flow.content_type] || Email;
  const isEditable = !locked && draft.status !== 'streaming' && draft.status !== 'pending';

  return (
    <AssistantMessage scrollOnMount>
      <div className={`card${locked ? ' is-locked' : ''}${locked && locked.cancelled ? ' is-cancelled' : ''}`}>
        <div className="card__head">
          <HeadIcon size={20} className="card__head-icon" />
          <div>
            <h3 className="card__title">
              {multi ? `${drafts.length} drafts ready for review` : `Draft ${contentNoun(flow.content_type)} to ${drafts[0].title}`}
            </h3>
            <p className="card__subtitle">Streamed from the model with the reviewed values locked. Fully editable.</p>
          </div>
          <div className="card__head-right">
            <AiBadge title="AI-drafted message">
              <p>
                Written by {draft.source === 'offline' ? 'a pre-approved template' : model} from your prompt. Prices, discounts, dates and ages are
                passed in as fixed values and checked against the database after drafting.
              </p>
            </AiBadge>
          </div>
        </div>

        {multi && (
          <div className="draft-tabs">
            <Tabs selectedIndex={current} onChange={({ selectedIndex }: { selectedIndex: number }) => setCurrent(selectedIndex)}>
              <TabList aria-label="Drafts" contained>
                {drafts.map((d, i) => (
                  <Tab key={i} renderIcon={() => tabIcon(d)}>
                    {d.title}
                  </Tab>
                ))}
              </TabList>
            </Tabs>
          </div>
        )}

        <div className="card__body">
          <div className="form-grid">
            <div className={flow.has_subject ? 'span-6' : 'span-8'}>
              <TextInput
                id={`to-${data.chat.id}-${current}`}
                labelText="To"
                value={draft.to}
                onChange={(e: React.ChangeEvent<HTMLInputElement>) => update(current, { to: e.target.value })}
                readOnly={Boolean(locked)}
              />
            </div>
            {flow.has_subject && (
              <div className="span-6">
                <TextInput
                  id={`cc-${data.chat.id}-${current}`}
                  labelText="Cc"
                  value={draft.cc}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => update(current, { cc: e.target.value })}
                  readOnly={Boolean(locked)}
                />
              </div>
            )}
            {flow.has_subject && (
              <div className="span-8">
                <TextInput
                  id={`subject-${data.chat.id}-${current}`}
                  labelText="Subject"
                  value={draft.subject}
                  onChange={(e: React.ChangeEvent<HTMLInputElement>) => update(current, { subject: e.target.value })}
                  readOnly={Boolean(locked)}
                />
              </div>
            )}
            <div className="span-4">
              <Dropdown
                id={`ctype-${data.chat.id}-${current}`}
                titleText="Content type"
                label="Content type"
                items={contentTypes}
                selectedItem={draft.contentType}
                onChange={({ selectedItem }: any) => update(current, { contentType: selectedItem })}
                disabled={Boolean(locked)}
              />
            </div>
            <div className="span-12">
              <TextArea
                ref={bodyRef}
                id={`body-${data.chat.id}-${current}`}
                className={`draft-body${isEditable ? '' : ' is-streaming'}`}
                labelText={
                  <span className="label-row">
                    Body
                    <span className="label-row__aside">Drafted by AI. Edit anything before sending</span>
                  </span>
                }
                rows={8}
                value={draft.body}
                readOnly={!isEditable}
                onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => editBody(e.target.value)}
              />
              <FactCheckRow draft={draft} />
              {draft.status === 'error' && (
                <InlineNotification kind="error" lowContrast hideCloseButton title="Drafting failed." subtitle={draft.error || ''} />
              )}
            </div>
          </div>
          {sendError && <InlineNotification kind="error" lowContrast title="Could not send." subtitle={sendError} onClose={() => setSendError(null)} />}
        </div>

        {locked ? (
          <div className="card-status">
            {locked.cancelled ? <Misuse size={16} /> : <CheckmarkFilled size={16} className="ok" />}
            <span>{locked.text}</span>
          </div>
        ) : (
          <div className="card__actions">
            <div className="card__actions-status">{statusText}</div>
            <Button kind="secondary" onClick={onCancel} disabled={sending}>
              Cancel
            </Button>
            <Button kind="tertiary" renderIcon={Renew} disabled={busy || sending} onClick={() => generate(current)}>
              Regenerate
            </Button>
            <Button kind="primary" renderIcon={Send} disabled={busy || sending || ready.length === 0} onClick={send}>
              {sending ? 'Sending...' : ready.length > 1 ? `${flow.approve_label} (${ready.length})` : flow.approve_label}
            </Button>
          </div>
        )}
      </div>
    </AssistantMessage>
  );
}

function FactCheckRow({ draft }: { draft: Draft }) {
  if (draft.status === 'pending') return <div className="check-row check-row--muted">Waiting for the previous draft...</div>;
  if (draft.status === 'streaming')
    return (
      <div className="check-row">
        <InlineLoading description="Writing with locked facts..." />
      </div>
    );
  if (!draft.check) return null;
  if (draft.check.ok) {
    const n = draft.check.verified.length;
    return (
      <div className="check-row">
        <Tag type="green" renderIcon={CheckmarkFilled}>
          {n ? `Facts match ${draft.facts.some((f) => f.original) ? 'reviewed values' : 'database'} (${n} checked)` : 'No figures to verify'}
        </Tag>
        {draft.check.verified.map((v) => (
          <Tag key={v.label + v.value} type="gray" size="sm" renderIcon={Locked}>
            {v.value}
          </Tag>
        ))}
      </div>
    );
  }
  return (
    <div className="check-row check-row--issues" role="status">
      <Tag type="red" renderIcon={WarningAltFilled}>
        {`Fact check: ${draft.check.issues.length} mismatch${draft.check.issues.length === 1 ? '' : 'es'}`}
      </Tag>
      <ul className="check-issues">
        {draft.check.issues.map((iss) => (
          <li key={iss.found + iss.message}>{iss.message}</li>
        ))}
      </ul>
    </div>
  );
}
