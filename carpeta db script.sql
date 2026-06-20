-- =========================
-- TABLA CLIENTES
-- =========================
DROP TABLE IF EXISTS notificaciones;
DROP TABLE IF EXISTS detalle_pedidos;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS sesiones;
DROP TABLE IF EXISTS repartidores;
DROP TABLE IF EXISTS clientes;

CREATE TABLE clientes (
  id_cliente INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  correo TEXT UNIQUE NOT NULL,
  contraseña_hash TEXT NOT NULL,
  foto_url TEXT
);

INSERT INTO clientes (nombre, correo, contraseña_hash, foto_url)
VALUES ('Julián Cortés', 'julian.cortes@example.com', 'hash12345', 'https://example.com/fotos/julian.jpg');

-- =========================
-- TABLA REPARTIDORES
-- =========================
CREATE TABLE repartidores (
  id_repartidor INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre TEXT NOT NULL,
  correo TEXT UNIQUE NOT NULL,
  contraseña_hash TEXT NOT NULL
);

INSERT INTO repartidores (nombre, correo, contraseña_hash)
VALUES ('Matías González', 'matias.gonzalez@example.com', 'hash67890');

-- =========================
-- TABLA SESIONES
-- =========================
CREATE TABLE sesiones (
  id_sesion INTEGER PRIMARY KEY AUTOINCREMENT,
  id_cliente INTEGER,
  id_repartidor INTEGER,
  token_sesion TEXT UNIQUE NOT NULL,
  fecha_inicio DATETIME DEFAULT CURRENT_TIMESTAMP,
  fecha_cierre DATETIME,
  FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_repartidor) REFERENCES repartidores(id_repartidor)
);

INSERT INTO sesiones (id_cliente, token_sesion)
VALUES (1, 'token_cliente_ABC123');

-- =========================
-- TABLA PEDIDOS
-- =========================
CREATE TABLE pedidos (
  id_pedido INTEGER PRIMARY KEY AUTOINCREMENT,
  id_cliente INTEGER NOT NULL,
  id_repartidor INTEGER,
  fecha DATE NOT NULL,
  hora TIME NOT NULL,
  estado TEXT CHECK (
    estado IN (
      'pendiente',
      'preparacion',
      'entregado_repartidor',
      'en_camino',
      'entregado'
    )
  ),
  total INTEGER,
  FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
  FOREIGN KEY (id_repartidor) REFERENCES repartidores(id_repartidor)
);

INSERT INTO pedidos (id_cliente, fecha, hora, estado, total)
VALUES (1, '2026-06-19', '12:30', 'preparacion', 8500);

-- =========================
-- TABLA DETALLE PEDIDOS
-- =========================
CREATE TABLE detalle_pedidos (
  id_detalle INTEGER PRIMARY KEY AUTOINCREMENT,
  id_pedido INTEGER NOT NULL,
  producto TEXT NOT NULL,
  cantidad INTEGER NOT NULL,
  precio_unitario INTEGER NOT NULL,
  FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
);

INSERT INTO detalle_pedidos (id_pedido, producto, cantidad, precio_unitario)
VALUES (1, 'Completo', 2, 3500);

INSERT INTO detalle_pedidos (id_pedido, producto, cantidad, precio_unitario)
VALUES (1, 'Bebida', 1, 1500);

-- =========================
-- TABLA NOTIFICACIONES
-- =========================
CREATE TABLE notificaciones (
  id_notificacion INTEGER PRIMARY KEY AUTOINCREMENT,
  id_pedido INTEGER NOT NULL,
  mensaje TEXT NOT NULL,
  fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (id_pedido) REFERENCES pedidos(id_pedido)
);

INSERT INTO notificaciones (id_pedido, mensaje)
VALUES (1, 'Tu pedido ha sido recibido.');

INSERT INTO notificaciones (id_pedido, mensaje)
VALUES (1, 'Tu pedido está siendo preparado.');
