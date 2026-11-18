extends RefCounted # Declara la clase base o el nombre global de este script.
## Patrones comunes de proyectiles, equivalentes a entities/patterns.py.

const ProjectileScript = preload("res://scripts/entities/projectile.gd") # Define un dato, constante o propiedad usada por el script.


static func fan(origin: Vector2, target: Vector2, count: int, spread_deg: float, speed: float, damage: int, color: Color, size: int = 6, lifetime: float = 4.0) -> Array: # Declara una función y el punto de entrada de esta operación.
	var base := target - origin # Define un dato, constante o propiedad usada por el script.
	if base.length_squared() == 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		base = Vector2.RIGHT # Calcula y asigna el resultado al estado o dato indicado.
	var angles: Array[float] = [] # Define un dato, constante o propiedad usada por el script.
	if count == 1: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		angles.append(0.0) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var step := spread_deg / float(count - 1) # Define un dato, constante o propiedad usada por el script.
		for i in range(count): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			angles.append(-spread_deg / 2.0 + i * step) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var out: Array = [] # Define un dato, constante o propiedad usada por el script.
	for angle in angles: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		out.append(ProjectileScript.new(origin, base.rotated(deg_to_rad(angle)), speed, damage, color, size, lifetime)) # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	return out # Controla el flujo y selecciona el caso de ejecución correspondiente.


static func shot_at_angle(origin: Vector2, angle_deg: float, speed: float, damage: int, color: Color, size: int = 6, lifetime: float = 4.0): # Declara una función y el punto de entrada de esta operación.
	return ProjectileScript.new(origin, Vector2.RIGHT.rotated(deg_to_rad(angle_deg)), speed, damage, color, size, lifetime) # Controla el flujo y selecciona el caso de ejecución correspondiente.
