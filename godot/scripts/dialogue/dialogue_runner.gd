class_name DialogueRunner # Declara la clase base o el nombre global de este script.
extends RefCounted # Declara la clase base o el nombre global de este script.
## Avance de un diálogo: efecto de escritura, pausas y paso de línea (equivale a dialogue/runner.py).
##
## No sabe dibujar: solo lleva la cuenta de qué línea es, cuántas letras se ven y cuánto falta
## de una pausa. La caja (dialogue_box.gd) lo dibuja y los tests lo recorren sin ventana.
## Recibe las líneas que arma `DialogueParser.build_lines`: [{text, pauses, speaker, speed}, ...].
## Si una línea no trae velocidad (o es <= 0) se usa `default_speed`.

const DEFAULT_SPEED := 45.0  # letras por segundo cuando ni el diálogo ni la línea piden otra

var lines: Array # Define un dato, constante o propiedad usada por el script.
var default_speed: float # Define un dato, constante o propiedad usada por el script.
var index := 0 # Define un dato, constante o propiedad usada por el script.
var active := false # Define un dato, constante o propiedad usada por el script.
var plain := "" # Define un dato, constante o propiedad usada por el script.
var speed := DEFAULT_SPEED # Define un dato, constante o propiedad usada por el script.
## Letras escritas hasta ahora (con decimales; las visibles son `shown_count`).
var shown := 0.0 # Define un dato, constante o propiedad usada por el script.

var _line: Dictionary = {} # Define un dato, constante o propiedad usada por el script.
var _pause_left := 0.0 # Define un dato, constante o propiedad usada por el script.
var _pending: Array = [] # Define un dato, constante o propiedad usada por el script.


func _init(dialogue_lines: Array, default_cps: float = DEFAULT_SPEED) -> void: # Declara una función y el punto de entrada de esta operación.
	lines = dialogue_lines # Calcula y asigna el resultado al estado o dato indicado.
	default_speed = default_cps # Calcula y asigna el resultado al estado o dato indicado.
	active = not lines.is_empty() # Calcula y asigna el resultado al estado o dato indicado.
	speed = default_cps # Calcula y asigna el resultado al estado o dato indicado.
	_load_line() # Ejecuta esta instrucción para implementar el comportamiento del bloque.


# ---------- línea actual ----------
func _load_line() -> void: # Declara una función y el punto de entrada de esta operación.
	shown = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	_pause_left = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
	_pending = [] # Calcula y asigna el resultado al estado o dato indicado.
	if active: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		_line = lines[index] # Calcula y asigna el resultado al estado o dato indicado.
		plain = _line["text"] # Calcula y asigna el resultado al estado o dato indicado.
		_pending = (_line["pauses"] as Array).duplicate(true) # Calcula y asigna el resultado al estado o dato indicado.
		var line_speed := float(_line.get("speed", 0.0)) # Define un dato, constante o propiedad usada por el script.
		speed = line_speed if line_speed > 0.0 else default_speed # Calcula y asigna el resultado al estado o dato indicado.


func speaker() -> String: # Declara una función y el punto de entrada de esta operación.
	return str(_line.get("speaker", "")) if active else "" # Controla el flujo y selecciona el caso de ejecución correspondiente.


## Cantidad de letras visibles ahora.
func shown_count() -> int: # Declara una función y el punto de entrada de esta operación.
	return mini(int(shown), plain.length()) if active else 0 # Controla el flujo y selecciona el caso de ejecución correspondiente.


func visible_text() -> String: # Declara una función y el punto de entrada de esta operación.
	return plain.substr(0, shown_count()) if active else "" # Controla el flujo y selecciona el caso de ejecución correspondiente.


func line_complete() -> bool: # Declara una función y el punto de entrada de esta operación.
	return not active or shown >= plain.length() # Controla el flujo y selecciona el caso de ejecución correspondiente.


## true mientras está en una pausa del texto.
func waiting() -> bool: # Declara una función y el punto de entrada de esta operación.
	return _pause_left > 0.0 # Controla el flujo y selecciona el caso de ejecución correspondiente.


# ---------- avance ----------
func update(dt: float) -> void: # Declara una función y el punto de entrada de esta operación.
	if not active or line_complete(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	var remaining := dt # Define un dato, constante o propiedad usada por el script.
	while remaining > 0.0 and not line_complete(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		if _pause_left > 0.0: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var used := minf(_pause_left, remaining) # Define un dato, constante o propiedad usada por el script.
			_pause_left -= used # Calcula y asigna el resultado al estado o dato indicado.
			remaining -= used # Calcula y asigna el resultado al estado o dato indicado.
			continue # Controla el flujo y selecciona el caso de ejecución correspondiente.
		var target := shown + speed * remaining # Define un dato, constante o propiedad usada por el script.
		if not _pending.is_empty() and target >= float(_pending[0][0]): # Controla el flujo y selecciona el caso de ejecución correspondiente.
			var pause: Array = _pending.pop_front() # Define un dato, constante o propiedad usada por el script.
			remaining -= maxf(0.0, (float(pause[0]) - shown) / speed) # Calcula y asigna el resultado al estado o dato indicado.
			shown = float(pause[0]) # Calcula y asigna el resultado al estado o dato indicado.
			_pause_left = float(pause[1]) # Calcula y asigna el resultado al estado o dato indicado.
		else: # Controla el flujo y selecciona el caso de ejecución correspondiente.
			shown = target # Calcula y asigna el resultado al estado o dato indicado.
			remaining = 0.0 # Calcula y asigna el resultado al estado o dato indicado.


## Primera pulsación: muestra la línea completa. Segunda: pasa a la siguiente.
func advance() -> void: # Declara una función y el punto de entrada de esta operación.
	if not active: # Controla el flujo y selecciona el caso de ejecución correspondiente.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	if not line_complete(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		shown = float(plain.length()) # Calcula y asigna el resultado al estado o dato indicado.
		_pause_left = 0.0 # Calcula y asigna el resultado al estado o dato indicado.
		_pending = [] # Calcula y asigna el resultado al estado o dato indicado.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	index += 1 # Calcula y asigna el resultado al estado o dato indicado.
	if index >= lines.size(): # Controla el flujo y selecciona el caso de ejecución correspondiente.
		active = false # Calcula y asigna el resultado al estado o dato indicado.
		return # Ejecuta esta instrucción para implementar el comportamiento del bloque.
	_load_line() # Ejecuta esta instrucción para implementar el comportamiento del bloque.
