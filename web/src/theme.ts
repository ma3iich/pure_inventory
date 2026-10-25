// Applies Config.Theme (config.lua) as CSS variables. Every value is optional: the defaults are in pure.scss.

type Theme = Record<string, unknown>;

const hexToRgb = (value: unknown): string | null => {
  if (typeof value !== 'string') return null;
  let hex = value.trim().replace('#', '');
  if (hex.length === 3) hex = hex.split('').map((c) => c + c).join('');
  if (!/^[0-9a-fA-F]{6}$/.test(hex)) return null;
  const n = parseInt(hex, 16);
  return `${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}`;
};

const num = (value: unknown): number | null =>
  typeof value === 'number' && isFinite(value) ? value : null;

const loadedFonts = new Set<string>();

const loadFont = (font: string) => {
  if (loadedFonts.has(font) || !/^[\w\s-]+$/.test(font)) return;
  loadedFonts.add(font);
  const link = document.createElement('link');
  link.rel = 'stylesheet';
  link.href = `https://fonts.googleapis.com/css2?family=${encodeURIComponent(font)}:wght@400;500;600;700&display=swap`;
  document.head.appendChild(link);
};

export const applyTheme = (theme: Theme) => {
  const style = document.documentElement.style;
  const set = (name: string, value: string | null) => value !== null && style.setProperty(name, value);
  const color = (name: string, colorKey: string, opacityKey?: string) => {
    const rgb = hexToRgb(theme[colorKey]);
    if (!rgb) return;
    const opacity = opacityKey ? num(theme[opacityKey]) : null;
    set(name, opacity !== null ? `rgba(${rgb}, ${opacity})` : `rgb(${rgb})`);
  };
  const vh = (name: string, key: string) => {
    const value = num(theme[key]);
    set(name, value !== null ? `${value}vh` : null);
  };

  if (typeof theme.Font === 'string' && theme.Font !== '') {
    loadFont(theme.Font);
    set('--pi-font', `'${theme.Font}', Roboto, sans-serif`);
  }

  vh('--pi-slot-size', 'SlotSize');
  vh('--pi-slot-gap', 'SlotGap');
  vh('--pi-item-image', 'ItemImageSize');
  vh('--pi-clothing-size', 'ClothingSlotSize');
  vh('--pi-clothing-icon', 'ClothingIconSize');

  const offset = num(theme.ClothingDistance);
  if (offset !== null) set('--pi-clothing-offset', `${offset}vw`);

  const columns = num(theme.Columns);
  const rows = num(theme.VisibleRows);
  if (columns) set('--pi-columns', String(Math.max(1, Math.round(columns))));
  if (rows) set('--pi-rows', String(Math.max(1, Math.round(rows))));

  const radius = num(theme.SlotRadius);
  if (radius !== null) set('--pi-radius', `${radius}px`);

  color('--pi-slot-bg', 'SlotColor', 'SlotOpacity');
  if (hexToRgb(theme.SlotColor) && num(theme.SlotHoverOpacity) !== null)
    set('--pi-slot-hover', `rgba(${hexToRgb(theme.SlotColor)}, ${num(theme.SlotHoverOpacity)})`);
  color('--pi-outline', 'SlotOutline');
  color('--pi-label-bg', 'LabelColor', 'LabelOpacity');
  color('--pi-text', 'TextColor');
  color('--pi-menu-bg', 'MenuColor', 'MenuOpacity');
  color('--pi-menu-button', 'MenuButtonColor');
  color('--pi-clothing-icon-color', 'ClothingIconColor');
  color('--pi-worn', 'WornColor');
  color('--pi-not-worn', 'NotWornColor');

  set('--pi-label-transform', theme.UppercaseLabels === true ? 'uppercase' : 'none');
};
