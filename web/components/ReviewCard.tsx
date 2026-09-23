'use client';

import { useEffect, useState } from 'react';
import { Button, Dropdown, InlineLoading, InlineNotification, NumberInput, Tag, TextArea } from '@carbon/react';
import { AiLaunch, CheckmarkFilled, Edit, Locked, Misuse } from '@carbon/icons-react';
import { api } from '@/lib/api';
import type { FlowStart, Review, ReviewItem } from '@/lib/types';
import { AssistantMessage } from './common';

export type ReviewResult = { items: ReviewItem[]; productId: number | null; followUpDays: number; edited: boolean };

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
  const [prompts, setPrompts] = useState<string[]>([]);
  const [edited, setEdited] = useState<boolean[]>([]);
  const [current, setCurrent] = useState(0);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    api<Review>(`/api/flows/${data.flow.slug}/review`, {
      record_ids: recordIds,
      product_id: productId,
      follow_up_days: followUpDays ?? undefined,
    })
      .then((r) => {
        if (cancelled) return;
        setReview(r);
        setPrompts(r.items.map((it) => it.prompt));
        setEdited(r.items.map(() => false));
        if (followUpDays === null) setFollowUpDays(r.follow_up.days);
        setLoading(false);
      })
      .catch((err) => !cancelled && onError(err.message));
    return () => {
      cancelled = true;
    };
    // Re-render the prompts from the template whenever the product or follow-up changes.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [productId, followUpDays]);

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
                  <Locked size={14} />
                  Locked values from the database. The draft must use these exactly.
                </div>
                <div className="facts">
                  {item.facts.map((f) => (
                    <Tag key={`${f.key}-${f.value}`} type="blue" renderIcon={Locked}>
                      {f.label}: {f.value}
                    </Tag>
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
              disabled={loading}
              onClick={() =>
                onApprove({
                  items: review.items.map((it, i) => ({ ...it, prompt: prompts[i] })),
                  productId,
                  followUpDays: followUpDays ?? review.follow_up.days,
                  edited: edited.some(Boolean),
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

function capitalize(s: string) {
  return s ? s[0].toUpperCase() + s.slice(1) : s;
}
