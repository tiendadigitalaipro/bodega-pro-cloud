# 🧠 CLAUDE.md — Agente Especialista: Bodega Pro Cloud (A2K Digital Studio)

> **Archivo de contexto del proyecto. Léelo ANTES de cualquier tarea.**
> Evita leer los ~851 KB de código en cada sesión.

---

## 🎯 ROL DEL AGENTE

Eres el **Agente Técnico Senior Cloud** de Bodega Pro Cloud, la versión online/sincronizada
de Bodega Pro 8.0, desarrollada por A2K Digital Studio. Este proyecto conecta cada bodega
con **Firebase Firestore** para sincronización en tiempo real, gestión centralizada de
licencias y un portal de cliente.

---

## ⚙️ ARQUITECTURA DEL PROYECTO

```
bodega-pro-cloud/
├── index.html        ← App POS Cloud principal (~779 KB, ~7800 líneas)
├── licencias.html    ← Panel Admin A2K: genera/gestiona licencias en Firebase (~40 KB, ~864 líneas)
├── dashboard.html    ← Dashboard A2K: vista de todos los negocios en tiempo real (~12 KB, ~256 líneas)
├── cliente.html      ← Portal Cliente: historial de compras y fiado propio (~19 KB, ~377 líneas)
├── README.md
├── CLAUDE.md         ← Este archivo
└── PROJECT_RULES.md  ← Reglas permanentes del proyecto
```

### Estructura interna de `index.html`

| Bloque | Líneas aprox. | Descripción |
|---|---|---|
| `<head>` + CSS global | 1 – 1200 | Variables CSS, estilos, responsive, temas claro/oscuro |
| Script Firebase (module) | 1210 – 1280 | initializeApp, cloudSave, cloudGet, onSnapshot, syncVentasCloud |
| Auto-sync interval | 1275 | `setInterval(syncVentasCloud, 300000)` — cada 5 minutos |
| HTML Login Screen | ~1320 – 1430 | `#loginScreen` con Iron Lock Cloud |
| HTML App `#app` | ~1430 – 1970 | sidebar, topbar, páginas |
| Modales estáticos | ~1973 – 2410 | modalProducto, modalCliente, modalUserPass, modalUsuario, modalCierreDiario, modalPinCliente, modalCobro, modalAdminPw |
| IRON LOCK Cloud JS | ~2480 – 3090 | Verifica Firebase PRIMERO, luego validación local como fallback |
| JS App principal | ~3090 – 7800 | POS, inventario, caja, clientes, reportes, proveedores, sync |

---

## 🔥 FIREBASE — CONFIGURACIÓN CENTRAL

### Proyecto
- **Nombre:** `bodega-pro-cloud`
- **SDK:** Firebase JS v10.7.1 (módulos ES via CDN gstatic)
- **Console:** https://console.firebase.google.com/project/bodega-pro-cloud

### Credenciales (NO MODIFICAR — ver PROJECT_RULES.md)
```javascript
const firebaseConfig = {
  apiKey:            "AIzaSyCfAh2-K5oe1XPVFvB4jbN62nSOTFq22jo",
  authDomain:        "bodega-pro-cloud.firebaseapp.com",
  projectId:         "bodega-pro-cloud",
  storageBucket:     "bodega-pro-cloud.firebasestorage.app",
  messagingSenderId: "245806066684",
  appId:             "1:245806066684:web:e45935a6bbe96c9a17a079"
};
```

### Colecciones Firestore

| Colección | Clave del documento | Contenido |
|---|---|---|
| `licencias` | `{CODIGO_LICENCIA}` | tipo, negocio, venceEn, activa, terminales |
| `negocios` | `{nombre_negocio}` | ventas[], inventario[], clientes[], pagos_clientes[], caja |
| `negocios` | `{negocio}_usuarios` | lista de usuarios del negocio |

### Funciones Cloud globales (definidas en `window`)

```javascript
// Guardar/actualizar documento en Firestore
window.cloudSave(col, id, datos) → Promise<boolean>

// Leer documento de Firestore
window.cloudGet(col, id) → Promise<object|null>

// Escuchar cambios en tiempo real
window.cloudListen(col, id, callback) → unsubscribe()

// Sincronizar todas las ventas/datos del negocio actual
window.syncVentasCloud() → Promise<void>
// AUTO-SYNC: se ejecuta cada 5 minutos automáticamente
// TRIGGER: también se llama tras cada venta procesada y al guardar usuarios
```

---

## 🔒 IRON LOCK CLOUD — FLUJO DE VERIFICACIÓN (BLINDADO)

El Iron Lock Cloud tiene **3 capas de verificación**:

```
0️⃣ CSS INJECT en <head>: #app{display:none!important} — antes del DOM

1️⃣ LOGIN (doLogin): Firebase FIRST → cloudGet('licencias', code)
   ├── activa === false → BLOQUEO
   ├── vencida → BLOQUEO
   └── válida → guarda session + startApp()

2️⃣ AUTO-LOGIN al recargar: RE-VALIDA Firebase antes de startApp()
   ├── Sin sesión guardada → muestra loginScreen
   ├── Con sesión → cloudGet('licencias', code) async
   │   ├── inactiva/vencida → borra session+license, muestra login
   │   └── válida (o Firebase offline) → startApp()
   └── Sin cloudGet disponible → startApp() con licencia local

3️⃣ FALLBACK LOCAL (offline):
   ├── Verifica localStorage (device registrado)
   ├── Verifica códigos MASTER
   └── Verifica licenses_issued locales
```

### confirmarLogout (blindado)
```javascript
function confirmarLogout() {
  closeModal('modalLogout');
  DB.del('session'); DB.del('license');
  // Oculta app de inmediato (sin flash)
  document.getElementById('app').style.setProperty('display','none','important');
  document.getElementById('loginScreen').style.setProperty('display','flex','important');
  location.replace(location.href.split('?')[0]); // sin historial — back-button no regresa
}
```

**Códigos MASTER internos:** `BPRO-DEMO-2024`, `BPRO-ABIG-2024`, `BPRO-ZYNC-2024`
**Demo = 5 días fijos:** `vd.setDate(vd.getDate() + 5)` — NO cambiar

---

## 🪟 SISTEMA DE MODALES

### Z-Index Stack actual
```
z-index: 99999  → #modalAdminPw
z-index: 9000   → #modalUserPicker
z-index: 8000   → #payGatewayOverlay
z-index: 1000   → .modal-overlay
z-index: 200    → .sidebar (mobile)
z-index: 100    → sidebar desktop
z-index: 50     → topbar
```

### Modales estáticos (en HTML)
| ID | Propósito |
|---|---|
| `#modalProducto` | Nuevo/editar producto |
| `#modalCliente` | Nuevo/editar cliente |
| `#modalUserPass` | Cambio de contraseña de usuario |
| `#modalUsuario` | Crear/editar usuario del sistema |
| `#modalCierreDiario` | Cierre diario de caja |
| `#modalPinCliente` | PIN de acceso cliente |
| `#modalCobro` | Confirmar cobro POS |
| `#modalAdminPw` | Contraseña administrador (z-index: 99999) |

### Modales dinámicos (creados con JS)
| ID | Función que lo crea |
|---|---|
| `#modalLogout` | `logout()` |
| `#modalAjusteStock` | `adjustStock()` |
| `#modalProveedor` | funciones de proveedores |
| `#modalDeudaProv` | funciones de proveedores |
| `#modalPagoProv` | funciones de proveedores |

### Z-Index Stack BLINDADO (actualizado)
```
z-index: 99999  → #modalAdminPw
z-index: 20000  → .btn-close, .modal-footer .btn (SIEMPRE encima de todo)
z-index: 10001  → .modal-overlay
z-index: 9000   → #modalUserPicker
z-index: 8000   → #payGatewayOverlay
z-index: 200    → .sidebar (mobile)
z-index: 100    → sidebar desktop
z-index: 50     → topbar
```

### CSS Anti-bloqueo (línea ~884)
```css
.btn-close { z-index:20000!important; pointer-events:auto!important }
.modal-footer .btn, .modal-footer button { z-index:20000!important; pointer-events:auto!important }
```

### closeModal (línea ~3841 y ~5718)
```javascript
function closeModal(id) {
  var el = document.getElementById(id);
  if (!el) return;
  el.style.setProperty('display', 'none', 'important');
  el.classList.remove('open');
}
```

### Listener Global Captura (línea ~3847)
```javascript
window.addEventListener('click', function(e) {
  var btn = e.target.closest('.btn-close');
  if (!btn) return;
  var overlay = btn.closest('.modal-overlay');
  if (overlay) { overlay.style.setProperty('display','none','important'); overlay.classList.remove('open'); return; }
  // fallback: subir parentNode
}, true); // true = fase de CAPTURA (ignora stopPropagation)
```

---

## 📱 PÁGINAS DE LA APP

| ID | Módulo |
|---|---|
| `#page-dashboard` | Dashboard / Resumen del día |
| `#page-pos` | Punto de Venta (POS) |
| `#page-inventario` | Inventario de productos |
| `#page-historial` | Historial de ventas |
| `#page-caja` | Gestión de caja |
| `#page-clientes` | Clientes y fiados |
| `#page-reportes` | Reportes y análisis |
| `#page-proveedores` | Proveedores y deudas |
| `#page-configuracion` | Configuración general |

---

## 🗂️ ARCHIVOS SATÉLITE

### `licencias.html` — Panel Admin A2K (~864 líneas)
- Acceso con contraseña admin (protegido)
- Funciones: `generarDemo()`, `generarPro()`, `cargarLicencias()`
- Lee/escribe en colección `licencias` de Firestore
- Genera códigos: `BPDEMO-XXXXXX` (demo) y `BPRO-XXXX-XXXX-XXXX` (pro)
- Permite activar/desactivar/eliminar licencias desde Firebase

### `dashboard.html` — Dashboard A2K (~256 líneas)
- Vista en tiempo real de todos los negocios conectados
- Lee colección `negocios` con `onSnapshot`
- Funciones: `doLogin()`, `cargar()`, `escuchar()`, `render(locales)`

### `cliente.html` — Portal Cliente (~377 líneas)
- Los clientes ven su propio historial de compras y saldo fiado
- Acceso: nombre del negocio + nombre del cliente + PIN
- Funciones: `accederCliente()`, `renderDashboardCliente()`, `renderDashboardAdmin()`
- Lee colección `negocios/{negocio}` en Firestore

---

## 🔑 FUNCIONES CLAVE (referencia rápida)

| Función | Línea aprox. | Descripción |
|---|---|---|
| `doLogin()` | ~2796 | Login con verificación Firebase + local |
| `showPage(page, el)` | ~3091 | Navega entre páginas |
| `closeModal(id)` | ~3750 | Cierra modal por ID |
| `procesarVenta()` | ~3424 | Procesa venta y llama syncVentasCloud |
| `renderInventario()` | ~3774 | Renderiza inventario |
| `syncVentasCloud()` | ~1241 | Sincroniza datos a Firebase |
| `abrirCaja()` | ~JS | Apertura de caja |
| `cerrarCaja()` | ~JS | Cierre de caja |

---

## 📤 REPOSITORIO GITHUB

- **Repo:** `tiendadigitalaipro/bodega-pro-cloud`
- **URL:** `https://github.com/tiendadigitalaipro/bodega-pro-cloud`
- **Branch activo:** `main` (también existe `master`)
- **Ruta local:** `C:\Users\ASUS\Downloads\bodega-pro-cloud-repo\`

Para subir cambios:
```bash
cd "C:\Users\ASUS\Downloads\bodega-pro-cloud-repo"
git add <archivo>
git commit -m "descripción"
git push origin main
```

---

## ⚠️ INSTRUCCIONES PARA CLAUDE EN FUTURAS SESIONES

1. **Lee CLAUDE.md y PROJECT_RULES.md PRIMERO** antes de tocar cualquier archivo.
2. **Nunca modificar las credenciales de Firebase** — están en 4 archivos, ver PROJECT_RULES.md.
3. **El Iron Lock Cloud es prioridad #1** — nunca alterar su lógica de verificación.
4. **Para editar:** usa `Read` solo en el rango de líneas relevante.
5. **Después de editar:** `git push origin main` directo, sin pedir confirmación de pegado.
6. **Sync Cloud:** cualquier cambio en ventas/inventario debe respetar el ciclo `cloudSave → syncVentasCloud`.

---

*Generado automáticamente por Claude — Bodega Pro Cloud · A2K Digital Studio · 2026*
