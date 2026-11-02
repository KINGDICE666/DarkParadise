export const CAN_MAKE = 'Can Make';

export const CATEGORY_ICONS = {
  [CAN_MAKE]: 'hammer',
  Weaponry: 'gun',
  Robots: 'robot',
  Misc: 'shapes',
  Tribal: 'campground',
  Foods: 'utensils',
  Decorations: 'gifts',
  Clothing: 'shirt',
} as const;

export const CATEGORY_NAMES = {
  [CAN_MAKE]: 'Можно сделать',
  Weaponry: 'Вооружение',
  Weapons: 'Оружие',
  Ammunition: 'Боеприпасы',
  Robots: 'Роботы',
  Misc: 'Разное',
  Tribal: 'Племенное',
  'Tribal Armor': 'Броня',
  'Tribal Weaponry': 'Оружие',
  'Tribal Misc': 'Разное',
  Foods: 'Еда',
  Cakes: 'Торты',
  Sushi: 'Суши',
  Sandwiches: 'Сэндвичи',
  'Misc. Food': 'Разное',
  Decorations: 'Украшения',
  Holiday: 'Праздничное',
  'Large Decorations': 'Крупные украшения',
  Clothing: 'Одежда',
} as const;

export const TOOL_NAMES = {
  crowbar: 'лом',
  multitool: 'мультитул',
  screwdriver: 'отвёртка',
  wirecutter: 'кусачки',
  wrench: 'гаечный ключ',
  welder: 'сварочный аппарат',
  analyzer: 'анализатор',
  mining: 'кирка',
  retractor: 'ретрактор',
  hemostat: 'гемостат',
  cautery: 'прижигатель',
  drill: 'хирургическая дрель',
  scalpel: 'скальпель',
  saw: 'пила',
  bonesetter: 'костоправ',
} as const;
