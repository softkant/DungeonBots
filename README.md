# DungeonBots — Asistente Táctico de Bots para Mazmorras (WoW 3.3.5a)

**DungeonBots** es un addon ligero y elegante para World of Warcraft 3.3.5a (Wrath of the Lich King) diseñado específicamente para que los **jugadores casuales** puedan invocar, configurar y dirigir bots de mazmorra sin tener que memorizar ni tipear decenas de comandos por chat.

---

## Características Principales

### 1. Gestión e Historial de Bots (Party Builder)
* **Historial de bots:** Registra automáticamente cada bot que se une a tu grupo junto con su clase, retrato y última especialización asignada. Al pulsar `[ Ver Historial de bots ]` se abre un diálogo con la lista completa para llamarlos e invitarlos uno por uno (`.playerbots bot add <nombre>` + invitación automática).
* **Invocador por Clases:** 10 botones visuales con icono y color de clase para invocar a cualquier bot individual (`.playerbots bot addclass [clase]`).
* **Auto-Invite Inteligente:** Cuando un bot recién creado susurra al jugador ("Hello", "Ready", etc.), el addon lo detecta y le envía automáticamente la invitación al grupo.
* **Control Global y Utilidades:**
  * `[ Reinvocar Grupo ]`: Ejecuta `.playerbots bot add *` y los teletransporta a tu posición (solo para bots que siguen en tu grupo pero se ausentaron por relogueo o tras pasar el minuto fuera de mazmorra).
  * `[ Despedir a Todos ]`: Ejecuta `.playerbots bot remove *` para guardar y retirar a los bots, y los saca automáticamente del grupo (preservando amigos humanos).
  * `[ Reparar Equipo ]`: Ordena a todos los bots reparar su equipo junto a un comerciante o montura (`/p repair`).
  * `[ Liberar alma ]`: Fuerza a los bots muertos a liberar espíritu (`/p release`; ten en cuenta que el bot se quedará en el cementerio).

---

### 2. Bots en el grupo (X) — Talentos, Roles y Equipo
Muestra una tarjeta táctica para cada uno de los miembros del grupo:
* **Identificación Automática y Manual (`¿Quién es bot?`):** Distingue entre bots (`[ BOT ]`) y jugadores reales (`[ JUGADOR ]`) enviando una consulta discreta a los miembros sin verificar, o alternando el estado con un clic si juegas con amigos humanos para no enviarles órdenes por error.
* **Retratos con Raza y Género:** Muestra el icono oficial del rostro del bot según su raza y sexo (Orco, Elfo de Sangre, Humano, No-muerto, etc.) en lugar del signo de pregunta genérico.
* **Menú Desplegable Dinámico de Ramas (Specs):** 
  * Cada vez que un bot entra al grupo, el addon le consulta automáticamente en vivo su lista de ramas (`talents spec list`) y sus talentos actuales (`talents`) para mostrar datos reales del servidor y no depender solo del historial.
  * Al pulsar `[ Ver Ramas ]`, el addon vuelve a consultar `talents spec list` / `talents` y abre inmediatamente el menú desplegable para elegir una especialización.
  * Las ramas oficiales enviadas por el servidor se guardan y se seleccionan automáticamente al hacer clic en ellas.
* **Gestión de Equipo Segura:**
  * **Adaptar Equipo (`autogear match`):** Ajusta su armadura a la rama activa (con tooltip de advertencia sobre la reducción de Item Level).
  * **Equipar Azul (`autogear blue`):** Le otorga un conjunto de equipo azul balanceado.
* **Despido Individual:** Botón `[ Despedir ]` para retirar del mundo a un bot concreto y sacarlo del grupo.

---

### 3. Asistente de ICC: Dalaran, Forja, Foso y Cámaras
Resuelve el problema del límite de 60 segundos en Dalaran y la cadena de misiones para acceder a Foso de Saron y Cámaras de Reflexión:
1. **Temporizador Visual de Dalaran (60s):** Barra de cuenta regresiva en tiempo real (verde -> amarillo -> rojo) con aviso sonoro cuando quedan 15 segundos.
2. **Paso 1 (Dalaran):** Selecciona al PNJ de la misión y pulsa `[ 1. ¡Traer Bots y Aceptar Misión de Dalaran! ]` (ejecuta `/p summon` y `/p accept *` e inicia el cronómetro).
3. **Paso 2 (Entrada a Forja):** Cruza el portal de la mazmorra y pulsa `[ 2. ¡Reinvocar Grupo en Mazmorra! ]` (ejecuta `.playerbots bot add *` y `/p summon`).
4. **Paso 3 (Entregar y Continuar):** Selecciona al PNJ dentro de la mazmorra y pulsa `[ 3. Entregar y Aceptar Siguiente ]` (ejecuta `/p accept *` para entregar y tomar la siguiente).

---

### 4. Barra Táctica Flotante (Combat HUD)
Una barra compacta, arrastrable y bloqueable en pantalla que por defecto aparece automáticamente solo dentro de **mazmorras de 5 jugadores** (configurable en `Armar Grupo`), con botones de acción rápida para combate:
1. **Focus Target (`do attack my target`):** Fuerza a todos los bots a cambiar de objetivo de inmediato hacia tu enemigo seleccionado.
2. **Pull con Tanque (`pull my target`):** Ordena al tanque iniciar el combate con disparo a distancia, taunt o lanzamiento heroico.
3. **Quedarse (`stay`):** Frena a los bots en seco para evitar patrullas o colocarlos antes de un jefe.
4. **Seguir (`follow`):** Reanuda el seguimiento normal tras de ti.
5. **Summon (`summon`):** Rescata a bots atascados en texturas, puertas o escaleras.
6. **¡HUIR! (`flee`):** Botón de pánico que aborta el combate y hace que los bots corran hacia ti para salvar un wipe.
7. **Descansar (`drink`):** Pide a los curadores y casters beber maná y comer vida antes del siguiente pull.

---

## Accesos Directos y Comandos

* **El Ojo de Mazmorras (Minimapa y Buscador LFD):**
  * **Botón flotante del Minimapa:**
    * **Clic Izquierdo:** Abrir / Cerrar el panel principal de DungeonBots.
    * **Clic Derecho:** Mostrar / Ocultar la barra táctica flotante (HUD).
    * **Arrastrar:** Mover el icono alrededor del minimapa.
  * **LFDMicroButton (Ojo del menú inferior):** Clic derecho abre DungeonBots.
  * **LFDParentFrame (Ventana de Buscar Grupo 'I'):** Botón directo `[ DungeonBots ]` integrado en la esquina superior derecha.
* **Comandos de Chat:**
  * `/db` o `/bots`: Abre o cierra la ventana principal.
  * `/db hud`: Muestra u oculta la barra flotante de combate.
  * `/db dalaran`: Dispara la macro de preparación de Dalaran al instante.
  * `/db addall`: Reinvoca a todos los bots del grupo (`.playerbots bot add *`).
  * `/db dismiss`: Despide a todos los bots del grupo (`.playerbots bot remove *`).
  * `/db reset`: Restaura la posición del HUD al centro inferior de la pantalla.
