'use client';

import { useState } from 'react';
import { Button, Tag } from '@carbon/react';
import { Activity, CheckmarkFilled, Home, Task, Ticket } from '@carbon/icons-react';
import type { ApproveResult, FlowStart, ReviewItem } from '@/lib/types';
import AgentSteps from './AgentSteps';
import RecordsTable from './RecordsTable';
import ReviewCard, { type ReviewResult } from './ReviewCard';
import DraftsCard from './DraftsCard';
import { AssistantMessage } from './common';

type Stage = 'steps' | 'table' | 'review' | 'drafts' | 'done' | 'cancelled';

type Props = {
  data: FlowStart;
  recordNoun: string;
  userName: string;
  model: string;
  chatId: () => number | null;
  onChanged: () => void;
  onActivity: (count: number) => void;
  onOpenActivity: () => void;
  onGoHome: () => void;
  onError: (message: string) => void;
  onFallback: () => void;
};

// One guided flow: agent steps -> records table -> review -> drafts -> approval.
// Earlier stages stay on screen, locked, so the audience can follow the whole story.
export default function GuidedFlow(props: Props) {
  const { data } = props;
  const [stage, setStage] = useState<Stage>('steps');
  const [cancelledAt, setCancelledAt] = useState<Stage | null>(null);
  const [recordIds, setRecordIds] = useState<number[]>([]);
  const [review, setReview] = useState<ReviewResult | null>(null);
  const [results, setResults] = useState<ApproveResult[] | null>(null);
  const [approvedBy, setApprovedBy] = useState('');

  const order: Stage[] = ['steps', 'table', 'review', 'drafts', 'done'];
  const reached = (s: Stage) => order.indexOf(s) <= order.indexOf(cancelledAt || stage);
  const lockFor = (s: Stage, text: string) =>
    cancelledAt === s ? { text: 'Cancelled', cancelled: true } : order.indexOf(cancelledAt || stage) > order.indexOf(s) ? { text } : (false as const);

  const cancel = (at: Stage) => {
    setCancelledAt(at);
    setStage('cancelled');
    props.onChanged();
  };

  const names = data.records.filter((r) => recordIds.includes(r.id)).map((r) => r.name);

  return (
    <>
      <AgentSteps title={data.flow.title} icon={data.flow.icon} steps={data.agent_steps} onDone={() => setStage((s) => (s === 'steps' ? 'table' : s))} />

      {reached('table') && stage !== 'steps' && (
        data.records.length === 0 ? (
          <AssistantMessage>
            <p className="prose">Nothing needs action right now. The query returned no {props.recordNoun}.</p>
          </AssistantMessage>
        ) : (
          <RecordsTable
            data={data}
            recordNoun={props.recordNoun}
            locked={lockFor('table', `Selected ${names.length}: ${names.join(', ')}`)}
            onContinue={(ids) => {
              setRecordIds(ids);
              setStage('review');
            }}
            onCancel={() => cancel('table')}
          />
        )
      )}

      {reached('review') && recordIds.length > 0 && (
        <ReviewCard
          data={data}
          recordIds={recordIds}
          locked={lockFor('review', `Prompt approved${review && review.edited ? ' with your edits' : ''}`)}
          onApprove={(r) => {
            setReview(r);
            setStage('drafts');
          }}
          onCancel={() => cancel('review')}
          onError={props.onError}
        />
      )}

      {reached('drafts') && review && (
        <DraftsCard
          data={data}
          items={review.items as ReviewItem[]}
          productId={review.productId}
          followUpDays={review.followUpDays}
          chatId={props.chatId}
          model={props.model}
          locked={lockFor('drafts', `Approved by ${props.userName}`)}
          onApproved={(res, who) => {
            setResults(res);
            setApprovedBy(who);
            setStage('done');
            props.onActivity(res.length * 2 + res.filter((r) => r.ticket_id).length);
            props.onChanged();
          }}
          onCancel={() => cancel('drafts')}
          onFallback={props.onFallback}
        />
      )}

      {stage === 'cancelled' && (
        <AssistantMessage scrollOnMount>
          <div className="prose">
            <p>Cancelled. Nothing was sent, and no records were changed.</p>
          </div>
        </AssistantMessage>
      )}

      {stage === 'done' && results && (
        <AssistantMessage scrollOnMount>
          <div className="confirm" role="status" aria-label={`Approved: ${approvedBy}`}>
            <CheckmarkFilled size={24} className="confirm__icon" />
            <div>
              <div className="confirm__lines">
                {results.map((r) => (
                  <p key={r.activity_id}>{r.confirmation}</p>
                ))}
              </div>
              <div className="confirm__meta">
                {results.map((r) => (
                  <Tag key={`a${r.activity_id}`} type="gray" size="sm" renderIcon={Activity}>
                    {`activity_log #${r.activity_id}`}
                  </Tag>
                ))}
                {results.map((r) => (
                  <Tag key={`t${r.task.id}`} type="gray" size="sm" renderIcon={Task}>
                    {`Task due ${r.task.due}`}
                  </Tag>
                ))}
                {results
                  .filter((r) => r.ticket_id)
                  .map((r) => (
                    <Tag key={`k${r.ticket_id}`} type="gray" size="sm" renderIcon={Ticket}>
                      {`Ticket #${r.ticket_id}`}
                    </Tag>
                  ))}
              </div>
              <div className="confirm__actions">
                <Button kind="ghost" size="md" renderIcon={Activity} onClick={props.onOpenActivity}>
                  View activity
                </Button>
                <Button kind="ghost" size="md" renderIcon={Home} onClick={props.onGoHome}>
                  Back to today&apos;s signals
                </Button>
              </div>
            </div>
          </div>
        </AssistantMessage>
      )}
    </>
  );
}
