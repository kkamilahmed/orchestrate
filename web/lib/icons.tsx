import {
  Activity,
  Book,
  Catalog,
  ChartLine,
  Chat,
  Dashboard,
  Document,
  Email,
  Enterprise,
  Flash,
  Idea,
  ListChecked,
  Phone,
  Renew,
  Task,
  Ticket,
  Time,
  ToolKit,
  UserAvatar,
  UserMultiple,
  WarningAlt,
} from '@carbon/icons-react';
import type { CarbonIconType } from '@carbon/icons-react';

// Icon names stored in the database (flows.icon, suggestions.icon) -> Carbon icons.
const ICONS: Record<string, CarbonIconType> = {
  activity: Activity,
  book: Book,
  catalog: Catalog,
  'chart--line': ChartLine,
  chat: Chat,
  dashboard: Dashboard,
  document: Document,
  email: Email,
  enterprise: Enterprise,
  flash: Flash,
  idea: Idea,
  'list--checked': ListChecked,
  phone: Phone,
  renew: Renew,
  task: Task,
  ticket: Ticket,
  time: Time,
  'tool-kit': ToolKit,
  'user--avatar': UserAvatar,
  'user--multiple': UserMultiple,
  'warning--alt--filled': WarningAlt,
};

export function iconFor(name: string | undefined): CarbonIconType {
  return (name && ICONS[name]) || Flash;
}
