import React, { useEffect, useState } from "react";
import { Button, Group, rem, Select, TextInput, NumberInput } from "@mantine/core";
import { useForm } from "@mantine/form";
import { DatePickerInput } from "@mantine/dates";
import { IconCalendar } from "@tabler/icons-react";
import { fetchNui } from "../utils/fetchNui";

interface Props {
	handleCreate: () => void;
	id: number;
}

interface UIConfig {
	height: {
		default: number;
		min: number;
		max: number;
	};
}

const CreateCharacterModal: React.FC<Props> = (props) => {
	const icon = (
		<IconCalendar style={{ width: rem(18), height: rem(18) }} stroke={1.5} />
	);
	
	const [nationalities, setNationalities] = useState<string[]>([]);
	const [uiConfig, setUiConfig] = useState<UIConfig>({
		height: {
			default: 170,
			min: 110,
			max: 220
		}
	});
	
	// Fetch nationalities and UI config from the server
	useEffect(() => {
		const fetchData = async () => {
			try {
				const [nationalitiesResponse, configResponse] = await Promise.all([
					fetchNui<string[]>("getNationalities", {}, { data: [] }),
					fetchNui<UIConfig>("getUIConfig", {}, { 
						data: {
							height: {
								default: 170,
								min: 110,
								max: 220
							}
						}
					})
				]);
				setNationalities(nationalitiesResponse);
				setUiConfig(configResponse);
			} catch (error) {
				console.error("Failed to fetch data:", error);
				setNationalities([
					"American", "British", "Canadian", "French", "German", 
					"Italian", "Japanese", "Mexican", "Russian", "Spanish"
				]);
			}
		};
		
		fetchData();
	}, []);

	const form = useForm({
		initialValues: {
			firstName: "",
			lastName: "",
			nationality: "",
			gender: "",
			birthdate: new Date("2006-12-31"),
			height: uiConfig.height.default,
		},
		validate: {
			firstName: (value) => (value.length < 2 ? "First name is too short" : null),
			lastName: (value) => (value.length < 2 ? "Last name is too short" : null),
			nationality: (value) => (!value ? "Nationality is required" : null),
			gender: (value) => (!value ? "Gender is required" : null),
			birthdate: (value) => (!value ? "Birthdate is required" : null),
			height: (value) => (
				value < uiConfig.height.min || value > uiConfig.height.max
					? `Height must be between ${uiConfig.height.min}cm and ${uiConfig.height.max}cm`
					: null
			),
		},
	});

	const handleSubmit = async (values: {
		firstName: string;
		lastName: string;
		nationality: string;
		gender: string;
		birthdate: Date;
		height: number;
	}) => {
		const dateString = values.birthdate.toISOString().slice(0, 10);
		props.handleCreate();
		await fetchNui<string>(
			"createNewCharacter",
			{ cid: props.id, character: { ...values, birthdate: dateString } },
			{ data: "success" }
		);
	};

	return (
		<form onSubmit={form.onSubmit((values) => handleSubmit(values))}>
			<Group grow>
				<TextInput
					data-autofocus
					required
					placeholder='Your First Name'
					label='First Name'
					{...form.getInputProps("firstName")}
				/>

				<TextInput
					required
					placeholder='Your Last Name'
					label='Last Name'
					{...form.getInputProps("lastName")}
				/>
			</Group>

			<Select
				required
				label='Nationality'
				placeholder='Select Nationality'
				data={nationalities}
				defaultValue={nationalities[0]}
				allowDeselect={false}
				{...form.getInputProps("nationality")}
			/>

			<Select
				required
				label='Gender'
				placeholder='Select Gender'
				data={["Male", "Female"]}
				defaultValue='Male'
				allowDeselect={false}
				{...form.getInputProps("gender")}
			/>

			<NumberInput
				required
				label='Height (cm)'
				placeholder='Enter your height'
				min={uiConfig.height.min}
				max={uiConfig.height.max}
				defaultValue={uiConfig.height.default}
				{...form.getInputProps("height")}
			/>

			<DatePickerInput
				leftSection={icon}
				leftSectionPointerEvents='none'
				label='Select Date of Birth'
				placeholder={"YYYY-MM-DD"}
				valueFormat='YYYY-MM-DD'
				defaultValue={new Date("2006-12-31")}
				minDate={new Date("1900-01-01")}
				maxDate={new Date("2006-12-31")}
				{...form.getInputProps("birthdate")}
			/>

			<Group justify='flex-end' mt='sm'>
				<Button color='teal' h={45} fullWidth variant='light' type='submit'>
					Create
				</Button>
			</Group>
		</form>
	);
};

export default CreateCharacterModal;
