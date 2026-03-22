# PROJECT_RULES.md — Bodega Pro Cloud
# Reglas Técnicas Permanentes · A2K Digital Studio

> Este archivo define las reglas INAMOVIBLES del proyecto.
> Claude DEBE leerlo en cada sesión antes de modificar cualquier archivo.

---

## 🔴 REGLA #1 — IRON LOCK CLOUD: PRIORIDAD ABSOLUTA DE SEGURIDAD

El **Iron Lock Cloud** es el sistema de licencias con doble capa de verificación.
Es la **característica de seguridad más crítica de toda la aplicación**.

### Lo que NUNCA se puede hacer:
- Eliminar o cortocircuitar la verificación contra Firebase (`cloudGet('licencias', code)`)
- Eliminar el fallback de validación local
- Agregar cualquier bypass que permita acceso sin código válido
- Modificar la lógica de vencimiento de licencias DEMO
- Cambiar los códigos MASTER sin autorización explícita del dueño del proyecto
- Reducir el tiempo de demo (actualmente: **5 días fijos**)

### Flujo obligatorio (NO MODIFICAR):
```
Firebase FIRST → [activa? vencida?] → ACCESO o BLOQUEO
     ↓ (si Firebase falla/offline)
Local FALLBACK → [device registrado? master? emitida?] → ACCESO o BLOQUEO
     ↓ (si ninguno pasa)
BLOQUEO TOTAL → pantalla de activación
```

### Colección `licencias` en Firebase (estructura protegida):
```javascript
{
  activa: true/false,        // ← NUNCA ignorar este campo
  esDemo: true/false,
  venceEn: "ISO8601",        // ← NUNCA ignorar si esDemo === true
  negocio: "nombre",
  tipo: "DEMO" | "PRO",
  terminales: 1,
  creadaEn: "ISO8601"
}
```

---

## 🔴 REGLA #2 — CREDENCIALES FIREBASE: PROHIBIDO MODIFICAR

Las credenciales de Firebase están presentes en **4 archivos**:
- `index.html` (línea ~1215)
- `licencias.html` (línea ~491)
- `dashboard.html` (línea ~148)
- `cliente.html` (línea ~115)

### Credenciales activas (solo referencia — NO CAMBIAR):
```
Proyecto:   bodega-pro-cloud
apiKey:     AIzaSyCfAh2-K5oe1XPVFvB4jbN62nSOTFq22jo
authDomain: bodega-pro-cloud.firebaseapp.com
projectId:  bodega-pro-cloud
```

### Regla:
**NUNCA modificar ninguna de estas credenciales** sin autorización explícita del propietario.
Si se necesita migrar a un nuevo proyecto Firebase, el propietario debe indicarlo
explícitamente y se deben actualizar los 4 archivos simultáneamente.

---

## 🔴 REGLA #3 — DISEÑO CONSISTENTE CON LA VERSIÓN LOCAL (A2K Style)

Bodega Pro Cloud es la versión hermana de Bodega Pro 8.0 Local. El diseño visual
**debe ser idéntico o superior** al de la versión local, nunca inferior.

### Variables CSS del sistema A2K (NO MODIFICAR sin causa):
```css
--accent:   #7C3AED   (morado principal)
--accent2:  #6D28D9
--neon:     #06D6A0   (verde neón)
--neon2:    #059669
--danger:   #EF4444   (rojo)
--warn:     #F59E0B   (amarillo)
--success:  #10B981
--font:     'Inter'
--display:  'Syne'    (títulos)
--mono:     'JetBrains Mono' (código/valores)
```

### Reglas de diseño:
- **NO** simplificar el CSS para "aligerar" el archivo
- **NO** reemplazar el diseño oscuro por uno más simple
- **NO** eliminar animaciones, gradientes o efectos de glassmorphism
- **SÍ** puede agregarse CSS nuevo siempre que respete las variables existentes
- **SÍ** el tema claro (`[data-theme="light"]`) debe mantenerse funcional

---

## 🟡 REGLA #4 — SISTEMA DE MODALES: ESTÁNDAR DE CIERRE

Todos los modales deben poder cerrarse con la X **Y** con el botón Cancelar/Cerrar.

### CSS obligatorio para botones de cierre:
```css
/* Botón X */
.btn-close {
  z-index: 20000 !important;
  pointer-events: auto !important;
  position: relative;
}

/* Botones Cancelar/Cerrar en footer de modal */
.modal-footer .btn, .modal-footer button {
  z-index: 20000 !important;
  pointer-events: auto !important;
  position: relative;
}
```

### Función closeModal (estándar obligatorio):
```javascript
function closeModal(id) {
  var el = document.getElementById(id);
  if (el) { el.style.setProperty('display', 'none', 'important'); el.classList.remove('open'); }
}
```
**NUNCA** usar `el.style.display = 'none'` — siempre `setProperty` con `!important`.

### Listener global de cierre (debe estar en fase de captura):
```javascript
window.addEventListener('click', function(e) {
  var btn = e.target.closest('.btn-close, .modal-footer .btn, .modal-footer button');
  if (!btn) return;
  var overlay = btn.closest('.modal-overlay');
  if (overlay) { overlay.style.setProperty('display','none','important'); overlay.classList.remove('open'); }
}, true); // TRUE = captura, ignora stopPropagation
```

---

## 🟡 REGLA #5 — SINCRONIZACIÓN CLOUD: CICLO PROTEGIDO

El ciclo de sincronización con Firebase **no debe romperse**:

```
Acción del usuario (venta, guardar producto, etc.)
        ↓
Guardar en localStorage (DB.set)
        ↓
Llamar window.syncVentasCloud()
        ↓
cloudSave('negocios', negocio, { ...datos, _ts: serverTimestamp() })
        ↓
Firestore actualizado ✅
```

### Reglas:
- El auto-sync cada 5 minutos (`setInterval 300000ms`) **no debe eliminarse**
- Cada `procesarVenta()` exitosa DEBE llamar `syncVentasCloud()`
- Si se agrega un nuevo módulo de datos, DEBE incluirse en el objeto que envía `syncVentasCloud`
- **NUNCA** guardar datos sensibles (contraseñas, PINs) en Firestore

---

## 🟡 REGLA #6 — ARCHIVOS SATÉLITE: RESPONSABILIDADES SEPARADAS

| Archivo | Quién lo usa | Puede modificar Firebase |
|---|---|---|
| `index.html` | Bodeguero (usuario final) | Solo escribe en `negocios/` |
| `licencias.html` | A2K Studio (admin) | Lee/escribe en `licencias/` |
| `dashboard.html` | A2K Studio (admin) | Solo lee `negocios/` |
| `cliente.html` | Cliente del negocio | Solo lee `negocios/` |

**NUNCA** dar acceso de escritura a `licencias/` desde `index.html` o `cliente.html`.

---

## 🟢 REGLA #7 — PESO Y ESTRUCTURA

- `index.html` debe mantenerse en ~779 KB (~7800 líneas)
- **NO** eliminar CSS, funciones o módulos para reducir peso
- Si se agrega funcionalidad, el peso puede crecer — nunca reducirse por eliminación

---

## 🟢 REGLA #8 — LICENCIA DEMO = 5 DÍAS FIJOS

- Demo siempre dura **5 días exactos** desde la creación
- El selector de días debe estar **siempre deshabilitado** (`disabled`, `pointer-events:none`)
- **NUNCA** agregar un selector de 1-7 días ni cambiar la duración

---

## 🟢 REGLA #9 — DIFERENCIAS CLAVE CLOUD vs LOCAL

| Característica | Versión Local | Versión Cloud |
|---|---|---|
| Almacenamiento | localStorage | localStorage + Firestore |
| Verificación licencia | Solo local | Firebase FIRST + local fallback |
| Gestión licencias | Panel en Configuración | `licencias.html` separado |
| Vista admin | No existe | `dashboard.html` |
| Portal cliente | No existe | `cliente.html` |
| Sync automático | No | Cada 5 min + post-venta |
| Usuarios multi-turno | Básico | `modalUserPass`, `modalUsuario` |

---

## 📋 HISTORIAL DE CAMBIOS

| Fecha | Cambio | Archivos |
|---|---|---|
| 2026-03-20 | Creación de CLAUDE.md y PROJECT_RULES.md | CLAUDE.md, PROJECT_RULES.md |
| 2026-03-21 | Iron Lock: re-validación Firebase en auto-login | index.html |
| 2026-03-21 | closeModal con setProperty !important + listener global captura | index.html |
| 2026-03-21 | confirmarLogout: borra license+session, location.replace sin historial | index.html |
| 2026-03-21 | Dashboard statsGrid2: clase grid-3 normalizada | index.html |

---

## 📞 CONTACTO DEL PROYECTO

- **Desarrollador:** A2K Digital Studio
- **WhatsApp:** +58 416 411 7331
- **Email:** a2kdigitalstudio2025@gmail.com
- **Repo GitHub Cloud:** `tiendadigitalaipro/bodega-pro-cloud`
- **Repo GitHub Local:** `tiendadigitalaipro/bodega-pro-descarga.html`
- **Branch:** `main`
