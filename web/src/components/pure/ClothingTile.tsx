import React from 'react';
import { useDrag, useDrop } from 'react-dnd';
import { DragSource } from '../../typings';
import { ClothingSlotConfig } from '../../store/settings';
import { fetchNui } from '../../utils/fetchNui';
import { imagepath } from '../../store/imagepath';
import { Locale } from '../../store/locale';
import ClothingIcon from './ClothingIcon';

export interface ClothingDragSource {
  clothing: string;
  image: string;
}

const Lock: React.FC<{ locked: boolean }> = ({ locked }) => (
  <svg viewBox="0 0 24 24" fill="currentColor">
    {locked ? (
      <path d="M8 10V7a4 4 0 1 1 8 0v3h1a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2zm2 0h4V7a2 2 0 1 0-4 0z" />
    ) : (
      <path d="M15 4a2 2 0 0 0-2 2v4h4a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-8a2 2 0 0 1 2-2h4V6a4 4 0 1 1 8 0v1h-2V6a2 2 0 0 0-2-2z" />
    )}
  </svg>
);

const ClothingTile: React.FC<{ slot: ClothingSlotConfig; worn: boolean; picture?: string }> = ({ slot, worn, picture }) => {
  // picture of the worn piece (pure_clothing); back to the icon when it cannot be loaded
  const [broken, setBroken] = React.useState<string | undefined>();
  const showPicture = worn && !!picture && broken !== picture;
  // a worn piece can be dragged into the player inventory to take it off
  const [{ isDragging }, drag] = useDrag<ClothingDragSource, void, { isDragging: boolean }>(
    () => ({
      type: 'CLOTHING',
      item: () => ({ clothing: slot.key, image: `url(${imagepath}/clothing_${slot.key}.png)` }),
      canDrag: () => worn,
      collect: (monitor) => ({ isDragging: monitor.isDragging() }),
    }),
    [slot.key, worn]
  );

  // an item of the player inventory dropped here is put on
  const [{ isOver }, drop] = useDrop<DragSource, void, { isOver: boolean }>(
    () => ({
      accept: 'SLOT',
      canDrop: (source) => source.inventory === 'player',
      drop: (source) => {
        fetchNui('clothingPutOn', { slot: source.item.slot, key: slot.key });
      },
      collect: (monitor) => ({ isOver: monitor.isOver() && monitor.canDrop() }),
    }),
    [slot.key]
  );

  const tip = `${slot.label}\n${worn ? Locale.ui_clothing_takeoff || '' : Locale.ui_clothing_puton || ''}`;

  return (
    <button
      ref={(element) => drag(drop(element))}
      className={`clothing-tile ${worn ? 'is-on' : 'is-off'}${isOver ? ' is-over' : ''}${isDragging ? ' is-dragging' : ''}`}
      data-tip={tip}
      onClick={() => worn && fetchNui('clothingTakeOff', { key: slot.key })}
    >
      {showPicture ? (
        <img src={picture} alt="" className="clothing-tile-picture" draggable={false} onError={() => setBroken(picture)} />
      ) : (
        <ClothingIcon icon={slot.icon} className="clothing-tile-icon" />
      )}
      <span className="clothing-tile-lock">
        <Lock locked={worn} />
      </span>
    </button>
  );
};

export default ClothingTile;
