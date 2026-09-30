'use client';

import { useEffect, useState } from 'react';
import { Button, DatePicker, DatePickerInput, Dropdown, InlineLoading, InlineNotification, NumberInput, TextArea, TextInput } from '@carbon/react';
import { AiLaunch, CheckmarkFilled, DataBase, Edit, Misuse, Reset } from '@carbon/icons-react';
import { api } from '@/lib/api';
import type { Fact, FactOverrides, FlowStart, Review, ReviewItem } from '@/lib/types';
import { AssistantMessage } from './common';

export type ReviewResult = { items: ReviewItem[]; productId: number | null; followUpDays: number; overrides: FactOverrides; edited: boolean };

type Props = {
  data: FlowStart;
  recordIds: number[];
  locked: false | { text: string; cancelled?: boolean };
  onApprove: (r: ReviewResult) => void;
  onCancel: () => void;
  onError: (message: string) => void;
};

type ProductOption = { id: number | null; label: string };

export default function ReviewCard({ data, recordIds, locked, onApprove, onCancel, onError }: Props) {
  const [review, setReview] = useState<Review | null>(null);
  const [productId, setProductId] = useState<number | null>(data.default_product_id);
  const [followUpDays, setFollowUpDays] = useState<number | null>(null);
  const [overrides, setOverrides] = useState<FactOverrides>({});
  const [prompts, setPrompts] = useState<string[]>([]);
  const [edited, setEdited] = useState<boolean[]>([]);
  const [current, setCurrent] = useState(0);
  const [loading, setLoading] = useState(true);

  const validOverrides = Object.values(overrides).every((values) => Object.values(values).every(isValidInput));

  useEffect(() => {
    if (!validOverrides) return;
    let cancelled = false;
    setLoading(true);
    // Wait for typing to pause before re-rendering, except on the first load.
    const timer = setTimeout(
      () =>
        api<Review>(`/api/flows/${data.flow.slug}/review`, {
          record_ids: recordIds,
          product_id: productId,
          follow_up_days: followUpDays ?? undefined,
          overrides,
        })
          .then((r) => {
            if (cancelled) return;
            setReview(r);
            setPrompts(r.items.map((it) => it.prompt));
            setEdited(r.items.map(() => false));
            if (followUpDays === null) setFollowUpDays(r.follow_up.days);
            setLoading(false);
          })
          .catch((err) => !cancelled && onError(err.message)),
      review ? 300 : 0
    );
    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
    // Re-render the prompts from the template whenever the product, follow-up or a fact changes.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [productId, followUpDays, overrides]);

  if (!review) {
    return (
      <AssistantMessage scrollOnMount>
        <InlineLoading description="Preparing a personalized prompt from the template..." />
      </AssistantMessage>
    );
  }

  const multi = review.items.length > 1;
  const item = review.items[current] || review.items[0];
  const productOptions: ProductOption[] = [{ id: null, label: 'None' }, ...data.products.map((p) => ({ id: p.id, label: p.label }))];
  const selectedProduct = productOptions.find((o) => o.id === productId) || productOptions[0];
  const recipientOptions = review.items.map((it, i) => ({ id: i, label: it.title }));

  return (
    <AssistantMessage scrollOnMount>
      <div className={`card${locked ? ' is-locked' : ''}${locked && locked.cancelled ? ' is-cancelled' : ''}`}>
        <div className="card__head">
          <Edit size={20} className="card__head-icon" />
          <div>
            <h3 className="card__title">Review before drafting</h3>
            <p className="card__subtitle">
              {multi
                ? `One personalized prompt per recipient (${review.items.length}). Switch recipients to review each one.`
                : `Personalized for ${item.title}.`}
            </p>
          </div>
        </div>
        <div className="card__body">
          <div className="form-grid">
            {multi && (
              <div className="span-12">
                <Dropdown
                  id={`recipient-${data.chat.id}`}
                  titleText="Preview for"
                  label="Recipient"
                  items={recipientOptions}
                  itemToString={(o: any) => (o ? o.label : '')}
                  selectedItem={recipientOptions[current]}
                  onChange={({ selectedItem }: any) => setCurrent(selectedItem.id)}
                  disabled={Boolean(locked)}
                />
              </div>
            )}
            <div className="span-8">
              <Dropdown
                id={`product-${data.chat.id}`}
                titleText="Product"
                label="Product"
                items={productOptions}
                itemToString={(o: any) => (o ? o.label : '')}
                selectedItem={selectedProduct}
                onChange={({ selectedItem }: any) => setProductId(selectedItem.id)}
                disabled={Boolean(locked)}
              />
            </div>
            <div className="span-4">
              <NumberInput
                id={`followup-${data.chat.id}`}
                label="Follow-up in (days)"
                helperText={`Task due ${review.follow_up.date}`}
                min={1}
                max={60}
                value={followUpDays ?? review.follow_up.days}
                onChange={(_e: any, { value }: any) => {
                  const v = Number(value);
                  if (Number.isInteger(v) && v >= 1 && v <= 60) setFollowUpDays(v);
                }}
                disabled={Boolean(locked)}
              />
            </div>
            {review.ineligible.length > 0 && (
              <div className="span-12">
                <InlineNotification
                  kind="warning"
                  lowContrast
                  hideCloseButton
                  title={`${review.ineligible.map((x) => x.name).join(', ')} ${review.ineligible.length === 1 ? 'is' : 'are'} not eligible for the discount.`}
                  subtitle={`${capitalize(review.ineligible[0].note)}. The prompt tells the assistant not to mention it.`}
                />
              </div>
            )}
            {item.facts.length > 0 && (
              <div className="span-12">
                <div className="facts-label">
                  <DataBase size={14} />
                  Values from the database. Change one and the prompt and draft use your value exactly.
                  {item.facts.some((f) => overrides[f.record_id]?.[f.key] !== undefined) && !locked && (
                    <Button kind="ghost" size="sm" renderIcon={Reset} className="facts-reset" onClick={() => setOverrides(withoutRecords(overrides, item.record_ids))}>
                      Reset to database
                    </Button>
                  )}
                </div>
                <div className="facts-grid">
                  {item.facts.map((f) => (
                    <FactField
                      key={`${f.record_id}-${f.key}`}
                      id={`fact-${data.chat.id}-${f.record_id}-${f.key}`}
                      fact={f}
                      value={overrides[f.record_id]?.[f.key]}
                      disabled={Boolean(locked)}
                      onChange={(v) => setOverrides((o) => ({ ...o, [f.record_id]: { ...o[f.record_id], [f.key]: v } }))}
                    />
                  ))}
                </div>
              </div>
            )}
            <div className="span-12">
              <TextArea
                id={`prompt-${data.chat.id}`}
                className="prompt-area"
                labelText={
                  <span className="label-row">
                    Prompt
                    <span className="label-row__aside">
                      <Edit size={12} /> Editable. Pre-filled from the template with database values
                    </span>
                  </span>
                }
                rows={11}
                value={prompts[current] ?? ''}
                onChange={(e: React.ChangeEvent<HTMLTextAreaElement>) => {
                  const v = e.target.value;
                  setPrompts((p) => p.map((x, i) => (i === current ? v : x)));
                  setEdited((p) => p.map((x, i) => (i === current ? true : x)));
                }}
                readOnly={Boolean(locked)}
              />
              {loading && <InlineLoading className="inline-note" description="Updating prompt..." />}
            </div>
          </div>
        </div>
        {locked ? (
          <div className="card-status">
            {locked.cancelled ? <Misuse size={16} /> : <CheckmarkFilled size={16} className="ok" />}
            <span>{locked.text}</span>
          </div>
        ) : (
          <div className="card__actions">
            <div className="card__actions-status">Nothing is sent without your approval.</div>
            <Button kind="secondary" onClick={onCancel}>
              Cancel
            </Button>
            <Button
              kind="primary"
              renderIcon={AiLaunch}
              disabled={loading || !validOverrides}
              onClick={() =>
                onApprove({
                  items: review.items.map((it, i) => ({ ...it, prompt: prompts[i] })),
                  productId,
                  followUpDays: followUpDays ?? review.follow_up.days,
                  overrides,
                  edited: edited.some(Boolean) || review.items.some((it) => it.facts.some((f) => f.original)),
                })
              }
            >
              {multi ? `Generate ${review.items.length} drafts` : 'Generate draft'}
            </Button>
          </div>
        )}
      </div>
    </AssistantMessage>
  );
}

// One editable fact: a date picker for dates, a number field for everything else. The
// database value stays visible underneath once it has been changed.
function FactField({ id, fact, value, disabled, onChange }: { id: string; fact: Fact; value: string | number | undefined; disabled: boolean; onChange: (v: string | number) => void }) {
  const current = value ?? fact.input ?? '';
  const helper = fact.original ? `Database: ${fact.original}` : 'From the database';
  if (fact.input === null) {
    // Calculated from other values (e.g. price and discount), so it follows them instead of being typed.
    return (
      <TextInput
        id={id}
        className={fact.original ? 'is-edited' : ''}
        labelText={fact.label}
        value={fact.value}
        helperText={fact.original ? `Database: ${fact.original}` : fact.derived || 'From the database'}
        readOnly
      />
    );
  }
  if (fact.kind === 'date') {
    return (
      <DatePicker
        datePickerType="single"
        dateFormat="m/d/Y"
        value={isoToDate(String(current))}
        readOnly={disabled}
        onChange={(dates: Date[]) => dates[0] && onChange(dateToIso(dates[0]))}
      >
        <DatePickerInput id={id} labelText={fact.label} placeholder="mm/dd/yyyy" helperText={helper} className={fact.original ? 'is-edited' : ''} />
      </DatePicker>
    );
  }
  const label = fact.kind === 'money' ? `${fact.label} ($)` : fact.kind === 'percent' ? `${fact.label} (%)` : fact.unit ? `${fact.label} (${fact.unit})` : fact.label;
  return (
    <NumberInput
      id={id}
      className={fact.original ? 'is-edited' : ''}
      label={label}
      helperText={helper}
      min={0}
      step={fact.kind === 'money' ? 0.01 : 1}
      allowEmpty
      hideSteppers
      value={current}
      invalid={!isValidInput(current)}
      invalidText="Enter a number of 0 or more."
      readOnly={disabled}
      onChange={(e: any, { value: v }: any) => onChange(v === undefined ? e.target.value : v)}
    />
  );
}

function isValidInput(v: string | number) {
  if (typeof v === 'number') return Number.isFinite(v) && v >= 0;
  if (/^\d{4}-\d{2}-\d{2}$/.test(v)) return true;
  return v.trim() !== '' && Number.isFinite(Number(v)) && Number(v) >= 0;
}

function withoutRecords(overrides: FactOverrides, recordIds: number[]): FactOverrides {
  return Object.fromEntries(Object.entries(overrides).filter(([id]) => !recordIds.includes(Number(id))));
}

// Dates travel as YYYY-MM-DD; the picker works with local Date objects.
function isoToDate(iso: string) {
  const [y, m, d] = iso.split('-').map(Number);
  return y && m && d ? new Date(y, m - 1, d) : undefined;
}

function dateToIso(d: Date) {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

function capitalize(s: string) {
  return s ? s[0].toUpperCase() + s.slice(1) : s;
}
