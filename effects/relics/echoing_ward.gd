extends Effect

func modified_incoming_status_duration(status_def: StatusDef, duration: float) -> float:
	if status_def.status_type == StatusDef.StatusType.WARD:
		return duration * 1.5
	return duration
