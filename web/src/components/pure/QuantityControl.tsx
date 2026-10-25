import React from 'react';
import { useAppDispatch, useAppSelector } from '../../store';
import { selectItemAmount, setItemAmount } from '../../store/inventory';
import { Locale } from '../../store/locale';

// Amount moved / used / given: × = whole stack (0), › = one more, or typed with the keyboard.
const QuantityControl: React.FC = () => {
  const amount = useAppSelector(selectItemAmount);
  const dispatch = useAppDispatch();

  const set = (value: number) => dispatch(setItemAmount(Math.max(0, Math.min(1000000, Math.floor(value) || 0))));

  return (
    <div className="quantity" title={Locale.ui_amount_hint || ''}>
      <button className="quantity-button" onClick={() => set(0)} title={Locale.ui_amount_all || ''}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.4} strokeLinecap="round">
          <path d="M7 7l10 10M17 7 7 17" />
        </svg>
      </button>
      <input
        className="quantity-value"
        type="number"
        min={0}
        value={amount}
        onChange={(event) => set(event.target.valueAsNumber)}
        onFocus={(event) => event.target.select()}
      />
      <button className="quantity-button" onClick={() => set(amount + 1)} title={Locale.ui_amount_more || ''}>
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={2.4} strokeLinecap="round" strokeLinejoin="round">
          <path d="m9 5 7 7-7 7" />
        </svg>
      </button>
    </div>
  );
};

export default QuantityControl;
