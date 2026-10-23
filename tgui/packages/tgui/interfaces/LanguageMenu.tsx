import {
  Box,
  Button,
  DmIcon,
  Icon,
  Section,
  Stack,
  Table,
  Tooltip,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';
import { useBackend } from '../backend';
import { Window } from '../layouts';

type Language = {
  name: string;
  desc: string;
  key: string | null;
  is_default: BooleanLike;
  can_speak: BooleanLike;
  could_speak: BooleanLike;
  can_understand: BooleanLike;
  partial_understanding: number;
  icon: string;
  icon_state: string;
};

type Data = {
  is_living: BooleanLike;
  admin_mode: BooleanLike;
  omnitongue: BooleanLike;
  languages: Language[];
};

type LanguageProps = {
  language: Language;
};

type LanguagePropsPassRest = LanguageProps & {
  [key: string]: any;
};

const LangSpeakIcon = (props: LanguagePropsPassRest) => {
  const { language, ...rest } = props;
  return (
    <Icon
      name="comment"
      color={
        language.could_speak
          ? language.can_speak
            ? 'good'
            : 'bad'
          : language.can_speak
            ? 'average'
            : 'grey'
      }
      {...rest}
    />
  );
};

const LangUnderstandIcon = (props: LanguageProps) => {
  const { language } = props;
  if (!language.can_understand && language.partial_understanding > 0) {
    return (
      <Tooltip content={`Вы понимаете ${language.name} лишь частично.`}>
        <Box
          inline
          style={{
            borderBottom: '2px dotted rgba(255, 255, 255, 0.8)',
          }}
        >
          {language.partial_understanding}%
        </Box>
      </Tooltip>
    );
  }
  return <Icon name="brain" color={language.can_understand ? 'good' : 'bad'} />;
};

const LanguageNameAndDesc = (props: LanguageProps) => {
  const { language } = props;
  return language.desc ? (
    <Tooltip content={language.desc} position="bottom-start">
      <Box
        inline
        style={{
          borderBottom: '2px dotted rgba(255, 255, 255, 0.8)',
        }}
      >
        {language.name}
      </Box>
    </Tooltip>
  ) : (
    <Box>{language.name}</Box>
  );
};

const LanguageRow = (props: LanguageProps) => {
  const { act, data } = useBackend<Data>();
  const { is_living, admin_mode } = data;
  const { language } = props;

  return (
    <Table.Row className="candystripe">
      <Table.Cell verticalAlign="middle">
        {language.icon && language.icon_state ? (
          <Stack>
            <Stack.Item>
              <DmIcon icon={language.icon} icon_state={language.icon_state} />
            </Stack.Item>
            <Stack.Item>
              <LanguageNameAndDesc language={language} />
            </Stack.Item>
          </Stack>
        ) : (
          <LanguageNameAndDesc language={language} />
        )}
      </Table.Cell>
      <Table.Cell>
        {!language.could_speak ? (
          <Tooltip
            content={
              language.can_speak
                ? `Вы знаете ${language.name}, но физически не можете на нём говорить.`
                : `Даже выучив ${language.name}, вы физически не сможете на нём говорить.`
            }
          >
            <LangSpeakIcon
              language={language}
              inline
              style={{
                borderBottom: '2px dotted rgba(255, 255, 255, 0.8)',
              }}
            />
          </Tooltip>
        ) : (
          <LangSpeakIcon language={language} />
        )}
      </Table.Cell>
      <Table.Cell>
        <LangUnderstandIcon language={language} />
      </Table.Cell>
      <Table.Cell>{language.key ? `:${language.key}` : '—'}</Table.Cell>
      {!!is_living && (
        <Table.Cell>
          <Button.Checkbox
            checked={language.is_default}
            color={
              language.is_default
                ? 'good'
                : language.could_speak && language.can_speak
                  ? 'grey'
                  : 'transparent'
            }
            onClick={() =>
              act('select_default', {
                language_name: language.name,
              })
            }
          />
        </Table.Cell>
      )}
      {!!admin_mode && (
        <Table.Cell>
          <Button
            disabled={language.can_speak && language.can_understand}
            onClick={() =>
              act('grant_language', {
                language_name: language.name,
              })
            }
          >
            Выдать
          </Button>
          <Button
            disabled={!language.can_speak && !language.can_understand}
            onClick={() =>
              act('remove_language', {
                language_name: language.name,
              })
            }
          >
            Убрать
          </Button>
        </Table.Cell>
      )}
    </Table.Row>
  );
};

const OmnitongueToggle = (props) => {
  const { act, data } = useBackend<Data>();
  const { omnitongue } = data;
  return (
    <Button
      tooltip="Если включено, физические ограничения больше не мешают говорить на известных языках."
      selected={omnitongue}
      onClick={() => act('toggle_omnitongue')}
    >
      {`Всеязычие ${omnitongue ? 'включено' : 'выключено'}`}
    </Button>
  );
};

export const LanguageMenu = (props) => {
  const { data } = useBackend<Data>();
  const { admin_mode, is_living, languages } = data;

  const shown_languages = languages
    .filter(
      (language) =>
        admin_mode ||
        language.can_speak ||
        language.can_understand ||
        language.partial_understanding > 0,
    )
    .sort(
      (a, b) =>
        ((a.can_speak ? 1 : 0) - (b.can_speak ? 1 : 0)) * -2 +
        (a.name > b.name ? 1 : 0),
    );

  return (
    <Window
      title="Меню языков"
      width={admin_mode ? 700 : 500}
      height={Math.min(
        shown_languages.length * 25 + (admin_mode ? 100 : 70),
        500,
      )}
    >
      <Window.Content>
        <Section
          scrollable
          title={admin_mode ? <i>- Режим администратора -</i> : null}
          buttons={admin_mode ? <OmnitongueToggle /> : null}
          fill
        >
          <Table>
            <Table.Row header>
              <Table.Cell>Язык</Table.Cell>
              <Table.Cell>Речь</Table.Cell>
              <Table.Cell>Понимание</Table.Cell>
              <Table.Cell>
                <Tooltip content="Напишите этот ключ в сообщении, чтобы говорить на этом языке.">
                  <Box
                    inline
                    style={{
                      borderBottom: '2px dotted rgba(255, 255, 255, 0.8)',
                    }}
                  >
                    Ключ
                  </Box>
                </Tooltip>
              </Table.Cell>
              {!!is_living && (
                <Table.Cell>
                  <Tooltip content="Язык, на котором вы говорите без ключа.">
                    <Box
                      inline
                      style={{
                        borderBottom: '2px dotted rgba(255, 255, 255, 0.8)',
                      }}
                    >
                      Основной
                    </Box>
                  </Tooltip>
                </Table.Cell>
              )}
              {!!admin_mode && <Table.Cell />}
            </Table.Row>
            {shown_languages.map((language) => (
              <LanguageRow key={language.name} language={language} />
            ))}
          </Table>
        </Section>
      </Window.Content>
    </Window>
  );
};
