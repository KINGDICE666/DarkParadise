import type { ReactNode } from 'react';

const Tag = (props: { tone: string; children: string }) => (
  <span className={`SensorPost__tag SensorPost__tag--${props.tone}`}>
    {props.children}
  </span>
);

const WedgeExample = () => (
  <svg width={120} height={90} className="SensorHelp__figure">
    <circle cx={10} cy={80} r={4} fill="#e8f7fb" />
    <path
      d="M10 80 L84 12 A100 100 0 0 1 108 34 Z"
      fill="rgba(255,179,71,0.08)"
      stroke="none"
    />
    <path
      d="M52 41 L84 12 A100 100 0 0 1 108 34 L69 56 A45 45 0 0 0 52 41 Z"
      fill="rgba(255,179,71,0.3)"
      stroke="rgba(255,179,71,0.7)"
    />
    <text x={60} y={86} fill="#ffb347" fontSize={9}>
      пеленг 4–9 Гм
    </text>
  </svg>
);

const BlipExample = () => (
  <svg width={120} height={90} className="SensorHelp__figure">
    <circle cx={10} cy={80} r={4} fill="#e8f7fb" />
    <path
      d="M60 30 L66 36 L60 42 L54 36 Z"
      fill="none"
      stroke="#5dffc2"
      strokeWidth={1.5}
    />
    <line
      x1={60}
      y1={36}
      x2={92}
      y2={22}
      stroke="#5dffc2"
      strokeDasharray="3 3"
    />
    <line
      x1={60}
      y1={36}
      x2={34}
      y2={66}
      stroke="#ff5f6d"
      strokeDasharray="2 3"
    />
    <circle cx={34} cy={66} r={2.5} fill="#ff5f6d" />
    <text x={40} y={70} fill="#ff5f6d" fontSize={9}>
      CPA 01:40
    </text>
    <text x={70} y={18} fill="#5dffc2" fontSize={9}>
      курс
    </text>
  </svg>
);

const Section = (props: { title: string; children: ReactNode }) => (
  <div className="SensorHelp__section">
    <h4>{props.title}</h4>
    {props.children}
  </div>
);

export const SensorHelp = () => (
  <div className="SensorHelp">
    <div className="SensorHelp__column">
      <Section title="1. С ЧЕГО НАЧАТЬ">
        <p>
          Включите тумблер <b>ТЕПЛОВОЙ ПАССИВ</b>. Он ничего не излучает и
          слушает чужое тепло (ИК) и радиоизлучение (ЭМ). Если нужны точные
          координаты, включите <b>АКТИВНЫЙ РАДАР</b>.
        </p>
        <p className="SensorHelp__example">
          Пример: вы прячетесь у астероидов. Держите только пассив. Радар
          включайте, когда уже готовы к бою: он вас выдаст.
        </p>
      </Section>
      <Section title="2. ПАССИВ ДАЁТ ПЕЛЕНГ">
        <div className="SensorHelp__row">
          <WedgeExample />
          <p>
            Пассив видит только <b>направление</b> на источник, а дальность даёт
            вилкой. На экране это жёлтый клин. Чем дольше цель в наблюдении, тем
            уже клин и выше качество трека (до 60%).
          </p>
        </div>
        <p className="SensorHelp__example">
          Шаттл на форсаже (ИК ≈ 80) слышен примерно с 7 Гм. Холодный дрейфующий
          корабль без транспондера (ИК 10, ЭМ 0) — меньше чем с 1 Гм.
        </p>
      </Section>
      <Section title="3. АКТИВНЫЙ РАДАР">
        <div className="SensorHelp__row">
          <BlipExample />
          <p>
            Луч обходит круг и даёт точную позицию, скорость и курс. Отметка
            ярко вспыхивает, когда луч проходит по ней, и гаснет до следующего
            оборота. Дальность выше у тяжёлых целей.
          </p>
        </div>
        <p>
          <b>РЕЖИМ ЛУЧА · СЕКТОР</b> сужает луч до конуса ±30° и бьёт в 1.7 раза
          дальше. Куда смотрит конус, задаёт ручка <b>АЗИМУТ СЕКТОРА</b>: колесо
          мыши ±5°, с Shift ±1°. Ручку можно тянуть мышью, а можно кликнуть по
          экрану.
        </p>
        <p className="SensorHelp__warn">
          Пока радар включён, ваше ЭМ высокое: все, у кого есть пассив, видят
          вас издалека.
        </p>
      </Section>
    </div>
    <div className="SensorHelp__column">
      <Section title="4. ИСТОЧНИКИ ТРЕКОВ">
        <div className="SensorHelp__tags">
          <span>
            <Tag tone="act">АКТ</Tag> точная отметка радара
          </span>
          <span>
            <Tag tone="act">БЛИЖ</Tag> цель в зоне ближнего скана
          </span>
          <span>
            <Tag tone="pas">ПАС</Tag> только пеленг пассива
          </span>
          <span>
            <Tag tone="iff">IFF</Tag> опознан по транспондеру
          </span>
          <span>
            <Tag tone="iff">КАРТА</Tag> объект с навигационной карты
          </span>
          <span>
            <Tag tone="sos">SOS</Tag> сигнал бедствия
          </span>
          <span>
            <Tag tone="lost">ПОТЕРЯН</Tag> пропал, последние данные
          </span>
        </div>
      </Section>
      <Section title="5. СБЛИЖЕНИЕ И CPA">
        <p>
          <b>СБЛИЖ.</b> показывает, с какой скоростью цель приближается. Минус
          значит, что она идёт к нам. <b>CPA</b> — точка наибольшего сближения.
        </p>
        <p className="SensorHelp__example">
          «0.4 · 01:40» значит: если никто не свернёт, через 1 минуту 40 секунд
          цель пройдёт в 0.4 Гм от нас.
        </p>
      </Section>
      <Section title="6. ЗАХВАТ И СКАН">
        <p>
          <b>ЗАХВАТ ЦЕЛИ</b> держит трек в луче радара: качество быстро растёт
          до 100%. Цель при этом получает предупреждение «нас ведёт радар». Если
          цель уйдёт из луча, захват сорвётся.
        </p>
        <p>
          <b>ДЕТАЛЬНЫЙ СКАН</b> работает в зоне ближнего массива (2 Гм). Он
          длится 10 секунд и раскрывает массу, экипаж, двигатели и силуэт
          корпуса.
        </p>
      </Section>
      <Section title="7. ВОДОПАД">
        <p>
          По горизонтали пеленг 0–360°, сверху самые свежие данные. Прямая
          вертикальная полоса — источник стоит на месте. Наклонная — цель
          смещается по пеленгу. Жёлтые полосы — то, что слышит пассив.
        </p>
      </Section>
      <Section title="8. ЗАМЕТНОСТЬ И ЭМИ">
        <p>
          <b>НАША ЗАМЕТНОСТЬ</b> складывается из ИК (работа двигателей), ЭМ
          (транспондер, радар, щиты, SOS) и массы. «ТИШИНА» значит, что нас
          почти не слышно.
        </p>
        <p className="SensorHelp__warn">
          ЭМИ по ближнему массиву сбивает пассив на 1 минуту: пеленги скачут,
          появляются ложные цели «T-??».
        </p>
      </Section>
    </div>
  </div>
);
