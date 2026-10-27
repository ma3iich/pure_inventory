import React from 'react';
import { useDrag, useDrop } from 'react-dnd';
import { DragSource } from '../../typings';
import { HangerConfig } from '../../store/settings';
import { fetchNui } from '../../utils/fetchNui';
import { imagepath } from '../../store/imagepath';
import { Locale } from '../../store/locale';
import ClothingIcon from './ClothingIcon';

// Outfit on the hanger, as the game sends it: its name and the number of worn pieces it holds.
export interface HangerState {
  label: string;
  count: number;
}

export interface HangerDragSource {
  hanger: true;
  image: string;
}

// Hanger slot, under the clothing slots: an outfit (or an empty hanger) dropped here is put on; click it or drag it
// into the inventory to take the whole outfit off.
const HangerTile: React.FC<{ config: HangerConfig; outfit?: HangerState | null }> = ({ config, outfit }) => {
  const on = !!outfit;
  const picture = `${imagepath}/${config.outfitItem}.png`;
  const [broken, setBroken] = React.useState(false);

  const [{ isDragging }, drag] = useDrag<HangerDragSource, void, { isDragging: boolean }>(
    () => ({
      type: 'HANGER',
      item: () => ({ hanger: true, image: `url(${picture})` }),
      canDrag: () => on,
      collect: (monitor) => ({ isDragging: monitor.isDragging() }),
    }),
    [on, picture]
  );

  const fits = (name?: string) => name === config.outfitItem || name === config.hangerItem;

  const [{ isOver, wrong }, drop] = useDrop<DragSource, void, { isOver: boolean; wrong: boolean }>(
    () => ({
      accept: 'SLOT',
      canDrop: (source) => source.inventory === 'player',
      // the game says why another item does not go here
      drop: (source) => {
        fetchNui('hangerDrop', { slot: source.item.slot });
      },
      collect: (monitor) => ({
        isOver: monitor.isOver() && monitor.canDrop(),
        wrong: !fits(monitor.getItem<DragSource>()?.item?.name),
      }),
    }),
    [config.outfitItem, config.hangerItem]
  );

  const tip = on
    ? `${outfit.label}\n${(Locale.ui_hanger_count || '%s piece(s) of clothing').replace('%s', String(outfit.count))}\n${Locale.ui_hanger_takeoff || ''}`
    : `${config.label}\n${Locale.ui_hanger_puton || ''}`;

  return (
    <button
      ref={(element) => drag(drop(element))}
      className={`clothing-tile clothing-tile--hanger ${on ? 'is-on has-outfit' : 'is-off'}${isOver ? (wrong ? ' is-wrong' : ' is-over') : ''}${isDragging ? ' is-dragging' : ''}`}
      data-tip={tip}
      onClick={() => on && fetchNui('hangerTakeOff', {})}
    >
      {on && !broken ? (
        <img src={picture} alt="" className="clothing-tile-picture" draggable={false} onError={() => setBroken(true)} />
      ) : (
        <ClothingIcon icon="hanger" className="clothing-tile-icon" />
      )}
      {on && (
        <>
          <span className="clothing-tile-name">{outfit.label}</span>
          <span className="clothing-tile-lock clothing-tile-count">{outfit.count}</span>
        </>
      )}
    </button>
  );
};

export default HangerTile;
