import React from 'react';
import { Text } from '@mantine/core';
import { IconBriefcase, IconBuildingBank, IconCalendarEvent, IconCashBanknote, IconFlag, IconGenderBigender, IconRuler2 } from '@tabler/icons-react';

interface Props {
  icon: string;
  label: string;
}

const iconMap: { [key: string]: JSX.Element } = {
  gender: <IconGenderBigender />,
  birthdate: <IconCalendarEvent />,
  nationality: <IconFlag />,
  bank: <IconBuildingBank />,
  cash: <IconCashBanknote />,
  job: <IconBriefcase />,
  height: <IconRuler2 />
};

const InfoCard: React.FC<Props> = (props) => {
  const icon = iconMap[props.icon];

  return (
    <div className='character-card-charinfo'>
      {icon}
      <Text fw={500} size="lg"><span className="ellipsis">{props.label}</span></Text>
    </div>
  );
};

export default InfoCard;