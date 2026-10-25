import React from 'react';
// Built-in line icons of the clothing slots (24 x 24). Config.Clothing.Slots[].icon can also be
// the link of an image (nui://my_resource/icon.png, https://...).
const ICONS: Record<string, React.ReactNode> = {
  hat: (
    <>
      <path d="M6.5 13C6.5 8 8 5 12 5s5.5 3 5.5 8" />
      <path d="M4 14.4c0-.8.7-1.4 1.5-1.2L12 14.7l6.5-1.5c.8-.2 1.5.4 1.5 1.2 0 .7-.5 1.3-1.2 1.4L12 17l-6.8-1.2C4.5 15.7 4 15.1 4 14.4z" />
    </>
  ),
  glasses: (
    <>
      <circle cx="6.5" cy="13" r="3" />
      <circle cx="17.5" cy="13" r="3" />
      <path d="M9.5 12.5h5" />
      <path d="M3.5 11l1-2h2M20.5 11l-1-2h-2" />
    </>
  ),
  mask: (
    <>
      <path d="M5 6c2-1 4-1.4 7-1.4S17 5 19 6c0 5-2 12-7 12S5 11 5 6z" />
      <circle cx="9.5" cy="10" r="0.5" fill="currentColor" />
      <circle cx="14.5" cy="10" r="0.5" fill="currentColor" />
      <path d="M9.6 13.4c1 .8 3.8 .8 4.8 0" />
    </>
  ),
  ears: (
    <>
      <circle cx="8" cy="6" r="1.2" />
      <path d="M8 7.2c0 3.8-3 4-3 6.8a3 3 0 0 0 6 0" />
      <circle cx="16" cy="6" r="1.2" />
      <path d="M16 7.2c0 3.8 3 4 3 6.8a3 3 0 0 1-6 0" />
    </>
  ),
  neck: (
    <>
      <path d="M9 4c0 3 6 3 6 0" />
      <path d="M9 4c-1 4-1 8 0 12M15 4c1 4 1 8 0 12" />
      <path d="M9.2 16l1.3 4M14.8 16l-1.3 4" />
    </>
  ),
  watch: (
    <>
      <rect x="8" y="8" width="8" height="8" rx="2" />
      <path d="M10 8V5h4v3M10 16v3h4v-3" />
      <path d="M12 11v1.6l1.2 1" />
    </>
  ),
  bracelet: (
    <>
      <ellipse cx="12" cy="12.5" rx="7" ry="4.5" />
      <circle cx="12" cy="7.7" r="1.2" fill="currentColor" />
    </>
  ),
  jacket: (
    <>
      <path d="M8 4 4 6l1 4 2-.6V20h10V9.4l2 .6 1-4-4-2-2 2h-2z" />
      <path d="M12 6v14" />
    </>
  ),
  shirt: <path d="M8.5 4 5 6l1 3 2-.5V20h8V8.5l2 .5 1-3-3.5-2-2 1.6h-3z" />,
  vest: (
    <>
      <path d="M8 4l4 2 4-2 2 3v11a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V7z" />
      <path d="M12 6.2V20" />
    </>
  ),
  decals: (
    <>
      <circle cx="6" cy="12" r="1.7" fill="currentColor" stroke="none" />
      <circle cx="12" cy="12" r="1.7" fill="currentColor" stroke="none" />
      <circle cx="18" cy="12" r="1.7" fill="currentColor" stroke="none" />
    </>
  ),
  bag: (
    <>
      <rect x="6" y="7" width="12" height="13" rx="3" />
      <path d="M9 7V5a3 3 0 0 1 6 0v2" />
      <path d="M9 12h6" />
    </>
  ),
  gloves: (
    <>
      <path d="M7 12V8a1.5 1.5 0 0 1 3 0v3" />
      <path d="M10 11V6a1.5 1.5 0 0 1 3 0v5" />
      <path d="M13 8.5a1.5 1.5 0 0 1 3 0V14a5 5 0 0 1-10 0v-1l-1.1-1.1a1.4 1.4 0 0 1 2-2L7 11" />
    </>
  ),
  pants: (
    <>
      <path d="M7 4h10l-.6 16h-3.6L12 9l-.8 11H7.6z" />
      <path d="M7 4h10" />
    </>
  ),
  shoes: (
    <>
      <path d="M3 15c2 0 3-1 4-2l1-1 1 2c.5 1 2 1.6 4 1.6h7a1 1 0 0 1 1 1v1a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1z" />
      <path d="M9 14l2-1M11 15.6l2-1" />
    </>
  ),
};

const ClothingIcon: React.FC<{ icon: string; className?: string }> = ({ icon, className }) => {
  if (/^(nui|https?):\/\//.test(icon) || /\.(png|webp|svg|jpg)$/.test(icon)) {
    return <img src={icon} className={className} alt="" draggable={false} />;
  }

  return (
    <svg
      className={className}
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.7}
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      {ICONS[icon] || ICONS.shirt}
    </svg>
  );
};

export default ClothingIcon;
