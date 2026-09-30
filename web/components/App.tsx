'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import {
  Button,
  Header,
  HeaderGlobalAction,
  HeaderGlobalBar,
  HeaderMenuButton,
  HeaderName,
  InlineLoading,
  InlineNotification,
  Modal,
  SideNav,
  SideNavDivider,
  SideNavItems,
  SideNavLink,
  SkipToContent,
} from '@carbon/react';
import { Activity, Add, Chat, CheckmarkFilled, Enterprise, Flash, Home as HomeIcon, Reset, SendFilled } from '@carbon/icons-react';
import { api, streamPost } from '@/lib/api';
import { iconFor } from '@/lib/icons';
import { renderMarkdown } from '@/lib/markdown';
import type { AppState, Assistant, Citation, FlowStart, Signal } from '@/lib/types';
import ActivityPanel from './ActivityPanel';
import AgentSteps, { stepsDuration } from './AgentSteps';
import GuidedFlow from './GuidedFlow';
import Home from './Home';
import IndustryModal from './IndustryModal';
import { AssistantMessage, UserMessage, relativeTime, scrollToBottom, sleep } from './common';

type ChatItem =
  | { id: string; kind: 'user'; text: string }
  | { id: string; kind: 'thinking' }
  | { id: string; kind: 'answer'; text: string; streaming: boolean; sectionTitles: string[]; citations: Citation[] }
  | { id: string; kind: 'steps'; title: string; icon: string; steps: string[] }
  | { id: string; kind: 'flow'; data: FlowStart }
  | { id: string; kind: 'notice'; tone: 'error' | 'info' | 'warning'; title: string; subtitle?: string }
  | { id: string; kind: 'history-flow'; text: string; done: boolean };

let nextId = 0;
const uid = () => `i${++nextId}`;

const DEFAULT_PLACEHOLDER = 'Ask anything, or describe a task...';

export default function App() {
  const [state, setState] = useState<AppState | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [view, setView] = useState<'home' | 'chat'>('home');
  const [items, setItems] = useState<ChatItem[]>([]);
  const [chatId, setChatIdState] = useState<number | null>(null);
  const chatIdRef = useRef<number | null>(null);
  const [busy, setBusy] = useState(false);
  const [input, setInput] = useState('');
  const [placeholder, setPlaceholder] = useState(DEFAULT_PLACEHOLDER);
  const [navOpen, setNavOpen] = useState(false);
  const [activityOpen, setActivityOpen] = useState(false);
  const [activityVersion, setActivityVersion] = useState(0);
  const [newActivity, setNewActivity] = useState(0);
  const [confirmReset, setConfirmReset] = useState(false);
  const [resetting, setResetting] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [fallbackOffline, setFallbackOffline] = useState(false);
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const setChatId = (id: number | null) => {
    chatIdRef.current = id;
    setChatIdState(id);
  };

  const refresh = useCallback(async () => {
    const s = await api<AppState>('/api/state');
    setState(s);
    setLoadError(null);
    return s;
  }, []);

  useEffect(() => {
    refresh().catch((err) => setLoadError(err.message));
  }, [refresh]);

  useEffect(() => {
    if (state) document.title = `${state.industry.logo_text} AI Assistant`;
  }, [state]);

  const push = (...add: ChatItem[]) => setItems((prev) => [...prev, ...add]);
  const patch = (id: string, p: Partial<ChatItem>) => setItems((prev) => prev.map((it) => (it.id === id ? ({ ...it, ...p } as ChatItem) : it)));
  const remove = (id: string) => setItems((prev) => prev.filter((it) => it.id !== id));

  const goHome = useCallback(() => {
    setNavOpen(false);
    setView('home');
    setItems([]);
    setChatId(null);
    setPlaceholder(DEFAULT_PLACEHOLDER);
    refresh().catch(() => {});
    document.getElementById('scroller')?.scrollTo({ top: 0 });
  }, [refresh]);

  const openChat = async (id: number) => {
    setNavOpen(false);
    if (busy) return;
    try {
      const data = await api<{ messages: { role: string; kind: string; content: string; payload: any }[] }>(`/api/chats/${id}`);
      const restored: ChatItem[] = data.messages.map((m) => {
        if (m.role === 'user') return { id: uid(), kind: 'user', text: m.content };
        if (m.kind === 'flow') return { id: uid(), kind: 'history-flow', text: m.content, done: m.payload?.stage === 'completed' };
        const cites: Citation[] = m.payload?.citations || [];
        return { id: uid(), kind: 'answer', text: m.content, streaming: false, sectionTitles: cites.map((c) => c.title), citations: cites };
      });
      setItems(restored);
      setChatId(id);
      setView('chat');
      requestAnimationFrame(() => scrollToBottom(true));
    } catch (err: any) {
      showError(err.message);
    }
  };

  const showError = (message: string) => {
    setView('chat');
    push({ id: uid(), kind: 'notice', tone: 'error', title: 'Something went wrong.', subtitle: message });
  };

  // --- Guided flows ---------------------------------------------------------

  const startFlow = async (slug: string, opts: { signalId?: number; userText?: string; title?: string } = {}) => {
    setNavOpen(false);
    setBusy(true);
    setView('chat');
    const shown = opts.userText || (opts.signalId && opts.title ? `Show me: ${opts.title}` : `Start: ${opts.title || slug}`);
    if (!opts.userText) push({ id: uid(), kind: 'user', text: shown });
    try {
      const data = await api<FlowStart>(`/api/flows/${slug}/start`, {
        chat_id: chatIdRef.current,
        signal_id: opts.signalId,
        user_text: shown,
        title: opts.title,
      });
      setChatId(data.chat.id);
      push({ id: uid(), kind: 'flow', data });
    } catch (err: any) {
      showError(err.message);
    } finally {
      setBusy(false);
      refresh().catch(() => {});
    }
  };

  const startAssistant = (a: Assistant) => {
    setNavOpen(false);
    if (a.flow_type === 'qa') {
      setPlaceholder(`Ask the ${a.title.replace(/^Ask the /i, '')}...`);
      inputRef.current?.focus();
      return;
    }
    startFlow(a.slug, { title: a.title });
  };

  // --- Free text ------------------------------------------------------------

  const sendMessage = async (raw: string) => {
    const text = raw.trim();
    if (!text || busy) return;
    setInput('');
    inputRef.current?.blur(); // so presenter shortcuts work right away
    setBusy(true);
    setView('chat');
    push({ id: uid(), kind: 'user', text });
    requestAnimationFrame(() => scrollToBottom(true));

    const thinkingId = uid();
    const answerId = uid();
    let answerShown = false;
    let full = '';
    let sectionTitles: string[] = [];
    const showAnswer = () => {
      if (answerShown) return;
      answerShown = true;
      remove(thinkingId);
      push({ id: answerId, kind: 'answer', text: '', streaming: true, sectionTitles, citations: [] });
    };

    try {
      const res = await streamPost<{ type: string; flow_slug: string }>(
        '/api/message',
        { chat_id: chatIdRef.current, text },
        {
          chat: (c) => {
            setChatId(c.id);
            push({ id: thinkingId, kind: 'thinking' });
          },
          qa: async (d) => {
            remove(thinkingId);
            sectionTitles = d.sections.map((s: Citation) => s.title);
            push({ id: uid(), kind: 'steps', title: d.flow.title, icon: d.flow.icon, steps: d.agent_steps });
            await sleep(stepsDuration(d.agent_steps.length, true));
          },
          meta: (m) => {
            if (m.fallback) setFallbackOffline(true);
          },
          token: (d) => {
            showAnswer();
            full += d.t;
            patch(answerId, { text: full, sectionTitles });
            scrollToBottom();
          },
          warning: (d) => push({ id: uid(), kind: 'notice', tone: 'warning', title: d.message }),
          done: (d) => {
            showAnswer();
            const titles = sectionTitles.length ? sectionTitles : (d.citations || []).map((c: Citation) => c.title);
            patch(answerId, { text: d.text, streaming: false, sectionTitles: titles, citations: d.citations || [] });
            scrollToBottom();
          },
          error: (d) => {
            remove(thinkingId);
            push({ id: uid(), kind: 'notice', tone: 'error', title: 'Something went wrong.', subtitle: d.message });
          },
        }
      );
      if (res && res.type === 'flow') {
        setBusy(false);
        await startFlow(res.flow_slug, { userText: text });
        return;
      }
    } catch (err: any) {
      remove(thinkingId);
      showError(err.message);
    } finally {
      setBusy(false);
      refresh().catch(() => {});
    }
  };

  // --- Presenter controls ---------------------------------------------------

  const switchIndustry = useCallback(
    async (slug: string) => {
      setModalOpen(false);
      if (state && state.industry.slug === slug) return;
      await api('/api/state/industry', { slug });
      setNewActivity(0);
      setFallbackOffline(false);
      goHome();
    },
    [state, goHome]
  );

  const toggleOffline = useCallback(async () => {
    const mode = await api<AppState['mode']>('/api/state/offline', { enabled: !(state && state.mode.forced) });
    setFallbackOffline(false);
    setState((s) => (s ? { ...s, mode } : s));
  }, [state]);

  const resetDemo = useCallback(async () => {
    await api('/api/reset', {});
    setConfirmReset(false);
    setModalOpen(false);
    setActivityOpen(false);
    setNewActivity(0);
    setFallbackOffline(false);
    setActivityVersion((v) => v + 1);
    goHome();
  }, [goHome]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (activityOpen) setActivityOpen(false);
        setNavOpen(false);
        return;
      }
      if (modalOpen && /^[1-9]$/.test(e.key) && state) {
        const ind = state.industries[Number(e.key) - 1];
        if (ind) switchIndustry(ind.slug);
        return;
      }
      const el = e.target as HTMLElement | null;
      const typing = el && (el.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(el.tagName));
      if (!e.shiftKey || e.metaKey || e.ctrlKey || e.altKey || typing) return;
      const k = e.key.toLowerCase();
      if (k === 'i') {
        e.preventDefault();
        setModalOpen((o) => !o);
      } else if (k === 'o') {
        e.preventDefault();
        toggleOffline().catch(console.error);
      } else if (k === 'r') {
        e.preventDefault();
        resetDemo().catch(console.error);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [activityOpen, modalOpen, state, switchIndustry, toggleOffline, resetDemo]);

  const openActivity = () => {
    setActivityOpen(true);
    setNewActivity(0);
    setActivityVersion((v) => v + 1);
  };

  // --- Render ---------------------------------------------------------------

  if (!state) {
    return (
      <div className="boot">
        {loadError ? (
          <InlineNotification kind="error" lowContrast hideCloseButton title="Cannot reach the API server." subtitle={`${loadError}. Is "node server.js" running?`} />
        ) : (
          <InlineLoading description="Loading..." />
        )}
      </div>
    );
  }

  const offline = state.mode.offline || fallbackOffline;
  const statusTitle = offline
    ? `Offline${state.mode.forced ? ' (toggled)' : !state.mode.hasKey ? ' (no API key)' : fallbackOffline ? ' (live model unreachable)' : ''}`
    : `Live: ${state.mode.model}`;
  const activeChat = state.chats.find((c) => c.id === chatId);
  const recent = state.chats.filter((c) => c.id !== chatId).slice(0, 8);
  const initials = state.user ? state.user.name.split(' ').map((p) => p[0]).slice(0, 2).join('') : '';

  return (
    <>
      <Header aria-label={`${state.industry.logo_text} AI Assistant`}>
        <SkipToContent href="#main-content" />
        <HeaderMenuButton aria-label={navOpen ? 'Close menu' : 'Open menu'} isActive={navOpen} onClick={() => setNavOpen((o) => !o)} />
        <HeaderName
          href="#"
          prefix={state.industry.logo_text}
          onClick={(e: React.MouseEvent) => {
            e.preventDefault();
            goHome();
          }}
        >
          AI Assistant
        </HeaderName>
        <HeaderGlobalBar>
          <HeaderGlobalAction aria-label="Reset demo" tooltipAlignment="end" onClick={() => setConfirmReset(true)}>
            <Reset size={20} />
          </HeaderGlobalAction>
          <HeaderGlobalAction
            aria-label="Activity"
            isActive={activityOpen}
            tooltipAlignment="end"
            onClick={() => (activityOpen ? setActivityOpen(false) : openActivity())}
          >
            <span className="activity-action">
              <Activity size={20} />
              {newActivity > 0 && <span className="activity-badge">{newActivity}</span>}
            </span>
          </HeaderGlobalAction>
          <div className="header-user">
            <span className="header-user__who">
              {state.user?.name}, {state.user?.role}
            </span>
            <span className="avatar" aria-hidden="true">
              {initials}
            </span>
          </div>
          {/* Presenter-only status: green = live model, gray = offline responses. */}
          <span className={`status-dot${offline ? ' is-offline' : ''}`} title={statusTitle} aria-hidden="true" />
        </HeaderGlobalBar>
      </Header>

      <SideNav aria-label="Chats and assistants" expanded={navOpen} onOverlayClick={() => setNavOpen(false)} onSideNavBlur={() => setNavOpen(false)} className="app-nav" href="#">
        <SideNavItems>
          <li className="app-nav__new">
            <Button kind="primary" size="md" renderIcon={Add} onClick={goHome}>
              New chat
            </Button>
          </li>
          <SideNavLink
            href="#"
            renderIcon={HomeIcon}
            isActive={view === 'home'}
            onClick={(e: React.MouseEvent) => {
              e.preventDefault();
              goHome();
            }}
          >
            Today&apos;s signals
          </SideNavLink>
          {chatId && (
            <>
              <li className="app-nav__label">Active chat</li>
              <SideNavLink href="#" renderIcon={Chat} isActive onClick={(e: React.MouseEvent) => e.preventDefault()}>
                {activeChat ? activeChat.title : 'New chat'}
              </SideNavLink>
            </>
          )}
          <li className="app-nav__label">Recent chats</li>
          {recent.length === 0 && <li className="app-nav__empty">No other chats yet</li>}
          {recent.map((c) => (
            <SideNavLink
              key={c.id}
              href="#"
              renderIcon={Chat}
              title={c.title}
              onClick={(e: React.MouseEvent) => {
                e.preventDefault();
                openChat(c.id);
              }}
            >
              <span className="app-nav__chat">
                <span className="app-nav__chat-title">{c.title}</span>
                <span className="app-nav__chat-time">{relativeTime(c.updated_at, true)}</span>
              </span>
            </SideNavLink>
          ))}
          <SideNavDivider />
          <li className="app-nav__label">Assistants</li>
          {state.assistants.map((a) => (
            <SideNavLink
              key={a.slug}
              href="#"
              renderIcon={iconFor(a.icon)}
              title={a.description}
              onClick={(e: React.MouseEvent) => {
                e.preventDefault();
                startAssistant(a);
              }}
            >
              {a.title}
            </SideNavLink>
          ))}
          <li className="app-nav__footer">
            <Enterprise size={16} />
            <span>{state.industry.company_name}</span>
          </li>
        </SideNavItems>
      </SideNav>

      <main className="main" id="main-content">
        <div className="scroller" id="scroller">
          <div className="column">
            {view === 'home' ? (
              <Home state={state} onSignal={(s: Signal) => startFlow(s.flow_slug, { signalId: s.id, title: s.title })} onSuggestion={sendMessage} />
            ) : (
              <section className="chat" aria-live="polite">
                {items.map((it) => (
                  <ChatItemView
                    key={it.id}
                    item={it}
                    state={state}
                    chatId={() => chatIdRef.current}
                    onChanged={() => refresh().catch(() => {})}
                    onActivity={(n) => (activityOpen ? setActivityVersion((v) => v + 1) : setNewActivity((c) => c + n))}
                    onOpenActivity={openActivity}
                    onGoHome={goHome}
                    onError={showError}
                    onFallback={() => setFallbackOffline(true)}
                  />
                ))}
              </section>
            )}
          </div>
        </div>
        <div className="composer-wrap">
          <div className="column">
            <form
              className="composer"
              onSubmit={(e) => {
                e.preventDefault();
                sendMessage(input);
              }}
            >
              <label htmlFor="composer-input" className="cds--visually-hidden">
                Message
              </label>
              <textarea
                id="composer-input"
                ref={inputRef}
                rows={1}
                value={input}
                placeholder={placeholder}
                onChange={(e) => {
                  setInput(e.target.value);
                  const ta = e.target;
                  ta.style.height = 'auto';
                  ta.style.height = `${Math.min(ta.scrollHeight, 192)}px`;
                }}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' && !e.shiftKey && !e.nativeEvent.isComposing) {
                    e.preventDefault();
                    sendMessage(input);
                  }
                }}
              />
              <Button type="submit" kind="primary" size="lg" hasIconOnly renderIcon={SendFilled} iconDescription="Send" tooltipPosition="left" disabled={busy || !input.trim()} />
            </form>
          </div>
        </div>
      </main>

      <ActivityPanel open={activityOpen} version={activityVersion} industry={state.industry.slug} onClose={() => setActivityOpen(false)} />
      <IndustryModal open={modalOpen} industries={state.industries} current={state.industry.slug} onSelect={switchIndustry} onClose={() => setModalOpen(false)} />
      <Modal
        open={confirmReset}
        danger
        size="sm"
        modalHeading="Reset the demo?"
        primaryButtonText={resetting ? 'Resetting...' : 'Reset'}
        primaryButtonDisabled={resetting}
        secondaryButtonText="Cancel"
        onRequestClose={() => !resetting && setConfirmReset(false)}
        onRequestSubmit={async () => {
          setResetting(true);
          try {
            await resetDemo();
          } catch (err: any) {
            setConfirmReset(false);
            showError(err.message);
          } finally {
            setResetting(false);
          }
        }}
      >
        <p className="prose">
          Clears everything done since the demo started: messages sent, &quot;Contacted today&quot; marks, tasks and new chats. The seeded history stays.
        </p>
      </Modal>
    </>
  );
}

type ItemProps = {
  item: ChatItem;
  state: AppState;
  chatId: () => number | null;
  onChanged: () => void;
  onActivity: (n: number) => void;
  onOpenActivity: () => void;
  onGoHome: () => void;
  onError: (message: string) => void;
  onFallback: () => void;
};

function ChatItemView({ item, state, ...rest }: ItemProps) {
  switch (item.kind) {
    case 'user':
      return <UserMessage text={item.text} />;
    case 'thinking':
      return (
        <AssistantMessage>
          <InlineLoading description="Thinking..." className="thinking" />
        </AssistantMessage>
      );
    case 'answer':
      return (
        <AssistantMessage>
          <div className="prose" dangerouslySetInnerHTML={{ __html: renderMarkdown(item.text, item.sectionTitles) + (item.streaming ? '<span class="cursor"></span>' : '') }} />
          {item.citations.length > 0 && <Sources citations={item.citations} />}
        </AssistantMessage>
      );
    case 'steps':
      return <AgentSteps title={item.title} icon={item.icon} steps={item.steps} compact />;
    case 'flow':
      return (
        <GuidedFlow
          data={item.data}
          recordNoun={state.industry.record_noun}
          userName={state.user?.name || ''}
          model={state.mode.model}
          {...rest}
        />
      );
    case 'notice':
      return (
        <AssistantMessage>
          <InlineNotification kind={item.tone} lowContrast hideCloseButton title={item.title} subtitle={item.subtitle} />
        </AssistantMessage>
      );
    case 'history-flow':
      return (
        <AssistantMessage>
          <div className={`history-flow${item.done ? ' is-complete' : ''}`}>
            {item.done ? <CheckmarkFilled size={20} /> : <Flash size={20} />}
            <div>
              {item.text.split('\n').map((line, i) => (
                <div key={i}>{line}</div>
              ))}
            </div>
          </div>
        </AssistantMessage>
      );
  }
}

function Sources({ citations }: { citations: Citation[] }) {
  const Book = iconFor('book');
  const Doc = iconFor('document');
  return (
    <div className="sources">
      <div className="sources__label">
        <Book size={14} />
        {citations.length === 1 ? 'Source' : 'Sources'}
      </div>
      {citations.map((c) => (
        <div key={c.title} className="source">
          <Doc size={20} className="source__icon" />
          <div>
            <div className="source__title">{c.title}</div>
            <div className="source__meta">{c.source}</div>
            {c.excerpt && <div className="source__excerpt">{c.excerpt}</div>}
          </div>
        </div>
      ))}
    </div>
  );
}
