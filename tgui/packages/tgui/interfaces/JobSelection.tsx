import { toMerged } from 'es-toolkit';
import { Color } from 'tgui-core/color';
import {
  Box,
  Button,
  Icon,
  NoticeBox,
  Section,
  Stack,
  StyleableSection,
} from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { JOB2ICON } from './common/JobToIcon';

type Job = {
  name: string;
  unavailable_reason: string | null;
  command: BooleanLike;
  open_slots: number | string;
  used_slots: number;
  prioritized: BooleanLike;
  description: string | null;
};

type Department = {
  color: string;
  jobs: Record<string, Job>;
  open_slots: number | string;
};

type Data = {
  departments_static: Record<string, Department>;
  departments: Record<string, Department>;
  shuttle_status: string;
  round_duration: string;
};

type JobEntryProps = {
  jobName: string;
  job: Job;
  department: Department;
  onClick: () => void;
};

function JobEntry(props: JobEntryProps) {
  const { jobName, job, department, onClick } = props;

  const jobIcon = JOB2ICON[jobName] || null;

  return (
    <Button
      fluid
      style={{
        backgroundColor: job.unavailable_reason
          ? '#949494'
          : job.prioritized
            ? '#16fc0f'
            : Color.fromHex(department.color).darken(10).toString(),
        color: job.unavailable_reason
          ? '#616161'
          : Color.fromHex(department.color).darken(90).toString(),
        fontSize: '1.1rem',
        cursor: job.unavailable_reason ? 'initial' : 'pointer',
      }}
      tooltip={
        job.unavailable_reason ||
        (job.prioritized ? (
          <>
            <p style={{ marginTop: '0px' }}>
              <b>Глава персонала ищет людей на эту должность!</b>
            </p>
            {job.description}
          </>
        ) : (
          job.description
        ))
      }
      tooltipPosition="top"
      onClick={() => {
        !job.unavailable_reason && onClick();
      }}
    >
      <Stack fill>
        {jobIcon && (
          <Stack.Item>
            <Icon name={jobIcon} />
          </Stack.Item>
        )}
        <Stack.Item grow>
          {job.command ? <b>{job.name}</b> : job.name}
        </Stack.Item>
        <Stack.Item>
          <span
            style={{
              whiteSpace: 'nowrap',
            }}
          >
            {job.used_slots} / {job.open_slots}
          </span>
        </Stack.Item>
      </Stack>
    </Button>
  );
}

type DepartmentEntryProps = {
  name: string;
  department: Department;
};

function DepartmentEntry(props: DepartmentEntryProps) {
  const { name, department } = props;
  const { act } = useBackend<Data>();

  return (
    <Box minWidth="30%">
      <StyleableSection
        title={
          <>
            {name}
            <span
              style={{
                fontSize: '1rem',
                whiteSpace: 'nowrap',
                position: 'absolute',
                right: '1em',
                color: Color.fromHex(department.color).darken(60).toString(),
              }}
            >
              Свободно: {department.open_slots}
            </span>
          </>
        }
        style={{
          backgroundColor: department.color,
          marginBottom: '1em',
          breakInside: 'avoid-column',
        }}
        titleStyle={{
          'border-bottom-color': Color.fromHex(department.color)
            .darken(50)
            .toString(),
        }}
        textStyle={{
          color: Color.fromHex(department.color).darken(80).toString(),
        }}
      >
        <Stack vertical>
          {Object.entries(department.jobs).map(([name, job]) => (
            <Stack.Item key={name}>
              <JobEntry
                key={name}
                jobName={name}
                job={job}
                department={department}
                onClick={() => {
                  act('select_job', { job: name });
                }}
              />
            </Stack.Item>
          ))}
        </Stack>
      </StyleableSection>
    </Box>
  );
}

export function JobSelection(props) {
  const { act, data } = useBackend<Data>();
  if (!data?.departments_static) {
    return null;
  }

  const departments: Record<string, Department> = toMerged(
    data.departments,
    data.departments_static,
  );

  const { shuttle_status, round_duration } = data;

  return (
    <Window width={1012} height={shuttle_status ? 690 : 666}>
      <Window.Content>
        <Section
          buttons={
            <Button
              onClick={() => act('select_job', { job: 'Random' })}
              tooltip="Случайная должность из доступных вам."
            >
              Случайная должность!
            </Button>
          }
          fill
          scrollable
          title={
            <>
              {shuttle_status && <NoticeBox info>{shuttle_status}</NoticeBox>}
              <Box as="span" color="label">
                Смена идёт уже {round_duration}.
              </Box>
            </>
          }
        >
          <Box style={{ columns: '20em' }}>
            {Object.entries(departments).map(([name, department]) => (
              <DepartmentEntry key={name} name={name} department={department} />
            ))}
          </Box>
        </Section>
      </Window.Content>
    </Window>
  );
}
