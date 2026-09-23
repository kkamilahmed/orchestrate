'use client';

import { Modal, RadioTile, TileGroup } from '@carbon/react';
import type { Industry } from '@/lib/types';

type Props = {
  open: boolean;
  industries: Industry[];
  current: string;
  onSelect: (slug: string) => void;
  onClose: () => void;
};

// Presenter-only: opened with Shift+I, never linked from the UI.
export default function IndustryModal({ open, industries, current, onSelect, onClose }: Props) {
  return (
    <Modal open={open} passiveModal modalLabel="Presenter" modalHeading="Switch industry" onRequestClose={onClose} size="md" className="industry-modal" selectorPrimaryFocus="input[type=radio]:checked">
      {open && (
        <TileGroup legend="Industry" name="industry" valueSelected={current} onChange={(value: string | number | undefined) => onSelect(String(value))} className="industry-list">
          {industries.map((ind, i) => (
            <RadioTile key={ind.slug} id={`industry-${ind.slug}`} value={ind.slug} className="industry-option">
              <span className="industry-option__key">{i + 1}</span>
              <span className="industry-option__name">{ind.name}</span>
              <span className="industry-option__company">{ind.company_name}</span>
            </RadioTile>
          ))}
        </TileGroup>
      )}
      <p className="modal-keys">
        Press <kbd>1</kbd>-<kbd>{industries.length}</kbd> to switch, <kbd>Esc</kbd> to close. <kbd>Shift+O</kbd> toggles offline, <kbd>Shift+R</kbd> resets the demo.
      </p>
    </Modal>
  );
}
