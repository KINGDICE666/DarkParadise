import type { PropsWithChildren, ReactNode } from 'react';
import { useBackend } from 'tgui/backend';
import { Box, Button, Dropdown, Stack, Tooltip } from 'tgui-core/components';
import { classes } from 'tgui-core/react';

import {
  createSetPreference,
  type Job,
  JoblessRole,
  JobPriority,
  type PreferencesMenuData,
} from '../types';
import { useServerPrefs } from '../useServerPrefs';

const EXPERIENCE_TYPES: Record<string, string> = {
  Crew: 'экипаж',
  Command: 'командование',
  Engineering: 'инженерию',
  Medical: 'медицину',
  Science: 'науку',
  Supply: 'снабжение',
  Security: 'охрану',
  Silicon: 'синтетиков',
  Service: 'обслуживание',
  Special: 'особые роли',
  Ghost: 'призрака',
};

function sortJobs(entries: [string, Job][], head?: string) {
  return [
    ...entries.filter(([key]) => key === head),
    ...entries.filter(([key]) => key !== head),
  ];
}

const PRIORITY_BUTTON_SIZE = '18px';

type PriorityButtonProps = {
  name: string;
  color: string;
  modifier?: string;
  enabled: boolean;
  onClick: () => void;
};

function PriorityButton(props: PriorityButtonProps) {
  const className = `PreferencesMenu__Jobs__departments__priority`;

  return (
    <Stack.Item height={PRIORITY_BUTTON_SIZE}>
      <Button
        className={classes([
          className,
          props.modifier && `${className}--${props.modifier}`,
        ])}
        color={props.enabled ? props.color : 'white'}
        circular
        onClick={props.onClick}
        tooltip={props.name}
        tooltipPosition="bottom"
        height={PRIORITY_BUTTON_SIZE}
        width={PRIORITY_BUTTON_SIZE}
      />
    </Stack.Item>
  );
}

type CreateSetPriority = (priority: JobPriority | null) => () => void;

function useCreateSetPriority(jobName: string): CreateSetPriority {
  const { act } = useBackend<PreferencesMenuData>();

  return (priority) => () =>
    act('set_job_preference', {
      job: jobName,
      level: priority,
    });
}

function PriorityHeaders() {
  const className = 'PreferencesMenu__Jobs__PriorityHeader';

  return (
    <Stack>
      <Stack.Item grow />

      <Stack.Item className={className}>Нет</Stack.Item>

      <Stack.Item className={className}>Низкий</Stack.Item>

      <Stack.Item className={className}>Средний</Stack.Item>

      <Stack.Item className={className}>Высокий</Stack.Item>
    </Stack>
  );
}

type PriorityButtonsProps = {
  createSetPriority: CreateSetPriority;
  isExclusive: boolean;
  priority: JobPriority;
};

function PriorityButtons(props: PriorityButtonsProps) {
  const { createSetPriority, isExclusive, priority } = props;

  return (
    <Stack
      style={{
        alignItems: 'center',
        height: '100%',
        justifyContent: 'flex-end',
        paddingLeft: '0.3em',
      }}
    >
      {isExclusive ? (
        <>
          <PriorityButton
            name="Нет"
            modifier="off"
            color="light-grey"
            enabled={!priority}
            onClick={createSetPriority(null)}
          />

          <PriorityButton
            name="Да"
            color="green"
            enabled={!!priority}
            onClick={createSetPriority(JobPriority.Low)}
          />
        </>
      ) : (
        <>
          <PriorityButton
            name="Нет"
            modifier="off"
            color="light-grey"
            enabled={!priority}
            onClick={createSetPriority(null)}
          />

          <PriorityButton
            name="Низкий"
            color="red"
            enabled={priority === JobPriority.Low}
            onClick={createSetPriority(JobPriority.Low)}
          />

          <PriorityButton
            name="Средний"
            color="yellow"
            enabled={priority === JobPriority.Medium}
            onClick={createSetPriority(JobPriority.Medium)}
          />

          <PriorityButton
            name="Высокий"
            color="green"
            enabled={priority === JobPriority.High}
            onClick={createSetPriority(JobPriority.High)}
          />
        </>
      )}
    </Stack>
  );
}

type JobRowProps = {
  className?: string;
  job: Job;
  name: string;
  muted: boolean;
};

function JobRow(props: JobRowProps) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const { className, job, name, muted } = props;

  const priority = data.job_preferences[name];
  const createSetPriority = useCreateSetPriority(name);

  const experienceNeeded = data.job_required_experience?.[name];
  const daysLeft = data.job_days_left ? data.job_days_left[name] : 0;
  const restriction = data.job_restrictions?.[name];

  let rightSide: ReactNode;

  if (data.job_bans && data.job_bans.indexOf(name) !== -1) {
    rightSide = (
      <Stack align="center" height="100%" pr={1}>
        <Stack.Item grow textAlign="right">
          <b>Заблокировано</b>
        </Stack.Item>
      </Stack>
    );
  } else if (experienceNeeded) {
    const { experience_type, required_playtime } = experienceNeeded;
    const hoursNeeded = Math.ceil(required_playtime / 60);

    rightSide = (
      <Stack align="center" height="100%" pr={1}>
        <Stack.Item grow textAlign="right">
          <b>{hoursNeeded} ч.</b> за{' '}
          {EXPERIENCE_TYPES[experience_type] ?? experience_type}
        </Stack.Item>
      </Stack>
    );
  } else if (daysLeft > 0) {
    rightSide = (
      <Stack align="center" height="100%" pr={1}>
        <Stack.Item grow textAlign="right">
          Через <b>{daysLeft}</b> дн.
        </Stack.Item>
      </Stack>
    );
  } else if (restriction) {
    rightSide = (
      <Stack align="center" height="100%" pr={1}>
        <Stack.Item grow textAlign="right">
          <b>{restriction}</b>
        </Stack.Item>
      </Stack>
    );
  } else {
    rightSide = (
      <PriorityButtons
        createSetPriority={createSetPriority}
        isExclusive={!!job.exclusive}
        priority={priority}
      />
    );
  }

  const displayName = data.job_titles?.[name] ?? job.name;

  let jobName: ReactNode = (
    <Stack.Item
      className="job-name"
      width="50%"
      style={{
        paddingLeft: '0.3em',
      }}
    >
      {job.alt_titles ? (
        <Box
          as="span"
          className="alt-titles"
          onClick={() => act('set_job_title', { job: name })}
        >
          {displayName}
        </Box>
      ) : (
        displayName
      )}
    </Stack.Item>
  );

  if (job.description) {
    jobName = (
      <Tooltip content={job.description} position="bottom-start">
        {jobName}
      </Tooltip>
    );
  }

  return (
    <Stack.Item
      className={classes([className, muted && 'muted'])}
      height="100%"
      mt={0}
    >
      <Stack fill align="center">
        {jobName}

        <Stack.Item grow className="options">
          {rightSide}
        </Stack.Item>
      </Stack>
    </Stack.Item>
  );
}

type DepartmentProps = {
  department: string;
} & PropsWithChildren;

function Department(props: DepartmentProps) {
  const { children, department: name } = props;
  const className = `PreferencesMenu__Jobs__departments--${name}`;
  const { data: backendData } = useBackend<PreferencesMenuData>();

  const data = useServerPrefs();
  if (!data) return;

  const { departments, jobs } = data.jobs;
  const department = departments[name];

  if (!department) {
    return null;
  }

  const jobsForDepartment = sortJobs(
    Object.entries(jobs).filter(([_, job]) => job.department === name),
    department.head,
  );

  const exclusiveSelected = Object.entries(jobs).some(
    ([jobName, job]) => job.exclusive && backendData.job_preferences[jobName],
  );

  return (
    <Box>
      <Stack fill vertical g={0}>
        {jobsForDepartment.map(([name, job]) => {
          return (
            <JobRow
              className={classes([
                className,
                name === department.head && 'head',
              ])}
              key={name}
              job={job}
              name={name}
              muted={exclusiveSelected && !job.exclusive}
            />
          );
        })}
      </Stack>

      {children}
    </Box>
  );
}

function JoblessRoleDropdown(props) {
  const { act, data } = useBackend<PreferencesMenuData>();
  const selected = data.character_preferences.misc.alternate_option;

  const options = [
    {
      displayText: 'Стать гражданским, если должность недоступна',
      value: JoblessRole.BeOverflow,
    },
    {
      displayText: 'Случайная должность, если должность недоступна',
      value: JoblessRole.BeRandomJob,
    },
    {
      displayText: 'Вернуться в лобби, если должность недоступна',
      value: JoblessRole.ReturnToLobby,
    },
  ];

  const selection = options?.find(
    (option) => option.value === selected,
  )?.displayText;

  return (
    <Box position="absolute" right={0} width="30%">
      <Dropdown
        width="100%"
        selected={selection}
        onSelected={createSetPreference(act, 'alternate_option')}
        options={options}
      />
    </Box>
  );
}

export function JobsPage() {
  return (
    <>
      <JoblessRoleDropdown />
      <Stack vertical fill>
        <Stack.Item mt={15}>
          <Stack fill g={1} className="PreferencesMenu__Jobs">
            <Stack.Item>
              <Stack vertical>
                <PriorityHeaders />
                <Department department="Engineering" />
                <Department department="Science" />
                <Department department="Silicon" />
                <Department department="Civilian" />
              </Stack>
            </Stack.Item>
            <Stack.Item mt={-5.9}>
              <Stack vertical>
                <PriorityHeaders />
                <Department department="Command" />
                <Department department="Service" />
                <Department department="Supply" />
                <Department department="Legal" />
              </Stack>
            </Stack.Item>
            <Stack.Item>
              <Stack vertical>
                <PriorityHeaders />
                <Department department="Security" />
                <Department department="Medical" />
              </Stack>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </>
  );
}
