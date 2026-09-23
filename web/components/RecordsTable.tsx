'use client';

import { useMemo, useState } from 'react';
import {
  Button,
  Pagination,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableHeader,
  TableRow,
  TableSelectAll,
  TableSelectRow,
  TableToolbar,
  TableToolbarContent,
  TableToolbarSearch,
  Tag,
} from '@carbon/react';
import { ArrowRight, CheckmarkFilled, ListChecked, Misuse } from '@carbon/icons-react';
import type { FlowStart } from '@/lib/types';
import { AssistantMessage } from './common';

type Props = {
  data: FlowStart;
  recordNoun: string;
  locked: false | { text: string; cancelled?: boolean };
  onContinue: (ids: number[]) => void;
  onCancel: () => void;
};

export default function RecordsTable({ data, recordNoun, locked, onContinue, onCancel }: Props) {
  const [selected, setSelected] = useState<Set<number>>(new Set());
  const [query, setQuery] = useState('');
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(5);
  const t = data.table;

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return data.records.filter((r) => !q || [r.name, r.contact, r.change].join(' ').toLowerCase().includes(q));
  }, [data.records, query]);
  const pages = Math.max(1, Math.ceil(filtered.length / pageSize));
  const current = Math.min(page, pages);
  const slice = filtered.slice((current - 1) * pageSize, current * pageSize);
  const allOnPage = slice.length > 0 && slice.every((r) => selected.has(r.id));
  const someOnPage = slice.some((r) => selected.has(r.id));

  const toggle = (id: number) => {
    if (locked) return;
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };
  const toggleAll = () => {
    if (locked) return;
    setSelected((prev) => {
      const next = new Set(prev);
      slice.forEach((r) => (allOnPage ? next.delete(r.id) : next.add(r.id)));
      return next;
    });
  };

  const colCount = 5 + (t.show_eligibility ? 1 : 0);
  const names = data.records.filter((r) => selected.has(r.id)).map((r) => r.name);

  return (
    <AssistantMessage scrollOnMount>
      <div className={`card${locked ? ' is-locked' : ''}${locked && locked.cancelled ? ' is-cancelled' : ''}`}>
        <div className="card__head">
          <ListChecked size={20} className="card__head-icon" />
          <div>
            <h3 className="card__title">{t.title}</h3>
            <p className="card__subtitle">{t.hint}</p>
          </div>
        </div>
        <div className="card__body card__body--table">
          <TableContainer className="records-table">
            <TableToolbar aria-label="Table toolbar">
              <TableToolbarContent>
                <TableToolbarSearch
                  persistent
                  placeholder={`Search ${data.records.length} ${recordNoun}`}
                  onChange={(e: any) => {
                    setQuery(e && e.target ? e.target.value : '');
                    setPage(1);
                  }}
                  disabled={Boolean(locked)}
                />
              </TableToolbarContent>
            </TableToolbar>
            <Table size="lg" aria-label={t.title}>
              <TableHead>
                <TableRow>
                  <TableSelectAll
                    id={`select-all-${data.chat.id}-${data.flow.slug}`}
                    name="select-all"
                    aria-label="Select all rows on this page"
                    checked={allOnPage}
                    indeterminate={!allOnPage && someOnPage}
                    onSelect={toggleAll}
                    disabled={Boolean(locked)}
                  />
                  <TableHeader>Name</TableHeader>
                  <TableHeader>{t.contact_label}</TableHeader>
                  <TableHeader>{t.change_label}</TableHeader>
                  <TableHeader>Date</TableHeader>
                  {t.show_eligibility && <TableHeader>Eligibility</TableHeader>}
                </TableRow>
              </TableHead>
              <TableBody>
                {slice.length === 0 && (
                  <TableRow>
                    <TableCell colSpan={colCount} className="table-empty">
                      {query ? 'No matches. Try a different search.' : 'Nothing to show.'}
                    </TableCell>
                  </TableRow>
                )}
                {slice.map((r) => (
                  <TableRow
                    key={r.id}
                    isSelected={selected.has(r.id)}
                    className="records-table__row"
                    onClick={(e: React.MouseEvent) => {
                      if (!(e.target as HTMLElement).closest('.cds--checkbox--inline, .cds--table-column-checkbox')) toggle(r.id);
                    }}
                  >
                    <TableSelectRow
                      id={`row-${data.chat.id}-${r.id}`}
                      name={`row-${r.id}`}
                      aria-label={`Select ${r.name}`}
                      checked={selected.has(r.id)}
                      onSelect={() => toggle(r.id)}
                      disabled={Boolean(locked)}
                    />
                    <TableCell>
                      <span className="records-table__name">{r.name}</span>
                      {r.actioned && (
                        <Tag type="green" size="sm" className="records-table__tag">
                          Contacted today
                        </Tag>
                      )}
                    </TableCell>
                    <TableCell className="muted nowrap">{r.contact}</TableCell>
                    <TableCell className="records-table__change">{r.change}</TableCell>
                    <TableCell className="muted nowrap">{r.event_date}</TableCell>
                    {t.show_eligibility && (
                      <TableCell>
                        {r.eligible ? (
                          <Tag type="green" size="sm">
                            Eligible
                          </Tag>
                        ) : (
                          <Tag type="outline" size="sm">
                            Not eligible
                          </Tag>
                        )}
                      </TableCell>
                    )}
                  </TableRow>
                ))}
              </TableBody>
            </Table>
            <Pagination
              page={current}
              pageSize={pageSize}
              pageSizes={[5, 10]}
              totalItems={filtered.length}
              onChange={({ page: p, pageSize: ps }: { page: number; pageSize: number }) => {
                setPage(p);
                setPageSize(ps);
              }}
              disabled={Boolean(locked)}
            />
          </TableContainer>
        </div>
        {locked ? (
          <div className="card-status">
            {locked.cancelled ? <Misuse size={16} /> : <CheckmarkFilled size={16} className="ok" />}
            <span>{locked.text}</span>
          </div>
        ) : (
          <div className="card__actions">
            <div className="card__actions-status">{selected.size ? `${selected.size} selected: ${names.join(', ')}` : 'None selected'}</div>
            <Button kind="secondary" onClick={onCancel}>
              Cancel
            </Button>
            <Button kind="primary" renderIcon={ArrowRight} disabled={selected.size === 0} onClick={() => onContinue(data.records.filter((r) => selected.has(r.id)).map((r) => r.id))}>
              Continue
            </Button>
          </div>
        )}
      </div>
    </AssistantMessage>
  );
}
