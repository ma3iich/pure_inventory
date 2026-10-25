import React, { useEffect, useRef } from 'react';
import { fetchNui } from '../../utils/fetchNui';
import { setPendingLabel, stopRename } from '../../store/rename';
import { useSettings } from '../../store/settings';

// Right click > Rename: the name is typed in the slot itself.
// Enter or click elsewhere = save, Escape = cancel (without closing the inventory).
const RenameInput: React.FC<{ slot: number; label: string }> = ({ slot, label }) => {
  const { features } = useSettings();
  const ref = useRef<HTMLTextAreaElement>(null);
  const done = useRef(false);
  const opened = useRef(Date.now());

  const finish = (save: boolean) => {
    if (done.current) return;
    done.current = true;

    const text = (ref.current?.value || '').replace(/\s+/g, ' ').trim();

    if (save && text !== '' && text !== label) {
      setPendingLabel(slot, text);
      fetchNui('renameEnd', { slot, label: text }).catch(() => {});
    } else {
      fetchNui('renameEnd', {}).catch(() => {});
    }

    stopRename();
  };

  useEffect(() => {
    fetchNui('renameStart').catch(() => {});

    const element = ref.current;
    if (element) {
      element.focus();
      element.select();
    }

    return () => {
      if (!done.current) {
        done.current = true;
        fetchNui('renameEnd', {}).catch(() => {});
      }
    };
  }, []);

  const resize = () => {
    const element = ref.current;
    if (!element) return;
    element.style.height = 'auto';
    element.style.height = `${element.scrollHeight}px`;
  };

  useEffect(resize, []);

  const stop = (event: React.SyntheticEvent) => event.stopPropagation();

  return (
    <textarea
      ref={ref}
      className="rename-input"
      defaultValue={label}
      maxLength={features.renameMax || 32}
      rows={1}
      spellCheck={false}
      onInput={resize}
      onKeyDown={(event) => {
        event.stopPropagation();
        if (event.key === 'Enter') {
          event.preventDefault();
          finish(true);
        } else if (event.key === 'Tab') {
          event.preventDefault();
        }
      }}
      onKeyUp={(event) => {
        // the inventory closes on Escape key up: cancel the rename only
        event.stopPropagation();
        if (event.key === 'Escape') finish(false);
      }}
      onBlur={() => {
        // the right click menu that closes can take the focus back for a moment
        if (Date.now() - opened.current < 400) {
          ref.current?.focus();
          return;
        }
        finish(true);
      }}
      onMouseDown={stop}
      onMouseUp={stop}
      onClick={stop}
      onContextMenu={stop}
    />
  );
};

export default RenameInput;
