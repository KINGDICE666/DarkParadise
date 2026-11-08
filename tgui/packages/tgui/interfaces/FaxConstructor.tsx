import {
  type DragEvent,
  type KeyboardEvent,
  type MouseEvent,
  type ReactNode,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from 'react';
import { Dropdown, Icon, Input } from 'tgui-core/components';
import { listenForKeyEvents } from 'tgui-core/hotkeys';
import { KEY_ESCAPE } from 'tgui-core/keycodes';
import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type TextStyle = {
  font: string;
  size: number;
  color: string;
  bold: boolean | number;
  italic: boolean | number;
  underline: boolean | number;
  strike: boolean | number;
};

type Row = {
  label: string;
  hint: string;
  value: string;
};

type FaxSection = TextStyle & {
  id: number;
  kind: 'fields' | 'text';
  title: string;
  title_align: string;
  text_align: string;
  text: string;
  divider: boolean | number;
  fillable: boolean | number;
  rows: Row[];
};

type Draft = TextStyle & {
  logo: string;
  align: string;
  text_align: string;
  purpose: string;
  form_id: string;
  title: string;
  organization: string;
  category: string;
  notice: string;
  sender_name: string;
  stamp_text: string;
  footer_text: string;
  stamps: string[];
  sections: FaxSection[];
};

type Option = {
  value: string;
  label: string;
};

type BuiltinPreset = {
  id: string;
  name: string;
  category: string;
  preview_html: string;
};

type CustomPreset = {
  name: string;
  author: string;
  preview_html: string | null;
};

type FaxConstructorData = {
  draft: Draft;
  preview_html: string;
  field_count: number;
  custom_presets: CustomPreset[];
  destinations: string[];
  destination: string | null;
  notify_sender: boolean | number;
  faxtype: string;
  reply_department: string | null;
  reply_sender: string | null;
  reply_lost: boolean | number;
  sending: boolean | number;
  can_undo: boolean | number;
  can_redo: boolean | number;
  custom_logo: string | null;
  fonts: string[];
  purposes: Option[];
  stamp_types: Option[];
  builtin_presets: BuiltinPreset[];
  max_sections: number;
  max_rows: number;
  max_stamps: number;
  max_line_len: number;
  max_text_len: number;
  max_fields: number;
  min_font_size: number;
  max_font_size: number;
};

type Selection = 'settings' | 'stamps' | number;

type DropMark = {
  index: number;
  after: boolean;
};

const LOGO_OPTIONS: Option[] = [
  { value: 'nt', label: 'NT' },
  { value: 'syndicate', label: 'Синдикат' },
  { value: 'ussp', label: 'СССП' },
  { value: 'solgov', label: 'ТСФ' },
  { value: 'custom', label: 'Свой PNG' },
  { value: 'none', label: 'Без логотипа' },
];

const LOGO_FILES: Record<string, string> = {
  nt: 'ntlogo.png',
  syndicate: 'syndielogo.png',
  ussp: 'ussplogo.png',
  solgov: 'solgovlogo.png',
};

const PALETTE = [
  '#000000',
  '#ffffff',
  '#1f6feb',
  '#2ea043',
  '#da3633',
  '#d4a72c',
];

const ALIGN_ICONS: Record<string, string> = {
  left: 'align-left',
  center: 'align-center',
  right: 'align-right',
  justify: 'align-justify',
};

const ALIGN_TITLES: Record<string, string> = {
  left: 'По левому краю',
  center: 'По центру',
  right: 'По правому краю',
  justify: 'По ширине',
};

const BLOCK_ALIGNS = ['left', 'center', 'right'];
const TEXT_ALIGNS = ['left', 'center', 'right', 'justify'];

const DECORATIONS: { key: keyof TextStyle; icon: string; title: string }[] = [
  { key: 'bold', icon: 'bold', title: 'Жирный' },
  { key: 'italic', icon: 'italic', title: 'Курсив' },
  { key: 'underline', icon: 'underline', title: 'Подчёркнутый' },
  { key: 'strike', icon: 'strikethrough', title: 'Зачёркнутый' },
];

const ADD_OPTIONS = [
  {
    kind: 'fields',
    icon: 'list',
    label: 'Поля',
    hint: 'Подписи слева, поля для заполнения справа',
  },
  {
    kind: 'text',
    icon: 'align-left',
    label: 'Текст',
    hint: 'Свободный текст с разметкой ручки',
  },
  {
    kind: 'applicant',
    icon: 'id-card',
    label: 'Данные заявителя',
    hint: 'Имя, номер аккаунта и должность',
  },
  {
    kind: 'signatures',
    icon: 'signature',
    label: 'Подписи',
    hint: 'Время и строки для подписей',
  },
];

const PENCODE_TOOLS: {
  label: ReactNode;
  title: string;
  open: string;
  close?: string;
}[] = [
  { label: <b>B</b>, title: 'Жирный', open: '[b]', close: '[/b]' },
  { label: <i>I</i>, title: 'Курсив', open: '[i]', close: '[/i]' },
  { label: <u>U</u>, title: 'Подчёркнутый', open: '[u]', close: '[/u]' },
  { label: 'A+', title: 'Крупный текст', open: '[large]', close: '[/large]' },
  { label: 'A-', title: 'Мелкий текст', open: '[small]', close: '[/small]' },
  {
    label: <Icon name="align-center" />,
    title: 'По центру',
    open: '[center]',
    close: '[/center]',
  },
  { label: 'H1', title: 'Заголовок', open: '[h1]', close: '[/h1]' },
  { label: <Icon name="minus" />, title: 'Линия', open: '[hr]' },
  {
    label: <Icon name="list-ul" />,
    title: 'Список',
    open: '[list]\n[*]',
    close: '\n[/list]',
  },
  {
    label: <Icon name="i-cursor" />,
    title: 'Поле для заполнения игроком',
    open: '[field]',
  },
  { label: <Icon name="clock" />, title: 'Текущее время', open: '[time]' },
  {
    label: <Icon name="calendar-days" />,
    title: 'Текущая дата',
    open: '[date]',
  },
  {
    label: <Icon name="satellite" />,
    title: 'Название станции',
    open: '[station]',
  },
];

const ZOOM_STEPS = [0.5, 0.65, 0.8, 1, 1.15, 1.3, 1.5];
const DEFAULT_ZOOM_STEP = 3;
const TEXT_COMMIT_DELAY_MS = 250;
const SAVE_AFTER_TYPING_DELAY_MS = 300;
const HEX_COLOR = /^#[0-9a-fA-F]{6}$/;
const TRANSPARENT_PIXEL =
  'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==';
const HANDLE_POSITIONS = [
  { top: -4, left: -4 },
  { top: -4, left: 'calc(50% - 4px)' },
  { top: -4, right: -4 },
  { top: 'calc(50% - 4px)', left: -4 },
  { top: 'calc(50% - 4px)', right: -4 },
  { bottom: -4, left: -4 },
  { bottom: -4, left: 'calc(50% - 4px)' },
  { bottom: -4, right: -4 },
];

const renderPreviewHtml = (html: string, customLogo: string | null) =>
  html
    .replace(
      /src='([\w-]+\.png)'/g,
      (_, name: string) => `src='${resolveAsset(name)}'`,
    )
    .replace(
      "src='fax_custom_logo'",
      `src='${customLogo ? `data:image/png;base64,${customLogo}` : TRANSPARENT_PIXEL}'`,
    );

const dropMarkFor = (
  event: DragEvent<HTMLElement>,
  index: number,
): DropMark => {
  const box = event.currentTarget.getBoundingClientRect();
  return { index, after: event.clientY > box.top + box.height / 2 };
};

const dropTargetIndex = (from: number, mark: DropMark) => {
  const insertAt = mark.after ? mark.index + 1 : mark.index;
  return insertAt > from ? insertAt - 1 : insertAt;
};

type IconButtonProps = {
  icon: string;
  title: string;
  disabled?: boolean;
  danger?: boolean;
  onClick: () => void;
};

const IconButton = (props: IconButtonProps) => {
  const { icon, title, disabled, danger, onClick } = props;
  return (
    <button
      type="button"
      className={`FaxConstructor__iconButton${danger ? ' FaxConstructor__iconButton--danger' : ''}`}
      title={title}
      disabled={disabled}
      onClick={(event) => {
        event.stopPropagation();
        onClick();
      }}
    >
      <Icon name={icon} />
    </button>
  );
};

type ConfirmIconButtonProps = {
  icon: string;
  title: string;
  onConfirm: () => void;
};

const ConfirmIconButton = (props: ConfirmIconButtonProps) => {
  const { icon, title, onConfirm } = props;
  const [armed, setArmed] = useState(false);
  return (
    <button
      type="button"
      className={`FaxConstructor__iconButton FaxConstructor__iconButton--danger${armed ? ' FaxConstructor__iconButton--armed' : ''}`}
      title={armed ? 'Нажмите ещё раз для подтверждения' : title}
      onBlur={() => setArmed(false)}
      onMouseLeave={() => setArmed(false)}
      onClick={(event) => {
        event.stopPropagation();
        if (armed) {
          onConfirm();
        }
        setArmed(!armed);
      }}
    >
      <Icon name={armed ? 'check' : icon} />
    </button>
  );
};

type FieldProps = {
  label: string;
  aside?: ReactNode;
  children: ReactNode;
};

const Field = ({ label, aside, children }: FieldProps) => (
  <div className="FaxConstructor__field">
    <div className="FaxConstructor__fieldLabel">
      <span>{label}</span>
      {aside}
    </div>
    {children}
  </div>
);

type TextFieldProps = {
  label: string;
  value: string;
  placeholder?: string;
  onChange: (value: string) => void;
};

const TextField = ({ label, value, placeholder, onChange }: TextFieldProps) => {
  const { data } = useBackend<FaxConstructorData>();
  return (
    <Field label={label}>
      <Input
        fluid
        expensive
        maxLength={data.max_line_len}
        placeholder={placeholder}
        value={value}
        onChange={onChange}
      />
    </Field>
  );
};

type SegmentsProps = {
  aligns: string[];
  value: string;
  onChange: (value: string) => void;
};

const Segments = ({ aligns, value, onChange }: SegmentsProps) => (
  <div className="FaxConstructor__segments">
    {aligns.map((align) => (
      <button
        key={align}
        type="button"
        title={ALIGN_TITLES[align]}
        className={`FaxConstructor__segment${value === align ? ' FaxConstructor__segment--active' : ''}`}
        onClick={() => onChange(align)}
      >
        <Icon name={ALIGN_ICONS[align]} />
      </button>
    ))}
  </div>
);

type CheckProps = {
  checked: boolean;
  title?: string;
  children: ReactNode;
  onChange: () => void;
};

const Check = ({ checked, title, children, onChange }: CheckProps) => (
  <button
    type="button"
    title={title}
    className={`FaxConstructor__check${checked ? ' FaxConstructor__check--checked' : ''}`}
    onClick={onChange}
  >
    <span className="FaxConstructor__checkMark">
      {checked && <Icon name="check" />}
    </span>
    {children}
  </button>
);

type SizeStepperProps = {
  value: number;
  min: number;
  max: number;
  onChange: (value: number) => void;
};

const SizeStepper = ({ value, min, max, onChange }: SizeStepperProps) => {
  const [text, setText] = useState(String(value));
  useEffect(() => setText(String(value)), [value]);
  const commit = (next: number) => {
    if (!Number.isFinite(next)) {
      setText(String(value));
      return;
    }
    const clamped = Math.min(max, Math.max(min, Math.round(next)));
    setText(String(clamped));
    if (clamped !== value) {
      onChange(clamped);
    }
  };
  return (
    <div className="FaxConstructor__stepper">
      <input
        aria-label="Размер"
        value={text}
        onChange={(event) => setText(event.currentTarget.value)}
        onBlur={() => commit(Number(text))}
        onKeyDown={(event) => {
          if (event.key === 'Enter') {
            commit(Number(text));
          }
        }}
      />
      <div className="FaxConstructor__stepperButtons">
        <button
          type="button"
          title="Больше"
          onClick={() => commit(value + 1)}
        >
          <Icon name="chevron-up" />
        </button>
        <button
          type="button"
          title="Меньше"
          onClick={() => commit(value - 1)}
        >
          <Icon name="chevron-down" />
        </button>
      </div>
    </div>
  );
};

type ColorInputProps = {
  value: string;
  onChange: (value: string) => void;
};

const ColorInput = ({ value, onChange }: ColorInputProps) => {
  const [text, setText] = useState(value);
  useEffect(() => setText(value), [value]);
  return (
    <input
      aria-label="Свой цвет"
      className="Input Input--monospace"
      maxLength={7}
      value={text}
      onChange={(event) => {
        const next = event.currentTarget.value;
        setText(next);
        if (HEX_COLOR.test(next)) {
          onChange(next.toLowerCase());
        }
      }}
      onBlur={() => setText(value)}
    />
  );
};

type StyleEditorProps = {
  style: TextStyle;
  sizeLabel: string;
  onChange: (key: string, value: unknown) => void;
};

const StyleEditor = ({ style, sizeLabel, onChange }: StyleEditorProps) => {
  const { data } = useBackend<FaxConstructorData>();
  const { fonts, min_font_size, max_font_size } = data;
  const [customColor, setCustomColor] = useState(false);
  return (
    <>
      <div className="FaxConstructor__fieldRow">
        <div>
          <div className="FaxConstructor__fieldLabel">Шрифт</div>
          <Dropdown
            width="100%"
            options={fonts.map((font) => ({
              value: font,
              displayText: <span style={{ fontFamily: font }}>{font}</span>,
            }))}
            selected={style.font}
            displayText={
              <span style={{ fontFamily: style.font }}>{style.font}</span>
            }
            onSelected={(font) => onChange('font', font)}
          />
        </div>
        <div>
          <div className="FaxConstructor__fieldLabel">{sizeLabel}</div>
          <SizeStepper
            value={style.size}
            min={min_font_size}
            max={max_font_size}
            onChange={(size) => onChange('size', size)}
          />
        </div>
      </div>
      <Field label="Текстовое оформление">
        <div className="FaxConstructor__styleRow">
          <div className="FaxConstructor__decorations">
            {DECORATIONS.map(({ key, icon, title }) => (
              <button
                key={key}
                type="button"
                title={title}
                className={
                  style[key] ? 'FaxConstructor__decoration--active' : undefined
                }
                onClick={() => onChange(key, !style[key])}
              >
                <Icon name={icon} />
              </button>
            ))}
          </div>
          <div className="FaxConstructor__styleSeparator" />
          {PALETTE.map((color) => (
            <button
              key={color}
              type="button"
              title={color}
              aria-label={color}
              className={`FaxConstructor__swatch${style.color === color ? ' FaxConstructor__swatch--selected' : ''}`}
              style={{ backgroundColor: color }}
              onClick={() => onChange('color', color)}
            />
          ))}
          <IconButton
            icon="palette"
            title="Свой цвет"
            onClick={() => setCustomColor(!customColor)}
          />
        </div>
        {customColor && (
          <div className="FaxConstructor__customColor">
            <ColorInput
              value={style.color}
              onChange={(color) => onChange('color', color)}
            />
          </div>
        )}
      </Field>
    </>
  );
};

type PencodeEditorProps = {
  label: string;
  value: string;
  maxLength: number;
  height?: number;
  onChange: (value: string) => void;
};

const PencodeEditor = (props: PencodeEditorProps) => {
  const { label, value, maxLength, height, onChange } = props;
  const [text, setText] = useState(value);
  const textareaRef = useRef<HTMLTextAreaElement>(null);
  const pendingTimer = useRef<ReturnType<typeof setTimeout>>(undefined);
  const pendingText = useRef<string | null>(null);
  const latestOnChange = useRef(onChange);
  latestOnChange.current = onChange;

  const flush = () => {
    clearTimeout(pendingTimer.current);
    if (pendingText.current !== null) {
      latestOnChange.current(pendingText.current);
      pendingText.current = null;
    }
  };

  useEffect(() => flush, []);

  useEffect(() => {
    if (document.activeElement !== textareaRef.current) {
      setText(value);
    }
  }, [value]);

  const update = (next: string) => {
    setText(next);
    pendingText.current = next;
    clearTimeout(pendingTimer.current);
    pendingTimer.current = setTimeout(flush, TEXT_COMMIT_DELAY_MS);
  };

  const insertTag = (open: string, close = '') => {
    const editor = textareaRef.current;
    if (!editor) {
      return;
    }
    const { selectionStart: start, selectionEnd: end } = editor;
    const next =
      text.slice(0, start) +
      open +
      text.slice(start, end) +
      close +
      text.slice(end);
    if (next.length > maxLength) {
      return;
    }
    update(next);
    requestAnimationFrame(() => {
      editor.focus();
      editor.setSelectionRange(start + open.length, end + open.length);
    });
  };

  return (
    <Field
      label={label}
      aside={
        <span className="FaxConstructor__counter">
          {text.length}/{maxLength}
        </span>
      }
    >
      <div className="FaxConstructor__editorTools">
        {PENCODE_TOOLS.map((tool) => (
          <button
            key={tool.title}
            type="button"
            title={tool.title}
            onMouseDown={(event) => event.preventDefault()}
            onClick={() => insertTag(tool.open, tool.close)}
          >
            {tool.label}
          </button>
        ))}
      </div>
      <textarea
        ref={textareaRef}
        aria-label={label}
        className="FaxConstructor__editor"
        style={height ? { height } : undefined}
        maxLength={maxLength}
        value={text}
        onChange={(event) => update(event.currentTarget.value)}
        onBlur={flush}
      />
    </Field>
  );
};

const LogoGroup = () => {
  const { act, data } = useBackend<FaxConstructorData>();
  const { draft, custom_logo } = data;
  const logoFile = LOGO_FILES[draft.logo];
  const logoLabel = LOGO_OPTIONS.find((logo) => logo.value === draft.logo);
  let logoSource: string | null = null;
  if (logoFile) {
    logoSource = resolveAsset(logoFile);
  } else if (draft.logo === 'custom' && custom_logo) {
    logoSource = `data:image/png;base64,${custom_logo}`;
  }
  return (
    <div className="FaxConstructor__group">
      <div className="FaxConstructor__groupTitle">
        Логотип {logoLabel?.label}
      </div>
      <div className="FaxConstructor__logoRow">
        <div className="FaxConstructor__logoFrame">
          {logoSource ? (
            <img src={logoSource} alt="Логотип" />
          ) : (
            <span>
              {draft.logo === 'custom' ? 'Загрузите PNG' : 'Без логотипа'}
            </span>
          )}
        </div>
        <div>
          <button
            type="button"
            className="FaxConstructor__upload"
            onClick={() => act('upload_logo')}
          >
            <Icon name="cloud-arrow-up" />
            Загрузить PNG
          </button>
          <div className="FaxConstructor__radios">
            {LOGO_OPTIONS.map((logo) => (
              <button
                key={logo.value}
                type="button"
                className={`FaxConstructor__radio${draft.logo === logo.value ? ' FaxConstructor__radio--checked' : ''}`}
                onClick={() =>
                  act('set_draft', { key: 'logo', value: logo.value })
                }
              >
                <span className="FaxConstructor__radioMark" />
                {logo.label}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

const SettingsPanel = () => {
  const { act, data } = useBackend<FaxConstructorData>();
  const { draft, purposes, max_text_len } = data;
  const setDraft = (key: string, value: unknown) =>
    act('set_draft', { key, value });
  const purposeLabel = purposes.find(
    (purpose) => purpose.value === draft.purpose,
  )?.label;
  return (
    <>
      <LogoGroup />
      <div className="FaxConstructor__group">
        <Field label="Назначение бланка">
          <Dropdown
            width="100%"
            options={purposes.map((purpose) => ({
              displayText: purpose.label,
              value: purpose.value,
            }))}
            selected={draft.purpose}
            displayText={purposeLabel}
            onSelected={(purpose) => setDraft('purpose', purpose)}
          />
        </Field>
        <TextField
          label="Заголовок"
          value={draft.title}
          onChange={(value) => setDraft('title', value)}
        />
        <TextField
          label="Организация"
          value={draft.organization}
          onChange={(value) => setDraft('organization', value)}
        />
        <Field label="Выравнивание логотипа">
          <Segments
            aligns={BLOCK_ALIGNS}
            value={draft.align}
            onChange={(align) => setDraft('align', align)}
          />
        </Field>
        <StyleEditor
          style={draft}
          sizeLabel="Размер"
          onChange={setDraft}
        />
        <Field label="Выравнивание текста">
          <Segments
            aligns={TEXT_ALIGNS}
            value={draft.text_align}
            onChange={(align) => setDraft('text_align', align)}
          />
        </Field>
      </div>
      <details className="FaxConstructor__details">
        <summary>Дополнительно</summary>
        <TextField
          label="Номер формы"
          value={draft.form_id}
          placeholder="Например, Форма NT-CC-DRV"
          onChange={(value) => setDraft('form_id', value)}
        />
        <TextField
          label="Категория"
          value={draft.category}
          onChange={(value) => setDraft('category', value)}
        />
        <TextField
          label="Примечание под шапкой"
          value={draft.notice}
          onChange={(value) => setDraft('notice', value)}
        />
        <TextField
          label="Префикс имени документа"
          value={draft.sender_name}
          placeholder="Например, Центральное командование"
          onChange={(value) => setDraft('sender_name', value)}
        />
      </details>
      {draft.purpose === 'custom' && (
        <PencodeEditor
          label="Нижний колонтитул"
          height={100}
          maxLength={max_text_len}
          value={draft.footer_text}
          onChange={(value) => setDraft('footer_text', value)}
        />
      )}
    </>
  );
};

const StampsPanel = () => {
  const { act, data } = useBackend<FaxConstructorData>();
  const { draft, stamp_types, max_stamps } = data;
  return (
    <>
      <div className="FaxConstructor__group">
        <div className="FaxConstructor__groupTitle">
          Штампы
          <span className="FaxConstructor__counter">
            {draft.stamps.length}/{max_stamps}
          </span>
        </div>
        <div className="FaxConstructor__stamps">
          {stamp_types.map((stamp) => (
            <button
              key={stamp.value}
              type="button"
              className={`FaxConstructor__stamp${draft.stamps.includes(stamp.value) ? ' FaxConstructor__stamp--selected' : ''}`}
              disabled={
                !draft.stamps.includes(stamp.value) &&
                draft.stamps.length >= max_stamps
              }
              onClick={() => act('toggle_stamp', { stamp: stamp.value })}
            >
              <img
                src={resolveAsset(`large_stamp-${stamp.value}.png`)}
                alt=""
              />
              {stamp.label}
            </button>
          ))}
        </div>
      </div>
      <TextField
        label="Текстовый штамп"
        value={draft.stamp_text}
        placeholder="Например, Копия верна"
        onChange={(value) => act('set_draft', { key: 'stamp_text', value })}
      />
    </>
  );
};

type RowCardProps = {
  section: FaxSection;
  row: Row;
  index: number;
  dropMark: DropMark | null;
  onDragStart: (index: number) => void;
  onDragEnd: () => void;
  onDragOverRow: (mark: DropMark) => void;
  onDropRow: () => void;
};

const RowCard = (props: RowCardProps) => {
  const { section, row, index, dropMark } = props;
  const { onDragStart, onDragEnd, onDragOverRow, onDropRow } = props;
  const { act, data } = useBackend<FaxConstructorData>();
  const { id } = section;
  const position = index + 1;
  const setRow = (key: string, value: string) =>
    act('set_row', { id, index: position, key, value });
  let dropClass = '';
  if (dropMark?.index === index) {
    dropClass = dropMark.after
      ? ' FaxConstructor__rowCard--dropAfter'
      : ' FaxConstructor__rowCard--dropBefore';
  }
  return (
    <div
      className={`FaxConstructor__rowCard${dropClass}`}
      onDragOver={(event) => {
        event.preventDefault();
        onDragOverRow(dropMarkFor(event, index));
      }}
      onDrop={(event) => {
        event.preventDefault();
        onDropRow();
      }}
    >
      <div className="FaxConstructor__rowHead">
        <span
          className="FaxConstructor__rowGrip"
          draggable
          title="Перетащите, чтобы изменить порядок"
          onDragStart={() => onDragStart(index)}
          onDragEnd={onDragEnd}
        >
          <Icon name="grip-vertical" />
        </span>
        <Input
          fluid
          expensive
          placeholder="Подпись поля"
          maxLength={data.max_line_len}
          value={row.label}
          onChange={(value) => setRow('label', value)}
        />
        <IconButton
          icon="arrow-up"
          title="Выше"
          disabled={index === 0}
          onClick={() =>
            act('reorder_row', { id, index: position, target: position - 1 })
          }
        />
        <IconButton
          icon="arrow-down"
          title="Ниже"
          disabled={index === section.rows.length - 1}
          onClick={() =>
            act('reorder_row', { id, index: position, target: position + 1 })
          }
        />
        <IconButton
          icon="xmark"
          title="Удалить поле"
          danger
          onClick={() => act('remove_row', { id, index: position })}
        />
      </div>
      <div className="FaxConstructor__rowBody">
        <Input
          fluid
          expensive
          placeholder="Подсказка мелким шрифтом"
          maxLength={data.max_line_len}
          value={row.hint}
          onChange={(value) => setRow('hint', value)}
        />
        <Input
          fluid
          expensive
          placeholder="Пусто — заполнит игрок"
          maxLength={data.max_line_len}
          value={row.value}
          onChange={(value) => setRow('value', value)}
        />
      </div>
    </div>
  );
};

type SectionPanelProps = {
  section: FaxSection;
};

const SectionPanel = ({ section }: SectionPanelProps) => {
  const { act, data } = useBackend<FaxConstructorData>();
  const { max_rows, max_text_len } = data;
  const { id } = section;
  const [draggedRow, setDraggedRow] = useState<number | null>(null);
  const [rowMark, setRowMark] = useState<DropMark | null>(null);
  const setSection = (key: string, value: unknown) =>
    act('set_section', { id, key, value });
  const finishRowDrag = () => {
    setDraggedRow(null);
    setRowMark(null);
  };
  const dropRow = () => {
    if (draggedRow !== null && rowMark) {
      act('reorder_row', {
        id,
        index: draggedRow + 1,
        target: dropTargetIndex(draggedRow, rowMark) + 1,
      });
    }
    finishRowDrag();
  };
  return (
    <>
      <div className="FaxConstructor__group">
        <div className="FaxConstructor__groupTitle">
          {section.kind === 'fields' ? 'Блок с полями' : 'Текстовый блок'}
        </div>
        <TextField
          label="Заголовок блока"
          value={section.title}
          placeholder="Без заголовка"
          onChange={(value) => setSection('title', value)}
        />
        <Field label="Выравнивание заголовка">
          <Segments
            aligns={TEXT_ALIGNS}
            value={section.title_align}
            onChange={(align) => setSection('title_align', align)}
          />
        </Field>
        <StyleEditor
          style={section}
          sizeLabel="Размер"
          onChange={setSection}
        />
        <Field label="Выравнивание текста">
          <Segments
            aligns={TEXT_ALIGNS}
            value={section.text_align}
            onChange={(align) => setSection('text_align', align)}
          />
        </Field>
        <Check
          checked={!!section.divider}
          onChange={() => setSection('divider', !section.divider)}
        >
          Линия над блоком
        </Check>
        <button
          type="button"
          className="FaxConstructor__ghostButton"
          title="Скопировать шрифт, размер, цвет и оформление на все блоки"
          onClick={() => act('style_all_sections', { id })}
        >
          <Icon name="paint-roller" />
          Применить оформление ко всем блокам
        </button>
      </div>
      {section.kind === 'text' ? (
        <div className="FaxConstructor__group">
          <PencodeEditor
            label="Содержимое"
            maxLength={max_text_len}
            value={section.text}
            onChange={(value) => setSection('text', value)}
          />
          <Check
            checked={!!section.fillable}
            title="В конце блока появится поле, которое игрок заполнит ручкой"
            onChange={() => setSection('fillable', !section.fillable)}
          >
            Поле для заполнения в конце блока
          </Check>
          <div className="FaxConstructor__hint">
            Длинный текст разбейте на несколько блоков: в один блок помещается
            до {max_text_len} символов.
          </div>
        </div>
      ) : (
        <div className="FaxConstructor__group">
          <div className="FaxConstructor__groupTitle">
            Поля
            <span className="FaxConstructor__counter">
              {section.rows.length}/{max_rows}
            </span>
          </div>
          {section.rows.map((row, index) => (
            <RowCard
              key={index}
              section={section}
              row={row}
              index={index}
              dropMark={rowMark}
              onDragStart={setDraggedRow}
              onDragEnd={finishRowDrag}
              onDragOverRow={setRowMark}
              onDropRow={dropRow}
            />
          ))}
          <button
            type="button"
            className="FaxConstructor__ghostButton"
            disabled={section.rows.length >= max_rows}
            onClick={() => act('add_row', { id })}
          >
            <Icon name="plus" />
            Добавить поле
          </button>
        </div>
      )}
    </>
  );
};

type NavItemProps = {
  icon: string;
  label: string;
  active: boolean;
  onClick: () => void;
};

const NavItem = ({ icon, label, active, onClick }: NavItemProps) => (
  <button
    type="button"
    className={`FaxConstructor__navItem${active ? ' FaxConstructor__navItem--active' : ''}`}
    onClick={onClick}
  >
    <Icon name={icon} className="FaxConstructor__navIcon" />
    <span className="FaxConstructor__navLabel">{label}</span>
  </button>
);

type SidebarProps = {
  selection: Selection;
  galleryOpen: boolean;
  onSelect: (selection: Selection) => void;
  onOpenGallery: () => void;
};

const Sidebar = (props: SidebarProps) => {
  const { selection, galleryOpen, onSelect, onOpenGallery } = props;
  const { act, data } = useBackend<FaxConstructorData>();
  const { draft, max_sections } = data;
  const [addOpen, setAddOpen] = useState(false);
  const [dragged, setDragged] = useState<number | null>(null);
  const [mark, setMark] = useState<DropMark | null>(null);
  const canAdd = draft.sections.length < max_sections;

  const addSection = (kind: string) => {
    act('add_section', {
      kind,
      after: typeof selection === 'number' ? selection : undefined,
    });
    setAddOpen(false);
  };

  const finishDrag = () => {
    setDragged(null);
    setMark(null);
  };

  const dropSection = () => {
    if (dragged !== null && mark) {
      act('reorder_section', {
        id: draft.sections[dragged].id,
        index: dropTargetIndex(dragged, mark) + 1,
      });
    }
    finishDrag();
  };

  return (
    <div className="FaxConstructor__panel">
      <div className="FaxConstructor__panelHeader FaxConstructor__brand">
        <Icon name="file-lines" className="FaxConstructor__brandIcon" />
        <span>
          Конструктор
          <br />
          бланков
        </span>
      </div>
      <div className="FaxConstructor__nav">
        <NavItem
          icon="table-cells-large"
          label="Шаблоны"
          active={galleryOpen}
          onClick={onOpenGallery}
        />
        <NavItem
          icon="gear"
          label="Общие настройки"
          active={!galleryOpen && selection === 'settings'}
          onClick={() => onSelect('settings')}
        />
        <NavItem
          icon="stamp"
          label="Штампы"
          active={!galleryOpen && selection === 'stamps'}
          onClick={() => onSelect('stamps')}
        />
        <div className="FaxConstructor__navDivider" />
        {draft.sections.map((section, index) => {
          const classes = ['FaxConstructor__navItem'];
          classes.push('FaxConstructor__navItem--block');
          if (!galleryOpen && selection === section.id) {
            classes.push('FaxConstructor__navItem--selected');
          }
          if (dragged === index) {
            classes.push('FaxConstructor__navItem--dragging');
          }
          if (mark?.index === index) {
            classes.push(
              mark.after
                ? 'FaxConstructor__navItem--dropAfter'
                : 'FaxConstructor__navItem--dropBefore',
            );
          }
          return (
            <button
              key={section.id}
              type="button"
              draggable
              title="Перетащите, чтобы изменить порядок блоков"
              className={classes.join(' ')}
              onClick={() => onSelect(section.id)}
              onDragStart={() => setDragged(index)}
              onDragEnd={finishDrag}
              onDragOver={(event) => {
                event.preventDefault();
                setMark(dropMarkFor(event, index));
              }}
              onDrop={(event) => {
                event.preventDefault();
                dropSection();
              }}
            >
              <Icon
                name={section.kind === 'fields' ? 'list' : 'align-left'}
                className="FaxConstructor__navIcon"
              />
              <span className="FaxConstructor__navLabel">
                {section.title || `Блок ${index + 1}`}
              </span>
            </button>
          );
        })}
        <div className="FaxConstructor__navDivider" />
        <button
          type="button"
          className="FaxConstructor__addButton"
          disabled={!canAdd}
          onClick={() => setAddOpen(!addOpen)}
        >
          <Icon name={addOpen ? 'xmark' : 'plus'} />
          Добавить блок
        </button>
        {addOpen && canAdd && (
          <div className="FaxConstructor__addMenu">
            {ADD_OPTIONS.map((option) => (
              <button
                key={option.kind}
                type="button"
                className="FaxConstructor__addEntry"
                onClick={() => addSection(option.kind)}
              >
                <Icon name={option.icon} />
                <span>
                  {option.label}
                  <span className="FaxConstructor__addHint">{option.hint}</span>
                </span>
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

type FrameBox = {
  top: number;
  left: number;
  width: number;
  height: number;
};

type SelectionFrameProps = {
  box: FrameBox | null;
  selection: Selection;
};

const SelectionFrame = ({ box, selection }: SelectionFrameProps) => {
  const { act, data } = useBackend<FaxConstructorData>();
  if (!box) {
    return null;
  }
  const index =
    typeof selection === 'number'
      ? data.draft.sections.findIndex((section) => section.id === selection)
      : -1;
  return (
    <div
      className="FaxConstructor__selection"
      style={{
        top: box.top - 3,
        left: box.left - 3,
        width: box.width + 6,
        height: box.height + 6,
      }}
    >
      {HANDLE_POSITIONS.map((position) => (
        <span
          key={JSON.stringify(position)}
          className="FaxConstructor__handle"
          style={position}
        />
      ))}
      {index >= 0 && (
        <div className="FaxConstructor__blockTools">
          <IconButton
            icon="arrow-up"
            title="Выше"
            disabled={index === 0}
            onClick={() =>
              act('move_section', { id: selection, direction: 'up' })
            }
          />
          <IconButton
            icon="arrow-down"
            title="Ниже"
            disabled={index === data.draft.sections.length - 1}
            onClick={() =>
              act('move_section', { id: selection, direction: 'down' })
            }
          />
          <IconButton
            icon="copy"
            title="Дублировать"
            disabled={data.draft.sections.length >= data.max_sections}
            onClick={() => act('duplicate_section', { id: selection })}
          />
          <IconButton
            icon="trash"
            title="Удалить блок (можно отменить)"
            danger
            onClick={() => act('remove_section', { id: selection })}
          />
        </div>
      )}
    </div>
  );
};

type PaperProps = {
  zoom: number;
  selection: Selection;
  onSelect: (selection: Selection) => void;
};

const Paper = ({ zoom, selection, onSelect }: PaperProps) => {
  const { data } = useBackend<FaxConstructorData>();
  const { preview_html, custom_logo } = data;
  const bodyRef = useRef<HTMLDivElement>(null);
  const html = useMemo(
    () => renderPreviewHtml(preview_html, custom_logo),
    [preview_html, custom_logo],
  );
  const [box, setBox] = useState<FrameBox | null>(null);
  const sectionKey = selection === 'settings' ? 'header' : selection;

  useLayoutEffect(() => {
    const body = bodyRef.current;
    if (!body) {
      return;
    }
    const measure = () => {
      const target = body.querySelector<HTMLElement>(
        `[data-section="${sectionKey}"]`,
      );
      setBox(
        target
          ? {
              top: target.offsetTop,
              left: target.offsetLeft,
              width: target.offsetWidth,
              height: target.offsetHeight,
            }
          : null,
      );
    };
    measure();
    const observer = new ResizeObserver(measure);
    observer.observe(body);
    return () => observer.disconnect();
  }, [html, sectionKey]);

  const onClick = (event: MouseEvent<HTMLDivElement>) => {
    event.preventDefault();
    const target = (event.target as HTMLElement).closest('[data-section]');
    const clickedKey = target?.getAttribute('data-section');
    if (!clickedKey) {
      return;
    }
    if (clickedKey === 'header') {
      onSelect('settings');
    } else if (clickedKey === 'stamps') {
      onSelect('stamps');
    } else {
      onSelect(Number(clickedKey));
    }
  };
  return (
    <div className="FaxConstructor__stage">
      <div className="FaxConstructor__paper" style={{ zoom }}>
        <div className="FaxConstructor__paperBody" ref={bodyRef}>
          <div
            className="FaxConstructor__paperContent"
            onClick={onClick}
            dangerouslySetInnerHTML={{ __html: html }}
          />
          <SelectionFrame box={box} selection={selection} />
        </div>
      </div>
    </div>
  );
};

const CUSTOM_CATEGORY = 'Мои шаблоны';
const ALL_CATEGORIES = 'Все';

type GalleryProps = {
  onLoaded: () => void;
};

const Gallery = ({ onLoaded }: GalleryProps) => {
  const { act, data } = useBackend<FaxConstructorData>();
  const { builtin_presets, custom_presets } = data;
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState(ALL_CATEGORIES);
  const categories = [
    ALL_CATEGORIES,
    ...new Set(builtin_presets.map((preset) => preset.category)),
    CUSTOM_CATEGORY,
  ];
  const query = search.trim().toLowerCase();
  const matches = (name: string, presetCategory: string) =>
    (category === ALL_CATEGORIES || category === presetCategory) &&
    name.toLowerCase().includes(query);
  const shownBuiltin = builtin_presets.filter((preset) =>
    matches(preset.name, preset.category),
  );
  const shownCustom = custom_presets.filter((preset) =>
    matches(preset.name, CUSTOM_CATEGORY),
  );
  const loadPreset = (id: string, builtin: boolean) => {
    act('load_preset', { id, builtin });
    onLoaded();
  };
  const thumbnail = (html: string | null) => (
    <div className="FaxConstructor__thumb">
      <div
        className="FaxConstructor__thumbInner"
        dangerouslySetInnerHTML={{
          __html: renderPreviewHtml(html ?? '', null),
        }}
      />
    </div>
  );
  return (
    <div className="FaxConstructor__gallery">
      <div className="FaxConstructor__galleryBar">
        <div className="FaxConstructor__gallerySearch">
          <Input
            fluid
            autoFocus
            placeholder="Поиск шаблона по названию"
            value={search}
            onChange={setSearch}
          />
        </div>
        {categories.map((entry) => (
          <button
            key={entry}
            type="button"
            className={`FaxConstructor__chip${category === entry ? ' FaxConstructor__chip--active' : ''}`}
            onClick={() => setCategory(entry)}
          >
            {entry}
          </button>
        ))}
      </div>
      <div className="FaxConstructor__cards">
        <button
          type="button"
          className="FaxConstructor__card"
          onClick={() => {
            act('new_draft');
            onLoaded();
          }}
        >
          <div className="FaxConstructor__thumb FaxConstructor__empty">
            <Icon name="file-circle-plus" size={3} color="#2f6fb7" />
          </div>
          <div className="FaxConstructor__cardName">Новый бланк</div>
          <div className="FaxConstructor__cardMeta">Начать с чистого бланка</div>
        </button>
        {shownBuiltin.map((preset) => (
          <button
            key={preset.id}
            type="button"
            className="FaxConstructor__card"
            onClick={() => loadPreset(preset.id, true)}
          >
            {thumbnail(preset.preview_html)}
            <div className="FaxConstructor__cardName">{preset.name}</div>
            <div className="FaxConstructor__cardMeta">{preset.category}</div>
          </button>
        ))}
        {shownCustom.map((preset) => (
          <div key={preset.name} className="FaxConstructor__card">
            <button
              type="button"
              className="FaxConstructor__cardOpen"
              onClick={() => loadPreset(preset.name, false)}
            >
              {thumbnail(preset.preview_html)}
              <div className="FaxConstructor__cardName">{preset.name}</div>
              <div className="FaxConstructor__cardMeta">
                Автор: {preset.author}
              </div>
            </button>
            <div className="FaxConstructor__cardDelete">
              <ConfirmIconButton
                icon="trash"
                title="Удалить шаблон"
                onConfirm={() => act('delete_preset', { id: preset.name })}
              />
            </div>
          </div>
        ))}
      </div>
      {shownBuiltin.length + shownCustom.length === 0 && (
        <div className="FaxConstructor__empty">
          {category === CUSTOM_CATEGORY && !query
            ? 'Сохранённых шаблонов пока нет. Они общие для всех админов и не пропадают между раундами.'
            : 'Ничего не найдено.'}
        </div>
      )}
    </div>
  );
};

type CreateModalProps = {
  onClose: () => void;
};

const CreateModal = ({ onClose }: CreateModalProps) => {
  const { act, data } = useBackend<FaxConstructorData>();
  const {
    draft,
    destinations,
    destination,
    reply_department,
    reply_sender,
    reply_lost,
    notify_sender,
    field_count,
    max_fields,
    sending,
  } = data;
  const [search, setSearch] = useState('');
  const query = search.trim().toLowerCase();
  const canSend =
    !sending && !reply_lost && (!!reply_department || !!destination);
  const departmentName = (department: string) =>
    department === 'All Departments' ? 'Все отделы станции' : department;
  return (
    <div
      className="FaxConstructor__modalBackdrop"
      role="presentation"
      onClick={onClose}
    >
      <div
        className="FaxConstructor__modal"
        role="dialog"
        aria-label="Создание бланка"
        onClick={(event) => event.stopPropagation()}
      >
        <div className="FaxConstructor__panelHeader">
          <Icon name="paper-plane" className="FaxConstructor__panelHeaderIcon" />
          Создание бланка
          <div className="FaxConstructor__headerTools">
            <IconButton icon="xmark" title="Закрыть" onClick={onClose} />
          </div>
        </div>
        <div className="FaxConstructor__modalBody">
          <dl className="FaxConstructor__summary">
            <dt>Документ</dt>
            <dd>{draft.title || 'Без заголовка'}</dd>
            <dt>Полей для игрока</dt>
            <dd>{field_count}</dd>
            <dt>Штампов</dt>
            <dd>{draft.stamps.length + (draft.stamp_text ? 1 : 0)}</dd>
          </dl>
          {field_count > max_fields && (
            <div className="FaxConstructor__warning">
              Заполнить получится только первые {max_fields} полей из{' '}
              {field_count}.
            </div>
          )}
          {!!reply_lost && (
            <div className="FaxConstructor__warning">
              Факс отправителя уничтожен, ответить на него нельзя. Бланк можно
              положить рядом с собой.
            </div>
          )}
          {!!reply_department && (
            <dl className="FaxConstructor__summary">
              <dt>Ответ в отдел</dt>
              <dd>{reply_department}</dd>
              {!!reply_sender && <dt>Отправитель</dt>}
              {!!reply_sender && <dd>{reply_sender}</dd>}
            </dl>
          )}
          {!reply_department && !reply_lost && (
            <Field label="Получатель">
              <Input
                fluid
                placeholder="Поиск отдела"
                value={search}
                onChange={setSearch}
              />
              <div className="FaxConstructor__departments">
                {destinations
                  .filter((department) =>
                    departmentName(department).toLowerCase().includes(query),
                  )
                  .map((department) => (
                    <button
                      key={department}
                      type="button"
                      className={`FaxConstructor__department${destination === department ? ' FaxConstructor__department--selected' : ''}`}
                      onClick={() =>
                        act('set_destination', { destination: department })
                      }
                    >
                      {departmentName(department)}
                    </button>
                  ))}
              </div>
            </Field>
          )}
          {!!reply_sender && (
            <Check
              checked={!!notify_sender}
              onChange={() => act('toggle_notify')}
            >
              Сообщить отправителю в гарнитуру
            </Check>
          )}
        </div>
        <div className="FaxConstructor__modalActions">
          <button
            type="button"
            className="FaxConstructor__action"
            style={{ padding: '0 16px' }}
            onClick={onClose}
          >
            Отмена
          </button>
          <button
            type="button"
            className="FaxConstructor__action"
            title="Положить бумагу на пол рядом с вами"
            onClick={() => {
              act('create');
              onClose();
            }}
          >
            <Icon name="file-arrow-down" />
            Положить рядом
          </button>
          <button
            type="button"
            className="FaxConstructor__action FaxConstructor__action--primary"
            disabled={!canSend}
            title={canSend ? undefined : 'Сначала выберите получателя'}
            onClick={() => {
              act('send');
              onClose();
            }}
          >
            <Icon name="paper-plane" />
            Отправить факс
          </button>
        </div>
      </div>
    </div>
  );
};

export const FaxConstructor = () => {
  const { act, data } = useBackend<FaxConstructorData>();
  const { draft, can_undo, can_redo } = data;
  const [selection, setSelection] = useState<Selection>('settings');
  const [galleryOpen, setGalleryOpen] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [zoomStep, setZoomStep] = useState(DEFAULT_ZOOM_STEP);
  const knownSections = useRef(draft.sections.map((section) => section.id));

  useEffect(() => {
    const appeared = draft.sections.filter(
      (section) => !knownSections.current.includes(section.id),
    );
    if (appeared.length === 1 && knownSections.current.length > 0) {
      setSelection(appeared[0].id);
    }
    knownSections.current = draft.sections.map((section) => section.id);
  }, [draft.sections]);

  const latestAct = useRef(act);
  latestAct.current = act;

  useEffect(
    () =>
      listenForKeyEvents((key) => {
        if (!key.isDown()) {
          return;
        }
        const combo = String(key);
        if (combo === 'Ctrl+S') {
          key.event.preventDefault();
          if (!key.repeat) {
            latestAct.current('save_preset');
          }
        } else if (combo === 'Ctrl+Z') {
          key.event.preventDefault();
          latestAct.current('undo');
        } else if (combo === 'Ctrl+Y' || combo === 'Ctrl+Shift+Z') {
          key.event.preventDefault();
          latestAct.current('redo');
        } else if (key.code === KEY_ESCAPE) {
          setModalOpen(false);
          setGalleryOpen(false);
        }
      }),
    [],
  );

  const selectedSection =
    typeof selection === 'number'
      ? draft.sections.find((section) => section.id === selection)
      : undefined;
  const effectiveSelection: Selection =
    typeof selection === 'number' && !selectedSection ? 'settings' : selection;

  const select = (next: Selection) => {
    setSelection(next);
    setGalleryOpen(false);
  };

  const saveFromTextField = (event: KeyboardEvent<HTMLDivElement>) => {
    const tag = (event.target as HTMLElement).tagName;
    if (
      !event.ctrlKey ||
      event.shiftKey ||
      event.code !== 'KeyS' ||
      (tag !== 'INPUT' && tag !== 'TEXTAREA')
    ) {
      return;
    }
    event.preventDefault();
    if (!event.repeat) {
      setTimeout(
        () => latestAct.current('save_preset'),
        SAVE_AFTER_TYPING_DELAY_MS,
      );
    }
  };

  return (
    <Window theme="faxconstructor" width={1400} height={860}>
      <Window.Content>
        <div
          className="FaxConstructor"
          role="presentation"
          onKeyDown={saveFromTextField}
        >
          <Sidebar
            selection={effectiveSelection}
            galleryOpen={galleryOpen}
            onSelect={select}
            onOpenGallery={() => setGalleryOpen(!galleryOpen)}
          />
          <div className="FaxConstructor__panel">
            <div className="FaxConstructor__panelHeader">
              <Icon
                name={galleryOpen ? 'table-cells-large' : 'pen'}
                className="FaxConstructor__panelHeaderIcon"
              />
              {galleryOpen ? 'Шаблоны' : 'Редактор бланка'}
              <div className="FaxConstructor__headerTools">
                <IconButton
                  icon="rotate-left"
                  title="Отменить (Ctrl+Z)"
                  disabled={!can_undo}
                  onClick={() => act('undo')}
                />
                <IconButton
                  icon="rotate-right"
                  title="Повторить (Ctrl+Y)"
                  disabled={!can_redo}
                  onClick={() => act('redo')}
                />
                <div className="FaxConstructor__toolSeparator" />
                <IconButton
                  icon="magnifying-glass-minus"
                  title="Уменьшить"
                  disabled={galleryOpen || zoomStep === 0}
                  onClick={() => setZoomStep(zoomStep - 1)}
                />
                <span className="FaxConstructor__zoomLabel">
                  {Math.round(ZOOM_STEPS[zoomStep] * 100)}%
                </span>
                <IconButton
                  icon="magnifying-glass-plus"
                  title="Увеличить"
                  disabled={galleryOpen || zoomStep === ZOOM_STEPS.length - 1}
                  onClick={() => setZoomStep(zoomStep + 1)}
                />
              </div>
            </div>
            {galleryOpen ? (
              <Gallery onLoaded={() => setGalleryOpen(false)} />
            ) : (
              <Paper
                zoom={ZOOM_STEPS[zoomStep]}
                selection={effectiveSelection}
                onSelect={select}
              />
            )}
            <div className="FaxConstructor__actions">
              <button
                type="button"
                className="FaxConstructor__action"
                title="Открыть бумагу так, как её увидит игрок"
                onClick={() => act('preview')}
              >
                <Icon name="eye" />
                Предпросмотр
              </button>
              <button
                type="button"
                className="FaxConstructor__action"
                title="Сохранить для всех админов (Ctrl+S)"
                onClick={() => act('save_preset')}
              >
                <Icon name="floppy-disk" />
                Сохранить шаблон
              </button>
              <button
                type="button"
                className="FaxConstructor__action FaxConstructor__action--primary"
                onClick={() => setModalOpen(true)}
              >
                <Icon name="check" />
                Создать бланк
              </button>
            </div>
          </div>
          <div className="FaxConstructor__panel">
            <div className="FaxConstructor__panelHeader">
              <Icon
                name="sliders"
                className="FaxConstructor__panelHeaderIcon"
              />
              Свойства элемента
            </div>
            <div className="FaxConstructor__properties">
              {effectiveSelection === 'settings' && <SettingsPanel />}
              {effectiveSelection === 'stamps' && <StampsPanel />}
              {!!selectedSection && (
                <SectionPanel
                  key={selectedSection.id}
                  section={selectedSection}
                />
              )}
            </div>
          </div>
          {modalOpen && <CreateModal onClose={() => setModalOpen(false)} />}
        </div>
      </Window.Content>
    </Window>
  );
};
