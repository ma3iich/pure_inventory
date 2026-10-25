import React, { useEffect, useRef, useState } from 'react';
import { useDrop } from 'react-dnd';
import { DragSource } from '../../typings';
import { useSettings } from '../../store/settings';
import { fetchNui } from '../../utils/fetchNui';
import useNuiEvent from '../../hooks/useNuiEvent';
import { onUse } from '../../dnd/onUse';
import { Locale } from '../../store/locale';
import ClothingTile from './ClothingTile';
import QuantityControl from './QuantityControl';
import WeightRing from './WeightRing';

interface ClothingState {
  supported: boolean;
  worn: Record<string, boolean>;
}

// Middle of the inventory: the 3D character (drawn by the game, see modules/preview/client.lua), the clothing
// slots on each side, and at the bottom the amount and the weight.
const CenterColumn: React.FC = () => {
  const { features, clothing } = useSettings();
  const [state, setState] = useState<ClothingState>({ supported: false, worn: {} });
  const dragging = useRef<{ x: number; total: number; timer: number | null } | null>(null);

  useEffect(() => {
    let mounted = true;

    if (features.preview || features.clothing) {
      fetchNui<ClothingState>('previewStart')
        .then((data) => mounted && data && setState({ supported: !!data.supported, worn: data.worn || {} }))
        .catch(() => {});
    }

    return () => {
      mounted = false;
      if (features.preview || features.clothing) fetchNui('previewStop').catch(() => {});
    };
  }, [features.preview, features.clothing]);

  useNuiEvent<ClothingState>('clothingState', (data) => setState({ supported: !!data.supported, worn: data.worn || {} }));

  // an item of the player dropped on the character is used (clothes are put on)
  const [{ isOver }, drop] = useDrop<DragSource, void, { isOver: boolean }>(
    () => ({
      accept: 'SLOT',
      canDrop: (source) => source.inventory === 'player',
      drop: (source) => onUse(source.item as any),
      collect: (monitor) => ({ isOver: monitor.isOver() && monitor.canDrop() }),
    }),
    []
  );

  // hold left click and move = rotate the character, wheel = zoom
  useEffect(() => {
    const send = () => {
      const drag = dragging.current;
      if (!drag) return;
      drag.timer = null;
      if (drag.total === 0) return;
      fetchNui('previewRotate', { dx: drag.total }).catch(() => {});
      drag.total = 0;
    };

    const move = (event: MouseEvent) => {
      const drag = dragging.current;
      if (!drag) return;
      drag.total += (event.clientX - drag.x) / (window.innerWidth || 1);
      drag.x = event.clientX;
      if (drag.timer === null) drag.timer = window.setTimeout(send, 30);
    };

    const up = () => {
      if (!dragging.current) return;
      send();
      dragging.current = null;
      document.body.classList.remove('preview-rotating');
    };

    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
    window.addEventListener('blur', up);

    return () => {
      window.removeEventListener('mousemove', move);
      window.removeEventListener('mouseup', up);
      window.removeEventListener('blur', up);
    };
  }, []);

  const showTiles = features.clothing && state.supported && clothing.length > 0;
  const left = clothing.filter((slot) => slot.side === 'left');
  const right = clothing.filter((slot) => slot.side === 'right');
  const rows = Math.max(left.length, right.length, 1);

  return (
    <div className="center-column" style={{ ['--pi-clothing-rows' as any]: rows }}>
      {features.preview && (
        <div
          ref={drop}
          className={`preview-zone${isOver ? ' is-over' : ''}`}
          onMouseDown={(event) => {
            if (event.button !== 0) return;
            dragging.current = { x: event.clientX, total: 0, timer: null };
            document.body.classList.add('preview-rotating');
          }}
          onWheel={(event) => {
            if (event.deltaY === 0) return;
            fetchNui('previewZoom', {
              direction: event.deltaY < 0 ? 1 : -1,
              x: event.clientX / (window.innerWidth || 1),
              y: event.clientY / (window.innerHeight || 1),
            }).catch(() => {});
          }}
        >
          {isOver && <span className="preview-zone-text">{Locale.ui_use_on_character || 'Use'}</span>}
        </div>
      )}

      {showTiles && (
        <>
          <div className="clothing-column clothing-column--left">
            {left.map((slot) => (
              <ClothingTile key={slot.key} slot={slot} worn={!!state.worn[slot.key]} />
            ))}
          </div>
          <div className="clothing-column clothing-column--right">
            {right.map((slot) => (
              <ClothingTile key={slot.key} slot={slot} worn={!!state.worn[slot.key]} />
            ))}
          </div>
        </>
      )}

      <div className="bottom-bar">
        <QuantityControl />
        <WeightRing />
      </div>
    </div>
  );
};

export default CenterColumn;
