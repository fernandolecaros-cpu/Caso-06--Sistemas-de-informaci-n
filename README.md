[README.md](https://github.com/user-attachments/files/29152913/README.md)
# 🚴 RutaSmart

Aplicación web de **optimización de rutas de reparto** para el Caso 06 *"Rutas
Enredadas"* del curso de Sistemas de Información.

Matías reparte almuerzos caseros en bicicleta y organizaba 30–50 pedidos diarios a
mano. RutaSmart recibe los pedidos, los agrupa por zona, calcula la ruta más corta y
muestra un panel que responde las tres preguntas clave del negocio.

---

## ✨ Funcionalidades

- **Hacer pedido** — el cliente elige del menú, arma su carrito y envía el pedido.
- **Ruta de hoy** — lista ordenada de entregas (agrupadas por zona, ordenadas por
  cercanía); Matías marca cada entrega y ve el avance.
- **Panel** — KPIs del día + 3 gráficos que responden:
  1. ¿Cuántos pedidos hoy y en qué orden entregar?
  2. ¿Qué zonas generan más pedidos?
  3. ¿A qué hora hay más demanda y cuántos pedidos por semana?

## 🧱 Stack tecnológico

| Capa | Tecnología | Por qué |
|------|------------|---------|
| Frontend | HTML + CSS + JavaScript (vanilla, SPA) | Sin framework: liviano y fácil de servir. Basado en el prototipo de Stitch. |
| Backend | Node.js + Express | API REST simple y estándar. |
| Base de datos | SQLite vía `node:sqlite` (módulo nativo de Node ≥ 22.5) | Relacional, sin servidor aparte y **sin compilar binarios nativos**. |
| Optimizador | Algoritmo propio (agrupación por zona + vecino más cercano con distancia haversine) | Resuelve el orden de entrega. |

> Se eligió `node:sqlite` (integrado en Node) en lugar de `better-sqlite3` para que el
> proyecto se ejecute con solo `npm install` sin compilación nativa.

## 📁 Estructura del repositorio

```
rutasmart/
├── db/
│   ├── schema.sql        # DDL: tablas, índices y vistas
│   └── seed.sql          # DML: datos de prueba
├── backend/
│   ├── server.js         # API REST + servidor de la SPA
│   ├── db.js             # conexión e inicialización de la BD
│   ├── optimizer.js      # algoritmo de optimización de ruta
│   ├── package.json
│   └── .env.example
├── frontend/
│   ├── index.html
│   ├── styles.css
│   └── app.js            # consume la API REST
└── docs/
    ├── especificacion_sistema.md
    ├── modelo_datos.md
    └── bitacora_prompts.md
```

## ▶️ Cómo ejecutarlo

Requisitos: **Node.js ≥ 22.5** (incluye el módulo `node:sqlite`).

```bash
cd backend
npm install
npm start
```

Luego abrir **http://localhost:3000** en el navegador. En el primer arranque la base
de datos se crea automáticamente desde `schema.sql` + `seed.sql`.

Para reiniciar la base con datos frescos: borra `backend/rutasmart.db` y vuelve a
iniciar.

## 🔌 API REST

| Método | Endpoint | Descripción |
|--------|----------|-------------|
| GET | `/api/health` | Estado del servidor |
| GET | `/api/zonas` | Lista de zonas |
| GET | `/api/productos` | Menú de productos |
| GET | `/api/clientes` | Clientes (id, nombre, zona) |
| GET | `/api/pedidos?fecha=YYYY-MM-DD` | Pedidos de una fecha, con su detalle |
| POST | `/api/pedidos` | Crea un pedido (transaccional) |
| PATCH | `/api/pedidos/:id/estado` | Cambia el estado de un pedido |
| GET | `/api/ruta/hoy` | Ruta optimizada del día |
| GET | `/api/dashboard` | KPIs + datos de los 3 gráficos |

## 🚀 Despliegue (Taller 03 — GitHub + Render)

1. Subir el repositorio a GitHub.
2. En Render, crear un **Web Service** apuntando al repo.
3. Configurar:
   - **Root Directory:** `backend`
   - **Build Command:** `npm install`
   - **Start Command:** `npm start`
   - El puerto se toma de la variable de entorno `PORT` (ver `.env.example`).

## 📦 Fases del proyecto

- **Fase 1 — Descubrimiento y prototipado** (NotebookLM + Stitch): prototipo visual.
- **Fase 2 — Construcción** (este repositorio): BD, backend, frontend y optimizador.
- **Fase 3 — Despliegue** (GitHub + Render): publicación en línea.
