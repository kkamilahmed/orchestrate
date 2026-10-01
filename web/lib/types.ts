export type Industry = { slug: string; name: string; company_name: string; logo_text: string; record_noun?: string };

export type Signal = {
  id: number;
  title: string;
  description: string;
  severity: 'high' | 'medium' | 'low';
  count: number;
  actioned: number;
  flow_slug: string;
};

export type Assistant = { slug: string; title: string; description: string; flow_type: 'outreach' | 'qa' | 'insight'; icon: string };

export type AppState = {
  industry: Required<Industry>;
  industries: Industry[];
  user: { name: string; first_name: string; role: string; email: string } | null;
  mode: { offline: boolean; forced: boolean; hasKey: boolean; provider: string; model: string };
  signals: Signal[];
  suggestions: { id: number; title: string; prompt: string; icon: string }[];
  assistants: Assistant[];
  chats: { id: number; title: string; updated_at: string }[];
  stats: { records: number };
};

export type FlowInfo = {
  slug: string;
  title: string;
  description: string;
  flow_type: string;
  icon: string;
  draft_mode: 'per_record' | 'combined';
  content_type: string;
  has_subject: boolean;
  approve_label: string;
};

export type FlowRecord = {
  id: number;
  name: string;
  email: string | null;
  phone: string | null;
  contact: string | null;
  change: string;
  event_date: string;
  eligible: boolean | null;
  actioned: boolean;
};

export type FlowStart = {
  chat: { id: number; title: string };
  flow: FlowInfo;
  agent_steps: string[];
  table: { title: string; hint: string; change_label: string; contact_label: string; show_eligibility: boolean };
  records: FlowRecord[];
  products: { id: number; name: string; label: string }[];
  default_product_id: number | null;
};

// input is the editable raw value (YYYY-MM-DD or a number), null when the fact can't be
// edited. derived explains how a calculated fact is worked out. original is the database
// value when the reviewer's changes moved it.
export type Fact = {
  key: string;
  record_id: number;
  label: string;
  kind: string;
  unit: string;
  value: string;
  input: string | number | null;
  derived: string | null;
  original: string | null;
};

// Reviewer edits of fact values: { recordId: { factKey: value } }.
export type FactOverrides = Record<number, Record<string, string | number>>;

export type ReviewItem = {
  record_ids: number[];
  names: string[];
  title: string;
  prompt: string;
  to: string;
  cc: string;
  subject: string;
  facts: Fact[];
};

export type Review = {
  product: { id: number; name: string; description: string } | null;
  items: ReviewItem[];
  ineligible: { name: string; note: string }[];
  follow_up: { label: string; date: string; days: number };
};

export type FactCheck = {
  ok: boolean;
  issues: { kind: string; found: string; expected: string | null; label: string; message: string }[];
  verified: { label: string; value: string }[];
};

export type ApproveResult = {
  record_ids: number[];
  names: string[];
  confirmation: string;
  activity_id: number;
  ticket_id: number | null;
  task: { id: number; title: string; due: string };
  log_label: string;
  facts_verified: boolean;
};

export type Citation = { title: string; source: string; excerpt?: string };

export type ActivityEntry = {
  id: number;
  action_type: string;
  payload: Record<string, any>;
  is_seed: boolean;
  created_at: string;
  record_name: string | null;
  flow_title: string | null;
};
