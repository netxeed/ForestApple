extends RefCounted
## Geometría de la cancha del partido secreto (derivada de sideswipe_tuning.gd y la pantalla).

const S = preload("res://scripts/core/settings.gd")
const T = preload("res://scripts/states/sideswipe_tuning.gd")

const BALL_R := T.BALL_RADIUS
const CAR_SIZE := T.CAR_SIZE
const FIELD := Rect2(
	(S.SCREEN_W - T.FIELD_WIDTH) / 2.0 + T.FIELD_SIDE_INSET,
	(S.SCREEN_H - T.FIELD_HEIGHT) / 2.0 + T.FIELD_TOP_INSET,
	T.FIELD_WIDTH - 2.0 * T.FIELD_SIDE_INSET,
	T.FIELD_HEIGHT - T.FIELD_TOP_INSET - T.FIELD_BOTTOM_INSET
)
const GOAL_TOP := T.GOAL_TOP
const GOAL_BOTTOM := T.GOAL_TOP + T.GOAL_HEIGHT

const APPLE_START := Vector2(FIELD.position.x + FIELD.size.x * 0.24, FIELD.end.y - CAR_SIZE.y / 2.0 - 3.0)
const KID_START := Vector2(FIELD.end.x - FIELD.size.x * 0.24, FIELD.end.y - CAR_SIZE.y / 2.0 - 3.0)
