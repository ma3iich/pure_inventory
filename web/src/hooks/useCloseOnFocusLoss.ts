import { useEffect } from 'react';
import { fetchNui } from '../utils/fetchNui';

// Another resource opened a window (text input, menu...) and took the keyboard: the inventory closes,
// otherwise it would stay open behind and keep the mouse.
export const useCloseOnFocusLoss = (visible: boolean) => {
  useEffect(() => {
    if (!visible) return;

    let timer: number | null = null;

    const onBlur = () => {
      if (timer !== null) clearTimeout(timer);

      timer = window.setTimeout(() => {
        timer = null;
        if (!document.hasFocus()) fetchNui('exit').catch(() => {});
      }, 100);
    };

    window.addEventListener('blur', onBlur);

    return () => {
      window.removeEventListener('blur', onBlur);
      if (timer !== null) clearTimeout(timer);
    };
  }, [visible]);
};
