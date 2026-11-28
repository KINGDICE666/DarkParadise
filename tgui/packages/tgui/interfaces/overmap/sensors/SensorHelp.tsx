import type { ReactNode } from 'react';

const Section = (props: { title: string; children: ReactNode }) => (
  <div className="SensorHelp__section">
    <h4>{props.title}</h4>
    {props.children}
  </div>
);

const ScreenSymbol = (props: {
  path: string;
  dash?: string;
  label: string;
}) => (
  <div className="SensorHelp__symbol">
    <svg width={34} height={34} viewBox="0 0 34 34" aria-hidden="true">
      <path
        d={props.path}
        fill="none"
        stroke="#b8ffc9"
        strokeWidth={1.5}
        strokeDasharray={props.dash}
      />
    </svg>
    <span>{props.label}</span>
  </div>
);

export const SensorHelp = () => (
  <div className="SensorHelp">
    <div className="SensorHelp__column">
      <Section title="ИСТОЧНИКИ">
        <p>
          ТЕПЛ. ПАССИВ — ближний массив. Ничего не излучает, слышит тепло (ИК) и
          радиоизлучение (ЭМ). Даёт только пеленг: пунктирную линию от корабля.
        </p>
        <p>
          РАДАР — дальний массив. Точная дальность, курс и скорость. Пока радар
          излучает, наше ЭМ высокое и нас видно издалека.
        </p>
        <p>
          РЕЖИМ ЛУЧА: КРУГ — обзор во все стороны; СЕКТОР — конус ±30° с
          дальностью ×1.7. Азимут сектора: ◀ ▶ по 5°, с Shift по 1°, колесо мыши
          над полем или клик по экрану.
        </p>
      </Section>
      <Section title="РЕГУЛИРОВКА">
        <p>
          УСИЛЕНИЕ — дальность пассива (от ×0.5 до ×1.5). Высокое усиление
          поднимает шум на водопаде.
        </p>
        <p>
          ПОДАВЛ. ПОЛЯ — гасит эхо астероидных и других полей. Слишком сильное
          подавление скрывает слабые поля целиком.
        </p>
        <p>ЯРКОСТЬ ЭХА — только яркость засветок на экране.</p>
      </Section>
      <Section title="ВОДОПАД">
        <p>
          По горизонтали пеленг, сверху свежие строки, слева время. Ровная
          вертикальная полоса — источник на месте, наклонная — смещается по
          пеленгу. Провал в шуме — на этом пеленге что-то глушит фон.
        </p>
      </Section>
    </div>
    <div className="SensorHelp__column">
      <Section title="ЗНАКИ НА ЭКРАНЕ">
        <div className="SensorHelp__symbols">
          <ScreenSymbol
            path="M10 17 a7 7 0 1 0 14 0 a7 7 0 1 0 -14 0 M22 12 L31 3"
            label="ЦЕЛЬ РАДАРА И ВЕКТОР"
          />
          <ScreenSymbol path="M17 8 L25 24 L9 24 Z" label="СВОЙ ПО IFF" />
          <ScreenSymbol path="M10 10 h14 v14 h-14 Z" label="СИГНАЛ БЕДСТВИЯ" />
          <ScreenSymbol
            path="M10 17 a7 7 0 1 0 14 0 a7 7 0 1 0 -14 0"
            dash="3 3"
            label="НЕУСТОЙЧИВЫЙ / ПОТЕРЯННЫЙ"
          />
          <ScreenSymbol
            path="M3 9 v-6 h6 M31 9 v-6 h-6 M3 25 v6 h6 M31 25 v6 h-6"
            label="ВЫБОР / ЗАХВАТ"
          />
          <ScreenSymbol path="M11 11 L23 23 M23 11 L11 23" label="ТОЧКА CPA" />
          <ScreenSymbol path="M2 32 L32 2" dash="8 6" label="ПЕЛЕНГ ПАССИВА" />
          <ScreenSymbol
            path="M3 17 a14 14 0 1 0 28 0 a14 14 0 1 0 -28 0"
            dash="4 3"
            label="ДАЛЬН КР"
          />
        </div>
      </Section>
      <Section title="ФУНКЦИОНАЛЬНЫЕ КЛАВИШИ">
        <p>
          СЛЕДЫ — точки прошлого положения целей. IFF — свои треугольником. ПЕЛ
          ЛИН и ДАЛЬН КР — линия пеленга и круг дальности по выбранной цели,
          значения в правом верхнем углу. CPA — точка наибольшего сближения.
          ПОДПИСИ — имена опознанных целей.
        </p>
      </Section>
      <Section title="ЗАХВАТ И СКАН">
        <p>
          ЗАХВАТ держит цель в луче: качество трека быстро растёт, цель получает
          «ОБЛУЧЕНИЕ». Если отражение неустойчиво, захват срывается. СКАН
          работает до 2 ГМ и раскрывает массу, экипаж, двигатели и силуэт.
        </p>
      </Section>
      <Section title="СТАТУС">
        <p>
          ОБЛУЧЕНИЕ — нас видит или ведёт чужой радар. ЭМИ СБОЙ — пассив минуту
          даёт ложные пеленги. ПОТЕРЯ ЦЕЛИ — трек сорвался или отражение
          нестабильно.
        </p>
      </Section>
    </div>
  </div>
);
