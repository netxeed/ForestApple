# ForestApple en Godot

El juego Godot migra el piso 1 completo del prototipo pygame: menú, opciones, partida, siete salas
previas al jefe, llave, combate contra enemigos y sandía, diálogo final, agujero y game over. La escena
principal es `game.tscn`. `main.tscn` conserva la demostración antigua de Gala y Aida; se abre aparte
con *Ejecutar escena actual* (F6).

## Controles

- Escritorio: WASD para moverse, flechas para disparar, E para interactuar y Esc para pausar.
- Android: flechas o joystick en cada lado, más botones de interactuar y pausa. Las opciones de móvil
  permiten cambiar modo, recorrido de base y tamaño del joystick.
- `K` limpia la sala y `R` reinicia cuando el modo debug está activo.

El cálculo táctil se compara con valores dorados, pero la respuesta de pantalla, gestos y diálogo aún
necesita una pasada en un teléfono Android real. La carpeta `sprites/` admite PNG de 32×32; este
checkout no incluye sprites de personajes, así que el juego dibuja figuras de respaldo.

## Datos y pruebas

`../data/` sigue siendo la fuente de Python. `godot/data/` contiene una copia idéntica para empaquetar
el juego; `test_data_paths.gd` comprueba que ambas coincidan. El arte de portada se empaqueta en
`assets/icon.png`.

Con Godot 4.7.2 instalado, desde la raíz del repositorio:

```sh
godot --headless --editor --path godot --quit
godot --headless --path godot --script res://tests/run_tests.gd
godot --headless --path godot --script res://tests/smoke_room_draw.gd
python tools/export_golden.py --check
python -m unittest discover -s tests -v
```

`tools/export_golden.py` genera los JSON de referencia desde el prototipo. La CI corre los tests de
Python y Godot en cada pull request. El código Python sigue en la raíz y no se archiva hasta terminar
el checklist manual de `docs/migracion-godot.md`, incluida la prueba en Android.
