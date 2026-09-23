// Minimal, safe markdown for assistant answers. Input is HTML-escaped first, then a
// small set of patterns is turned into markup: **bold**, *em*, `code`, lists,
// paragraphs, and [Section title] citations of knowledge base sections.

// Carbon "book" icon (@carbon/icons), inlined because this markup is built as a string.
const BOOK_ICON =
  '<svg class="cite__icon" viewBox="0 0 32 32" aria-hidden="true"><path d="M19 10H26V12H19z"/><path d="M19 15H26V17H19z"/><path d="M19 20H26V22H19z"/><path d="M6 10H13V12H6z"/><path d="M6 15H13V17H6z"/><path d="M6 20H13V22H6z"/><path d="M28,5H4A2.002,2.002,0,0,0,2,7V25a2.002,2.002,0,0,0,2,2H28a2.002,2.002,0,0,0,2-2V7A2.002,2.002,0,0,0,28,5ZM4,7H15V25H4ZM17,25V7H28V25Z"/></svg>';

function escapeHtml(s: string) {
  return s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]!);
}

function unescape(s: string) {
  return s.replace(/&amp;/g, '&').replace(/&#39;/g, "'").replace(/&quot;/g, '"').replace(/&lt;/g, '<').replace(/&gt;/g, '>');
}

export function renderMarkdown(src: string, sectionTitles: string[] = []): string {
  const titles = new Set(sectionTitles);
  const inline = (s: string) =>
    escapeHtml(s)
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      .replace(/(^|[^*])\*(?!\s)(.+?)\*(?!\*)/g, '$1<em>$2</em>')
      .replace(/`([^`]+)`/g, '<code>$1</code>')
      .replace(/\[([^\]]{3,90})\]/g, (m, t: string) =>
        titles.has(unescape(t)) ? `<span class="cite" title="Knowledge base section">${BOOK_ICON}${t}</span>` : m
      );

  let html = '';
  let list: 'ul' | 'ol' | null = null;
  let para: string[] = [];
  const flushPara = () => {
    if (para.length) html += `<p>${para.map(inline).join('<br>')}</p>`;
    para = [];
  };
  const closeList = () => {
    if (list) html += `</${list}>`;
    list = null;
  };
  for (const line of src.replace(/\r/g, '').split('\n')) {
    const ul = line.match(/^\s*[-*•]\s+(.*)$/);
    const ol = line.match(/^\s*\d+[.)]\s+(.*)$/);
    if (ul || ol) {
      flushPara();
      const kind = ul ? 'ul' : 'ol';
      if (list !== kind) {
        closeList();
        html += `<${kind}>`;
        list = kind;
      }
      html += `<li>${inline((ul || ol)![1])}</li>`;
    } else if (!line.trim()) {
      flushPara();
      closeList();
    } else {
      closeList();
      para.push(line.replace(/^#+\s*/, ''));
    }
  }
  flushPara();
  closeList();
  return html;
}
