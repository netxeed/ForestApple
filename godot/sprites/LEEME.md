# Sprites

El juego busca los PNG en `assets/` de la raíz del repositorio. No hace falta abrir el
importador de Godot: al iniciar, el cargador lee las imágenes del disco. En una versión
exportada, coloca la carpeta `assets/` junto al ejecutable.

## Animación direccional

Cada personaje puede tener una carpeta con su nombre en minúsculas y estos archivos:

```text
assets/
  Apple/
	apple_s_idle.png
	apple_s_1.png
	apple_s_2.png
	apple_n_idle.png
	apple_n_1.png
	apple_n_2.png
	apple_e_idle.png
	apple_e_1.png
	apple_e_2.png
	apple_w_idle.png
	apple_w_1.png
	apple_w_2.png
```

Se aceptan nombres de carpeta y archivo con mayúsculas o minúsculas. `w` significa oeste.
La manzana del jugador usa estos frames cuando están presentes; si falta una pose, usa
la pose idle correspondiente y después intenta una imagen única `<nombre>.png`.

Los personajes que no tengan frames direccionales también pueden usar una sola imagen:
`assets/Nombre/nombre.png`. Por ejemplo, la piña usa `assets/Pineapple/pineapple_s_idle.png`
como imagen estática si no hay `pineapple.png`.

Los PNG deben tener fondo transparente. El punto de apoyo es el centro de la imagen; el
tamaño visual es el tamaño original del archivo y no cambia el rectángulo de colisión.
Al agregar o reemplazar imágenes durante una ejecución, llama a `Sprites.clear_cache()`
o reinicia el juego.
