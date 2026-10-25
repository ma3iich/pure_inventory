import React, { useMemo } from 'react';
import { useAppSelector } from '../../store';
import { selectLeftInventory } from '../../store/inventory';
import { getTotalWeight } from '../../helpers';
import { Locale } from '../../store/locale';

// Weight of the player: ring that fills up + "12.5 kg".
const WeightRing: React.FC = () => {
  const inventory = useAppSelector(selectLeftInventory);
  const weight = useMemo(() => getTotalWeight(inventory.items), [inventory.items]);
  const max = inventory.maxWeight || 0;
  const ratio = max > 0 ? Math.min(1, weight / max) : 0;
  const circumference = 2 * Math.PI * 15;
  const color = ratio > 0.9 ? '#e5484d' : ratio > 0.7 ? '#e6a23c' : 'var(--pi-weight-color)';

  return (
    <div className="weight-ring" title={`${Locale.ui_weight || 'Weight'} : ${(weight / 1000).toFixed(1)} / ${(max / 1000).toFixed(1)} kg`}>
      <svg viewBox="0 0 36 36">
        <circle cx="18" cy="18" r="15" className="weight-ring-back" />
        <circle
          cx="18"
          cy="18"
          r="15"
          className="weight-ring-fill"
          style={{ stroke: color, strokeDasharray: `${circumference * ratio} ${circumference}` }}
        />
      </svg>
      <span>{(weight / 1000).toLocaleString('en-us', { maximumFractionDigits: 1 })} kg</span>
    </div>
  );
};

export default WeightRing;
