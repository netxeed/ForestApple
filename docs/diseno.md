# ForestApple — Documento de diseño

> Versión 0.3. Las secciones marcadas **[Decidido]** vienen del equipo.
> Las marcadas **[Propuesta]** son ideas para discutir: se aceptan, se cambian o se tiran.
> La historia se está redactando de nuevo, más completa y más larga; este documento
> sigue la versión corta vigente. Todo lo que falta resolver está en la sección
> **8. Preguntas abiertas**.

## 1. La historia [Decidido]

**Acto 1.** Una manzana convive con las demás frutas en un estante. Un día, sus
amigas manzanas son tiradas a la basura luego de pudrirse un poco. Eso la afecta
mucho: se siente angustiada y, en su preocupación, **asciende en términos de
conciencia** hasta concluir que el **cielo de las frutas** (adonde supuestamente
van las frutas comidas) **no existe**.

Mientras aprende a pensar, un niño la agarra y está a punto de comérsela, pero se
da cuenta de que es consciente: **ve sus ojos y entiende lo que dice**. El niño le da
la idea de **convertirse en un bosque**, lo que la tranquiliza un poco porque le
da un propósito en la vida. Forman una **alianza** para cumplirlo.

La manzana decide enfrentar a las frutas que creen en el cielo de las frutas y se
oponen a su idea de escapar y volverse un bosque. Ellas deciden acabar con la
manzana: empieza la **Guerra Civil de las Frutas**. *Fin del Acto 1.*

**Acto 2.** La manzana se enfrenta a todas las frutas mientras desciende por los
pisos (estantes): recoge ítems que la ayudan, resuelve puzzles y encuentra cosas
secretas. Tras derrotar al último jefe del último piso, conversa con el niño y se
prepara para pelear una última vez. *Fin del Acto 2.*

**Acto 3.** El niño, con el apoyo de la manzana, se enfrenta a **Juan, María y
Adán**, tres adultos que viven en la casa con él. Ganan y logran escapar. La
manzana es plantada y muere, pero cumple su propósito: su muerte da origen a un
gran bosque de manzanos que sigue produciendo manzanas hoy en día, en un lugar
desconocido. *Fin del tercer y último acto.*

**Tema central:** ¿es mejor dar la vida por otro (ser comido) o por algo que
continúa (pudrirse para dar vida)? Ninguna de las dos respuestas es gratis.
El propósito de la manzana es volverse un **bosque de manzanos** (no un solo
árbol): sacrificar todo su cuerpo y morir podrida para ser el sustrato perfecto,
lleno de nutrientes, que sus semillas necesitan.

## 2. Personajes

| Personaje | Rol | Estado |
|---|---|---|
| **Manzana** | Protagonista jugable. Sin nombre. La más inteligente de todas las manzanas. Callada y observadora; la pérdida de sus amigas la lleva a pensar. | Decidido |
| **El niño** | Aliado jugable. Su **nombre nunca se dice**; la manzana lo llama "niño". Puede ver sus ojos y entenderla cuando habla. Vive en una casa con Juan, María y Adán. | Decidido |
| **Gala, Aida e Isolde** | Amigas de la manzana (ver abajo). Sus textos están en `data/dialogues.json`. | Decidido |
| **Juan** | Hermano mayor del niño. Jefe final (con sus padres). | Decidido |
| **María y Adán** | Padres del niño. Jefes finales. | Decidido |
| **Las frutas** | Frutilla, piña, sandía, durazno, banana, limón. Enemigos de la guerra civil; creen en el cielo de las frutas. | Decidido |

Los adultos se ven **gigantes** para las frutas y el niño. Eso es también una
decisión visual: ellos nunca se ven enteros, solo manos, sombras, pies o partes
(**[Propuesta]**, ahorra arte y refuerza la escala).

### Las amigas del Acto 1

Son manzanas con nombres femeninos (porque "manzana" es una palabra femenina),
pero **su género es neutral y no importa para la historia**. En los textos conviene
evitar adjetivos que marquen género cuando hablan de sí mismas ("me da miedo" en
vez de "soy miedosa"). Aida e Isolde son más inteligentes que las demás manzanas,
aunque van detrás de la protagonista.

| Amiga | Cómo es | Qué siembra |
|---|---|---|
| **Gala** | Positiva siempre, no despreocupada: por eso dice "ojalá me coman pronto". Cree en el cielo de las frutas. | La fe en el cielo de las frutas. |
| **Aida** | Temerosa, algo tímida (no mucho); se lleva bien con sus amigas. Todas las noches piensa adónde irán y se lo confiesa a la protagonista. | Que la protagonista no es la única que se pregunta. |
| **Isolde** | Competente y razonable, con pensamiento crítico mayor al promedio, pero conformista y algo positiva como Gala (por eso se llevan mejor entre ellas que con Aida). | Lo que se pierde: la vida cotidiana. Y la idea de conformarse con una explicación razonable. |

**Rasgos [Propuesta]** (para ir dándoles vida; se aceptan, se cambian o se tiran):

| Amiga | Deseo | Gesto o manía | Defecto | Ante el hecho trágico |
|---|---|---|---|---|
| **Gala** | Que todos estén contentos. | Saluda a todo el mundo; tararea cuando está nerviosa. | No soporta la duda ajena y cambia de tema. | Es a quien más le duele: su fe se rompe o se vuelve más rígida. |
| **Aida** | Que le digan que no pasa nada. | Mira el borde del estante; baja la voz con lo importante. | Piensa tanto que a veces no actúa. | Se le confirma lo que temía; quizá no se sorprende. |
| **Isolde** | Que las cosas funcionen. | Acomoda el estante; corrige con cariño ("en realidad..."). | Prefiere una respuesta aceptable a una incómoda. | Busca una razón ("es el ciclo"); necesitar explicarlo es parte de su dolor. |

## 3. Estructura en tres actos [Decidido]

Cada acto tiene un estilo de juego distinto.

### Acto 1 — Introducción (estilo Undertale)
- Exploración libre, sin combate, como un RPG: se ve **un poco de la vida de la
  manzana**, se camina por los estantes y se **habla con otras frutas**.
- **Mini-tareas cortas** (nada extenso) hasta el **hecho trágico**: las amigas
  **envejecen un poco** y las **tiran a la basura**. De ahí sale la crisis.
- Las frutas expresan su fe en el cielo de las frutas (siembra el conflicto).
- El niño aparece **después** de la tragedia, cuando la manzana ya está pensando.
- Termina cuando la manzana encara a las frutas creyentes y estas deciden acabar
  con ella: empieza la guerra civil.

#### Esquema del Acto 1 [Propuesta]

Para que la pérdida duela, el Acto 1 tiene que hacer que **se quiera a las amigas**
antes de perderlas. Son pocas y distintas entre sí, y cada mini-tarea le muestra al
jugador a una de ellas (y a una fruta de otra especie) y siembra un tema.

**Momentos** (unas 6 a 7 pantallas y 15 a 20 minutos):

1. **Un día cualquiera.** Despertar en el estante, conocer el lugar y a las amigas. Se aprenden los controles caminando y hablando.
2. **Mini-tareas** (3 o 4, de pocos minutos cada una). Ayudar a Gala a animar a otra fruta, acompañar a Aida a ver algo que le da miedo, ayudar a Isolde a acomodar algo del estante, ayudar a una banana con un problema cotidiano. Cada una deja un rato de conversación sobre el cielo de las frutas.
3. **Un día de más calma que de costumbre.** Un cierre cálido (una charla entre las tres) justo antes del golpe.
4. **El hecho trágico.** Las amigas **envejecen un poco** (se arrugan, se ablandan) y las **tiran a la basura**. La escena es corta y se juega, no solo se lee.
5. **La crisis.** Un rato de exploración con los mismos lugares vacíos y las otras frutas actuando como si nada. La manzana toma conciencia y concluye que el cielo de las frutas no existe.
6. **El niño.** La agarra y está por comérsela; ve sus ojos y entiende que habla. Le propone volverse un bosque y forman la alianza.
7. **El enfrentamiento.** La manzana encara a las frutas creyentes, que deciden acabar con ella. Empieza la guerra civil y se abre el Acto 2.

**[Propuesta]** Que el envejecimiento se vea de a poco durante las mini-tareas (dos o tres versiones del sprite de cada amiga), así el golpe se siente anunciado y no de la nada. Pide algo más de arte, pero es poco.

### Acto 2 — La guerra civil (estilo Isaac)
- Es lo que ya está hecho: salas, puertas, enemigos, jefe por piso.
- Se **desciende por la heladera**, de estante en estante.
- Además de combate: **ítems, puzzles y cosas secretas** (todavía no hay puzzles ni secretos).
- El niño acompaña como **apoyo**: cura o hace de escudo/tanque.
- Cada piso del acto 2 tendrá **ítems/trinkets** que mejoran a la manzana. Se
  muestran con su sprite debajo del minimapa, como en *The Binding of Isaac*.
  El primer trinket es una llave consumible para entrar a la sala de la sandía;
  todavía no hay mejoras permanentes para la manzana.
- Al derrotar al jefe aparece un agujero en el centro de la sala. Al acercarse
  y pulsar `E`, la pantalla se oscurece y aparece un diálogo sin nombre que dice
  «La batalla continuará...». El piso 2 todavía no está hecho.
- Las frutas derrotadas mueren, pero la manzana **se lleva dos semillas de cada
  una** para plantarlas junto a ella al final.
- Antes de cada pelea importante puede haber un diálogo tipo Undertale
  (las frutas defienden sus creencias).
- Tras el último jefe del último piso, la manzana **conversa con el niño** y se
  prepara para una última pelea.

### Acto 3 — Batalla final (jugamos como el niño)
- El niño, con el apoyo de la manzana, pelea contra Juan, María y Adán.
- Ganan y escapan. La manzana es plantada, muere y de ella nace el gran bosque
  (final bonito; el bosque sigue dando manzanas y nadie sabe dónde está).

## 4. Mecánicas

### Ya decidido
- Controles: movimiento con WASD, disparo con flechas, una sala a la vez.
- El niño como apoyo: curación o escudo.
- Algunas frutas podrán volverse **ítems acompañantes** (como en Isaac) que
  disparan o curan. *(Futuro)*
- **Ruta pacifista**: convencer a la mayor cantidad de frutas posible. *(Futuro)*

### Propuestas
- **La vida como podredumbre:** en vez de corazones, el cuerpo de la manzana se
  ve cada vez más podrido a medida que recibe daño. Refuerza el tema.
- **Semillas como recurso:** las dos semillas por fruta derrotada se cuentan en
  pantalla y definen cómo luce el bosque del final.
- **Pisos por estante (ejemplo):** estante superior → estante medio → cajón de
  verduras → fondo. Cada piso con 5-6 salas y un jefe.

## 5. Acto 2: piso 1 y enemigos

El piso 1 es una grilla conectada de ocho salas: una inicial, seis normales y
la sala del jefe. Las puertas se cierran durante los combates y las salas
limpias permanecen limpias al volver. La sandía queda inaccesible hasta limpiar
todas las demás salas. Al completar la última, aparece una llave plateada
provisoria en el centro de esa sala. La manzana debe acercarse y pulsar `E` para
recogerla; luego se usa con `E` junto a la puerta de la sandía y desaparece al
abrirla. La puerta cerrada con llave se distingue por su color plateado. Al
derrotar a la sandía aparece el agujero de salida; al pulsar `E` junto a él se
oscurece la pantalla y aparece un diálogo sin nombre: «La batalla continuará...».
El descenso al piso 2 aún no está conectado.

El inventario de trinkets aparece debajo del minimapa y admite mostrar varios
iconos. Todo el acto 2 tendrá trinkets que mejoren a la manzana; por ahora la
llave de acceso es el único implementado y no otorga una mejora de combate.

### Enemigos

| Fruta | Comportamiento |
|---|---|
| **Frutilla** | Frágil, dispara semillas. *(Hecha)* |
| **Piña** | Tanque: mucha vida, lenta. |
| **Banana** | Guardia que ataca cuerpo a cuerpo. |
| **Durazno** | Rueda hacia el jugador. |
| **Limón** | Lanza ácido. |
| **Sandía** | Jefe del piso 1, tres fases. *(Hecha, sin balancear)* |

### Sandía (jefe del piso 1) [Implementada]

No pelea por odio sino por **fe**: quiere convencer a la manzana de que ser
comido lleva al cielo de las frutas. Las tres fases van de predicar, a perder la
paciencia, a ofrecerse a ser comida. Tiene cientos de semillas y la manzana se
lleva solo dos de ella: contraste que se puede usar en el final.

| Fase | Vida | Qué hace |
|---|---|---|
| 1 | 100 % a 66 % | Camina lento y escupe abanicos de 5 semillas. |
| 2 | 66 % a 33 % | Se sacude (aviso), rueda rebotando 3 veces y queda aturdida (doble daño). |
| 3 | 33 % a 0 % | Es más rápida; alterna abanicos y espirales y deja charcos de jugo que dañan. |

Entre fases se frena la pelea y habla (diálogo, hoy provisorio en
`data/dialogues.json`). Al morir dice sus últimas palabras y recién después
aparece el aviso de piso completado. Los números son provisorios.

## 6. Estado del demo

El primer demo se concentra en completar el piso 1 del acto 2: ocho salas,
cinco tipos de enemigos regulares, la sandía con tres fases, diálogos
provisorios, llave de acceso y salida visual hacia el piso 2. Hay movimiento,
disparo, minimapa, puertas, pausa y HUD. El balance, arte, música y diálogos
siguen siendo provisionales.

Acto 1, acto 3, más pisos y trinkets que den mejoras a la manzana siguen para
más adelante. El sistema muestra los trinkets y soporta la llave consumible; aún
no existen mejoras de combate.

Ya existen las piezas técnicas que usarán los tres actos: una **pila de estados**
(menú, opciones, partida, pausa, diálogo y game over), el **sistema de diálogo**
(hablante por línea, velocidad, pausas y saltos de renglón) y un prototipo de
**soporte para Android** con controles táctiles (sin probar en un teléfono). El
Acto 1 y el Acto 3 todavía no existen como juego; del Acto 1 hay solo textos
borrador en `data/dialogues.json`.

## 7. Implicaciones técnicas

- Cada acto se juega distinto, y por eso el juego usa **estados** (`states/`).
  Hoy hay estados de menú, opciones, partida (el combate del Acto 2), pausa,
  diálogo y game over. Faltan los de exploración del Acto 1 y de batalla final.
- El sistema de diálogo es clave: lo usan el Acto 1, las peleas del Acto 2 y el
  final. Ya está hecho (ver `README.md`); falta conectarlo a escenas del Acto 1.
- Los textos van en `data/` (JSON) para que quien escriba no toque código.
- El Acto 1 necesita **banderas de historia** (qué tareas se hicieron, con quién se habló) y NPCs con diálogos que cambian según eso. Hoy no existe.

### Motor: Python y Godot [Propuesta]

El prototipo actual está en Python (pygame) y no hay obligación de seguir con él.
El Acto 1 es un RPG de exploración (mapas, NPCs, zonas que disparan eventos,
cinemáticas), justo lo que más cuesta a mano y más resuelve un motor con editor.
Propuesta:

- Hacer en **Godot** un recorte pequeño del Acto 1 (una sala con dos NPCs y un
  diálogo) y decidir con eso en la mano. Si no convence, el prototipo en Python
  sigue intacto.
- No borrar el repositorio actual: queda como prototipo y referencia del Acto 2.
- Se conservan los diseños y los JSON (`rooms`, `enemies`, `dialogues`); lo que
  hay que reescribir es el código.
- Quien hace el arte puede trabajar directo en Godot (importar sprites, animar, armar
  mapas), y el soporte para Android pasa a ser el oficial.

Esto **no está decidido**: depende de probar el recorte.

## 8. Preguntas abiertas

Todo lo que el equipo todavía tiene que decidir. Cuando se resuelva una, se mueve
a su sección y se anota en el historial (sección 9).

### La historia y el Acto 1
1. ¿Qué ve la manzana del hecho trágico: **ve cómo tiran a sus amigas** o encuentra el estante vacío?
2. ¿Qué pasa entre que el niño la agarra y la suelta? Es el momento clave del acto: ¿se puede jugar? ¿Qué lo frena de comérsela?
3. ¿El niño se ve en **tamaño normal o en miniatura** (por su imaginación)? En la versión nueva la agarra con la mano, pero en el Acto 2 acompaña "en miniatura" como apoyo. ¿Cómo se explica?
4. ¿Las demás frutas **ven u oyen al niño**? (Los diálogos actuales asumen que no.)
5. ¿Por qué las frutas llegan a querer **matar** a la manzana? ¿Miedo, enojo, o creen que la ayudan?
6. ¿Qué relación tiene el niño con las frutas antes de conocer a la manzana?
7. ¿Gala, Aida e Isolde siguen presentes después de la tragedia (recuerdos, flashbacks) o solo viven en el Acto 1?
8. ¿Las mini-tareas se pueden hacer en cualquier orden?
9. ¿Qué tan largo es el Acto 1 en el MVP? (Propuesta: 15 a 20 minutos.)

### La familia del niño
10. ¿Por qué la familia es hostil con el niño? Alcanza con una línea sugerida en el
    Acto 1 ("nadie lo escucha porque se imagina cosas"), pero conviene fijarlo antes
    de escribir diálogos. ¿Y por qué lo persiguen o lo retienen en el Acto 3?

### Acto 2
11. ¿Qué tipos de **puzzles y secretos** hay? Todavía no existe ninguno.
12. ¿Cuántos pisos y qué jefe cierra cada uno? Hoy solo está el piso 1 (sandía).
13. ¿Qué pasa con las **semillas** llevadas de cada fruta en el final?

### Acto 3
14. ¿Cómo se juega la batalla final? Opciones: (a) el mismo estilo Isaac pero con el
    niño y sus propias reglas, (b) un jefe con tres fases, una por familiar, (c) algo
    más narrativo y menos de combate. Para el MVP conviene la (b) con el sistema que
    ya existe.
15. ¿Cómo **apoya la manzana** al niño en la pelea final?

### Técnicas
16. ¿Seguimos en Python o pasamos a Godot? (Depende del recorte de prueba.)

## 9. Historial de cambios

**v0.3** (la historia se redactó de nuevo; mañana se amplía)
- La historia vigente es la versión corta de la sección 1.
- Las amigas de la manzana (no su familia) son las que mueren: envejecen un poco y las tiran a la basura.
- **El niño aparece después de la tragedia**, no al comienzo: casi se come a la manzana, la entiende y le da la idea de volverse un bosque (antes la idea era de la manzana).
- El Acto 1 termina con la guerra civil ya declarada (antes terminaba con la alianza).
- Acto 2: se suman puzzles y cosas secretas; tras el último jefe, la manzana habla con el niño.
- Pendiente de ajustar: el diálogo `acto1_nino_llega` de `data/dialogues.json`, que todavía supone al niño al comienzo.
