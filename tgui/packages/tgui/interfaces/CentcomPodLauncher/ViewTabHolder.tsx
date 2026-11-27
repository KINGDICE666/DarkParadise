import { useEffect } from 'react';
import { Button, ByondUi, Section, Stack } from 'tgui-core/components';
import { useBackend } from '../../backend';
import { POD_GREY, TABPAGES } from './constants';
import type { PodLauncherData } from './types';

export const ViewTabHolder = (props: unknown) => {
  const { act, data } = useBackend<PodLauncherData>();
  const { mapRef, customDropoff, effectReverse, renderLighting, tabIndex } =
    data;

  const TabPageComponent = (TABPAGES[tabIndex] || TABPAGES[1]).component;

  // Карту заполняем после того, как ByondUi создал контрол, иначе BYOND берёт размер всего экрана
  useEffect(() => {
    act('refreshView');
  }, []);

  return (
    <Section
      buttons={
        <>
          {!!customDropoff && !!effectReverse && (
            <Button
              color="transparent"
              icon="arrow-circle-down"
              inline
              onClick={() => act('tabSwitch', { tabIndex: 2 })}
              selected={tabIndex === 2}
              tooltip="Место Высадки"
            />
          )}
          <Button
            color="transparent"
            icon="rocket"
            inline
            onClick={() => act('tabSwitch', { tabIndex: 0 })}
            selected={tabIndex === 0}
            tooltip="Капсула"
          />
          <Button
            color="transparent"
            icon="th"
            inline
            onClick={() => act('tabSwitch', { tabIndex: 1 })}
            selected={tabIndex === 1}
            tooltip="Ангар Погрузки"
          />
          <span style={POD_GREY}>|</span>
          {!!customDropoff && !!effectReverse && (
            <Button
              color="transparent"
              icon="lightbulb"
              inline
              onClick={() => {
                act('renderLighting');
                act('refreshView');
              }}
              selected={renderLighting}
              tooltip="Рендеринг освещения"
            />
          )}
          <Button
            color="transparent"
            icon="sync-alt"
            inline
            onClick={() => act('refreshView')}
            tooltip="Обновить окно просмотра"
          />
        </>
      }
      fill
      title="Осмотр"
    >
      <Stack fill vertical>
        <Stack.Item>
          <TabPageComponent />
        </Stack.Item>
        <Stack.Item grow>
          <ByondUi
            height="100%"
            params={{
              id: mapRef,
              type: 'map',
              zoom: 0,
            }}
          />
        </Stack.Item>
      </Stack>
    </Section>
  );
};
