import { Button } from 'tgui-core/components';
import { useBackend } from '../../backend';

export const LogisticsButton = (props: { enabled?: boolean }) => {
  const { act, data } = useBackend<{ logistics_enabled?: boolean }>();
  const enabled = props.enabled ?? !!data.logistics_enabled;
  return (
    <Button
      icon="boxes"
      tooltip="Логистика"
      tooltipPosition="bottom"
      disabled={!enabled}
      onClick={() => act('open_logistics')}
    />
  );
};
