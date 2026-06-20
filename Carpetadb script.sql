-- =====================================================================
-- RutaSmart | Script de estructura de base de datos y datos de prueba
-- Motor: SQLite 3 (compatible con node:sqlite / better-sqlite3)
-- Generado a partir del modelo de datos real de la app (Stitch + AI Studio)
-- Carpeta: /db
-- =====================================================================

PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- 1. LIMPIEZA (orden inverso a las dependencias por FK)
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS seguimiento;
DROP TABLE IF EXISTS notificaciones;
DROP TABLE IF EXISTS detalle_pedidos;
DROP TABLE IF EXISTS pedidos;
DROP TABLE IF EXISTS sesiones;
DROP TABLE IF EXISTS repartidores;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS categorias;

-- ---------------------------------------------------------------------
-- 2. ESTRUCTURA DE LA BASE DE DATOS
-- ---------------------------------------------------------------------

-- Categorías del menú (Platos del día, Vegetarianos, Bebidas)
CREATE TABLE categorias (
    id      INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre  TEXT NOT NULL UNIQUE
);

-- Productos / platos disponibles en el menú
CREATE TABLE productos (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre        TEXT NOT NULL,
    descripcion   TEXT,
    precio        REAL NOT NULL CHECK (precio >= 0),
    imagen_url    TEXT,
    categoria_id  INTEGER,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id) ON DELETE SET NULL
);

-- Clientes de la app (rol "Cliente")
CREATE TABLE clientes (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    id_cliente        INTEGER,                 -- alias histórico de id, usado por la app
    nombre            TEXT NOT NULL,
    email             TEXT UNIQUE,
    correo            TEXT UNIQUE,              -- duplicado de email usado en login
    contraseña_hash   TEXT NOT NULL DEFAULT '1234',
    foto_url          TEXT,
    telefono          TEXT,
    nivel             TEXT DEFAULT 'Nivel Básico',   -- Nivel Básico | Miembro VIP | Nivel Élite
    zona              TEXT
);

-- Sesiones de login de clientes
CREATE TABLE sesiones (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    id_cliente     INTEGER NOT NULL,
    token_sesion   TEXT NOT NULL UNIQUE,
    fecha_inicio   TEXT NOT NULL,
    fecha_cierre   TEXT,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id) ON DELETE CASCADE
);

-- Repartidores (rol "Repartidor")
CREATE TABLE repartidores (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre        TEXT NOT NULL,
    email         TEXT UNIQUE,
    vehiculo      TEXT,             -- Bicicleta | Moto | Auto
    comuna        TEXT,
    pedidos       INTEGER DEFAULT 0,
    km            REAL DEFAULT 0,
    calificacion  REAL DEFAULT 0 CHECK (calificacion BETWEEN 0 AND 5)
);

-- Pedidos realizados
CREATE TABLE pedidos (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    tracking_number  TEXT NOT NULL UNIQUE,
    cliente_id       INTEGER,
    repartidor_id    INTEGER,
    estado           TEXT NOT NULL CHECK (estado IN (
                        'RECIBIDO', 'CONFIRMADO', 'PREPARANDO', 'ASIGNADO',
                        'MATIAS_ACEPTO', 'EN_CAMINO', 'PROXIMO_5_MIN',
                        'ENTREGADO', 'PENDIENTE', 'EN_RUTA'
                     )),
    zona             TEXT,
    direccion        TEXT,
    ref_direccion    TEXT,
    subtotal         REAL NOT NULL DEFAULT 0,
    costo_envio      REAL NOT NULL DEFAULT 0,
    total            REAL NOT NULL DEFAULT 0,
    fecha            TEXT NOT NULL,
    hora             TEXT,
    metodo_pago      TEXT,          -- Transbank / Débito | Sodexo / Junaeb | Pagar con Efectivo | Crédito Webpay
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE SET NULL,
    FOREIGN KEY (repartidor_id) REFERENCES repartidores(id) ON DELETE SET NULL
);

-- Detalle de productos por pedido
CREATE TABLE detalle_pedidos (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    pedido_id    INTEGER NOT NULL,
    producto_id  INTEGER NOT NULL,
    cantidad     INTEGER NOT NULL CHECK (cantidad > 0),
    precio       REAL NOT NULL,
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT
);

-- Notificaciones enviadas al cliente sobre el estado de su pedido
CREATE TABLE notificaciones (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id  INTEGER,
    pedido_id   INTEGER,
    mensaje     TEXT NOT NULL,
    leido       INTEGER NOT NULL DEFAULT 0 CHECK (leido IN (0,1)),
    fecha       TEXT,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id) ON DELETE CASCADE,
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE
);

-- Historial de seguimiento / tracking de cada pedido (cambios de estado y ubicación)
CREATE TABLE seguimiento (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    pedido_id   INTEGER NOT NULL,
    estado      TEXT,
    fecha       TEXT,
    ubicacion   TEXT,
    FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE
);

-- Índices para acelerar las consultas más frecuentes del dashboard
CREATE INDEX idx_pedidos_cliente ON pedidos(cliente_id);
CREATE INDEX idx_pedidos_repartidor ON pedidos(repartidor_id);
CREATE INDEX idx_pedidos_estado ON pedidos(estado);
CREATE INDEX idx_pedidos_zona ON pedidos(zona);
CREATE INDEX idx_detalle_pedido ON detalle_pedidos(pedido_id);
CREATE INDEX idx_productos_categoria ON productos(categoria_id);
CREATE INDEX idx_notificaciones_cliente ON notificaciones(cliente_id);

-- ---------------------------------------------------------------------
-- 3. DATOS DE PRUEBA
-- ---------------------------------------------------------------------

-- Categorías
INSERT INTO categorias (id, nombre) VALUES
    (1, 'Platos del día'),
    (2, 'Vegetarianos'),
    (3, 'Bebidas');

-- Productos
INSERT INTO productos (id, nombre, descripcion, precio, imagen_url, categoria_id) VALUES
    (1, 'Pastel de Choclo', 'Receta tradicional con pino de carne, pollo, huevo duro y aceitunas, gratinado al horno.', 8500, '/img/pastel_de_choclo.jpg', 1),
    (2, 'Cazuela de Vacuno', 'Clásica sopa chilena con trozo de vacuno, zapallo, papa, choclo y arroz.', 7200, '/img/cazuela_de_vacuno.jpg', 1),
    (3, 'Porotos Granados', 'Guiso de porotos tiernos con zapallo, choclo y albahaca fresca.', 6500, '/img/porotos_granados.jpg', 2),
    (4, 'Humitas (2 un.)', 'Pastel de choclo molido con albahaca, envuelto en su propia hoja.', 5800, '/img/humitas.jpg', 2),
    (5, 'Porotos con Riendas', 'Porotos con tallarines gruesos chilenos con longaniza artesanal.', 5900, '/porotos_con_riendas.jpg', 1),
    (6, 'Charquicán de Vacuno', 'Tradicional guiso de papas, zapallo molido, carne tierna molida y huevo frito encima.', 6800, '/charquican.jpg', 1),
    (7, 'Completo Italiano', 'Pan alargado crujiente con salchicha, tomate picado, palta molida y mayonesa casera chilena.', 3500, '/completo_italiano.jpg', 1),
    (8, 'Ensalada César', 'Pechuga de pollo a las brasas, lechuga hidropónica, crotones de pan al ajo y salsa alioli César.', 4900, '/img/ensalada_cesar.jpg', 2),
    (9, 'Mote con Huesillo', 'Vaso de mote con duraznos deshidratados cocidos y almíbar chileno bien helado.', 2500, '/img/mote_con_huesillo.jpg', 3),
    (10, 'Limonada Menta Jengibre', 'Vaso refrescante de limonada natural batida con menta fresca y jengibre rallado.', 3200, '/img/limonada_menta_jengibre.jpg', 3),
    (11, 'Agua Mineral', 'Botella de agua mineral de manantial premium con gas servida helada.', 1500, '/img/agua_mineral.jpg', 3),
    (12, 'Bebida Cola 350cc', 'Refresco clásico frío de 350cc.', 1800, '/img/bebida_cola.jpg', 3);

-- Clientes (contraseña_hash de prueba = '1234' para todos)
INSERT INTO clientes (id, id_cliente, nombre, email, correo, contraseña_hash, foto_url, telefono, nivel, zona) VALUES
    (1, 1, 'Camila', 'camila@techcorp.cl', 'camila@techcorp.cl', '1234', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=150', '+56 9 8473 1122', 'Nivel Élite', 'Providencia'),
    (2, 2, 'Julián Cortés', 'julian.c@techcorp.com', 'julian.c@techcorp.com', '1234', 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=150', '+56 9 1234 5678', 'Nivel Élite', 'Centro'),
    (3, 3, 'Sebastián', 'seba@creativeagency.cl', 'seba@creativeagency.cl', '1234', 'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?auto=format&fit=crop&q=80&w=150', '+56 9 7362 8833', 'Miembro VIP', 'Providencia'),
    (4, 4, 'Felipe', 'felipe@lascondes.cl', 'felipe@lascondes.cl', '1234', NULL, '+56 9 6352 1199', 'Nivel Básico', 'Las Condes'),
    (5, 5, 'Carolina Morales', 'caro.morales@gmail.com', 'caro.morales@gmail.com', '1234', 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&q=80&w=150', '+56 9 9283 5533', 'Miembro VIP', 'Ñuñoa'),
    (6, 6, 'Andrés García', 'andres.g@santiago.cl', 'andres.g@santiago.cl', '1234', NULL, '+56 9 8654 4432', 'Nivel Élite', 'Santiago Poniente'),
    (7, 7, 'Florencia Donoso', 'flo@vitacuradesign.cl', 'flo@vitacuradesign.cl', '1234', NULL, '+56 9 7731 2288', 'Nivel Élite', 'Vitacura'),
    (8, 8, 'Mateo Silva', 'mateo@startup.cl', 'mateo@startup.cl', '1234', NULL, '+56 9 8653 2277', 'Nivel Básico', 'Centro'),
    (9, 9, 'Valentina Ríos', 'vale@agency.cl', 'vale@agency.cl', '1234', NULL, '+56 9 9872 6352', 'Miembro VIP', 'Providencia'),
    (10, 10, 'Diego Torres', 'diego@agile.cl', 'diego@agile.cl', '1234', 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=150', '+56 9 5432 1109', 'Nivel Élite', 'Las Condes'),
    (11, 11, 'Sofía Rojas', 'sofia@startup.cl', 'sofia@startup.cl', '1234', NULL, '+56 9 6632 7741', 'Nivel Básico', 'Ñuñoa'),
    (12, 12, 'Nicolás Salazar', 'nico@workspace.cl', 'nico@workspace.cl', '1234', NULL, '+56 9 7722 3451', 'Nivel Básico', 'Centro');

-- Repartidores (Matías es el repartidor activo de la demo; se agregan 2 adicionales como datos de prueba)
INSERT INTO repartidores (id, nombre, email, vehiculo, comuna, pedidos, km, calificacion) VALUES
    (1, 'Matías Aravena', 'matias.aravena@rutasmart.cl', 'Bicicleta', 'Providencia, RM', 1842, 3125.3, 4.8),
    (2, 'Camila Reyes', 'camila.reyes@rutasmart.cl', 'Moto', 'Santiago Centro, RM', 540, 980.4, 4.6),
    (3, 'Diego Fuentes', 'diego.fuentes@rutasmart.cl', 'Auto', 'Las Condes, RM', 210, 615.0, 4.9);

-- Sesiones de ejemplo
INSERT INTO sesiones (id_cliente, token_sesion, fecha_inicio, fecha_cierre) VALUES
    (2, 'tok_julian_2026_06_19', DATETIME('now', '-2 hours'), NULL),
    (1, 'tok_camila_2026_06_18', DATETIME('now', '-1 day'), DATETIME('now', '-1 day', '+40 minutes')),
    (5, 'tok_carolina_2026_06_17', DATETIME('now', '-2 day'), DATETIME('now', '-2 day', '+25 minutes'));

-- Pedidos (42 pedidos del día simulados + 1 pedido activo especial RS-2410)
INSERT INTO pedidos (id, tracking_number, cliente_id, repartidor_id, estado, zona, direccion, ref_direccion, subtotal, costo_envio, total, fecha, hora, metodo_pago) VALUES
    (1, 'RS-8821', 2, 1, 'ENTREGADO', 'Providencia', 'Av. Providencia 123, Of. 402', 'Edificio 101, Oficina 4', 10000, 1500, 11500, DATE('now'), '11:13', 'Sodexo / Junaeb'),
    (2, 'RS-8822', 3, 1, 'ENTREGADO', 'Las Condes', 'Calle Moneda 850, Piso 12', 'Edificio 102, Oficina 8', 11500, 1500, 13000, DATE('now'), '11:26', 'Pagar con Efectivo'),
    (3, 'RS-8823', 4, 1, 'ENTREGADO', 'Ñuñoa', 'Av. Apoquindo 4200, Depto 91', 'Edificio 103, Oficina 12', 8500, 1500, 10000, DATE('now'), '11:39', 'Crédito Webpay'),
    (4, 'RS-8824', 5, 1, 'ENTREGADO', 'Santiago Poniente', 'Plaza Ñuñoa 15', 'Edificio 104, Oficina 16', 10000, 1500, 11500, DATE('now'), '11:52', 'Transbank / Débito'),
    (5, 'RS-8825', 6, 1, 'ENTREGADO', 'Vitacura', 'Bulnes 2840, Sector Poniente', 'Edificio 105, Oficina 20', 11500, 1500, 13000, DATE('now'), '11:05', 'Sodexo / Junaeb'),
    (6, 'RS-8826', 7, 1, 'ENTREGADO', 'Centro', 'Av. Vitacura 2650, Of. 302', 'Edificio 106, Oficina 24', 8500, 1500, 10000, DATE('now'), '11:18', 'Pagar con Efectivo'),
    (7, 'RS-8827', 8, 1, 'ENTREGADO', 'Providencia', 'Calle Tech 404, Silicon Valley', 'Edificio 107, Oficina 28', 10000, 1500, 11500, DATE('now'), '11:31', 'Crédito Webpay'),
    (8, 'RS-8828', 9, 1, 'ENTREGADO', 'Las Condes', 'Av. Providencia 123, Of. 402', 'Edificio 108, Oficina 32', 11500, 1500, 13000, DATE('now'), '11:44', 'Transbank / Débito'),
    (9, 'RS-8829', 10, 1, 'ENTREGADO', 'Ñuñoa', 'Calle Moneda 850, Piso 12', 'Edificio 109, Oficina 36', 8500, 1500, 10000, DATE('now'), '11:57', 'Sodexo / Junaeb'),
    (10, 'RS-88210', 11, 1, 'ENTREGADO', 'Santiago Poniente', 'Av. Apoquindo 4200, Depto 91', 'Edificio 110, Oficina 40', 10000, 1500, 11500, DATE('now'), '11:10', 'Pagar con Efectivo'),
    (11, 'RS-88211', 12, 1, 'ENTREGADO', 'Vitacura', 'Plaza Ñuñoa 15', 'Edificio 111, Oficina 44', 11500, 1500, 13000, DATE('now'), '11:23', 'Crédito Webpay'),
    (12, 'RS-88212', 1, 1, 'ENTREGADO', 'Centro', 'Bulnes 2840, Sector Poniente', 'Edificio 112, Oficina 48', 8500, 1500, 10000, DATE('now'), '11:36', 'Transbank / Débito'),
    (13, 'RS-88213', 2, 1, 'ENTREGADO', 'Providencia', 'Av. Vitacura 2650, Of. 302', 'Edificio 113, Oficina 52', 10000, 1500, 11500, DATE('now'), '11:49', 'Sodexo / Junaeb'),
    (14, 'RS-88214', 3, 1, 'ENTREGADO', 'Las Condes', 'Calle Tech 404, Silicon Valley', 'Edificio 114, Oficina 56', 11500, 1500, 13000, DATE('now'), '12:02', 'Pagar con Efectivo'),
    (15, 'RS-88215', 4, 1, 'ENTREGADO', 'Ñuñoa', 'Av. Providencia 123, Of. 402', 'Edificio 115, Oficina 60', 8500, 1500, 10000, DATE('now'), '12:15', 'Crédito Webpay'),
    (16, 'RS-88216', 5, 1, 'ENTREGADO', 'Santiago Poniente', 'Calle Moneda 850, Piso 12', 'Edificio 116, Oficina 64', 10000, 1500, 11500, DATE('now'), '12:28', 'Transbank / Débito'),
    (17, 'RS-88217', 6, 1, 'ENTREGADO', 'Vitacura', 'Av. Apoquindo 4200, Depto 91', 'Edificio 117, Oficina 68', 11500, 1500, 13000, DATE('now'), '12:41', 'Sodexo / Junaeb'),
    (18, 'RS-88218', 7, 1, 'ENTREGADO', 'Centro', 'Plaza Ñuñoa 15', 'Edificio 118, Oficina 72', 8500, 1500, 10000, DATE('now'), '12:54', 'Pagar con Efectivo'),
    (19, 'RS-88219', 8, 1, 'ENTREGADO', 'Providencia', 'Bulnes 2840, Sector Poniente', 'Edificio 119, Oficina 76', 10000, 1500, 11500, DATE('now'), '12:07', 'Crédito Webpay'),
    (20, 'RS-88220', 9, 1, 'ENTREGADO', 'Las Condes', 'Av. Vitacura 2650, Of. 302', 'Edificio 120, Oficina 80', 11500, 1500, 13000, DATE('now'), '12:20', 'Transbank / Débito'),
    (21, 'RS-88221', 10, 1, 'ENTREGADO', 'Ñuñoa', 'Calle Tech 404, Silicon Valley', 'Edificio 121, Oficina 84', 8500, 1500, 10000, DATE('now'), '12:33', 'Sodexo / Junaeb'),
    (22, 'RS-88222', 11, 1, 'ENTREGADO', 'Santiago Poniente', 'Av. Providencia 123, Of. 402', 'Edificio 122, Oficina 88', 10000, 1500, 11500, DATE('now'), '12:46', 'Pagar con Efectivo'),
    (23, 'RS-88223', 12, 1, 'ENTREGADO', 'Vitacura', 'Calle Moneda 850, Piso 12', 'Edificio 123, Oficina 92', 11500, 1500, 13000, DATE('now'), '12:59', 'Crédito Webpay'),
    (24, 'RS-88224', 1, 1, 'ENTREGADO', 'Centro', 'Av. Apoquindo 4200, Depto 91', 'Edificio 124, Oficina 96', 8500, 1500, 10000, DATE('now'), '12:12', 'Transbank / Débito'),
    (25, 'RS-88225', 2, 1, 'ENTREGADO', 'Providencia', 'Plaza Ñuñoa 15', 'Edificio 125, Oficina 100', 10000, 1500, 11500, DATE('now'), '12:25', 'Sodexo / Junaeb'),
    (26, 'RS-88226', 3, 1, 'ENTREGADO', 'Las Condes', 'Bulnes 2840, Sector Poniente', 'Edificio 126, Oficina 104', 11500, 1500, 13000, DATE('now'), '12:38', 'Pagar con Efectivo'),
    (27, 'RS-88227', 4, 1, 'ENTREGADO', 'Ñuñoa', 'Av. Vitacura 2650, Of. 302', 'Edificio 127, Oficina 108', 8500, 1500, 10000, DATE('now'), '12:51', 'Crédito Webpay'),
    (28, 'RS-88228', 5, 1, 'ENTREGADO', 'Santiago Poniente', 'Calle Tech 404, Silicon Valley', 'Edificio 128, Oficina 112', 10000, 1500, 11500, DATE('now'), '13:04', 'Transbank / Débito'),
    (29, 'RS-88229', 6, 1, 'EN_RUTA', 'Vitacura', 'Av. Providencia 123, Of. 402', 'Edificio 129, Oficina 116', 11500, 1500, 13000, DATE('now'), '13:17', 'Sodexo / Junaeb'),
    (30, 'RS-88230', 7, 1, 'PENDIENTE', 'Centro', 'Calle Moneda 850, Piso 12', 'Edificio 130, Oficina 120', 8500, 1500, 10000, DATE('now'), '13:30', 'Pagar con Efectivo'),
    (31, 'RS-88231', 8, 1, 'PENDIENTE', 'Providencia', 'Av. Apoquindo 4200, Depto 91', 'Edificio 131, Oficina 124', 10000, 1500, 11500, DATE('now'), '13:43', 'Crédito Webpay'),
    (32, 'RS-88232', 9, 1, 'PENDIENTE', 'Las Condes', 'Plaza Ñuñoa 15', 'Edificio 132, Oficina 128', 11500, 1500, 13000, DATE('now'), '13:56', 'Transbank / Débito'),
    (33, 'RS-88233', 10, 1, 'PENDIENTE', 'Ñuñoa', 'Bulnes 2840, Sector Poniente', 'Edificio 133, Oficina 132', 8500, 1500, 10000, DATE('now'), '13:09', 'Sodexo / Junaeb'),
    (34, 'RS-88234', 11, 1, 'PENDIENTE', 'Santiago Poniente', 'Av. Vitacura 2650, Of. 302', 'Edificio 134, Oficina 136', 10000, 1500, 11500, DATE('now'), '13:22', 'Pagar con Efectivo'),
    (35, 'RS-88235', 12, 1, 'PENDIENTE', 'Vitacura', 'Calle Tech 404, Silicon Valley', 'Edificio 135, Oficina 140', 11500, 1500, 13000, DATE('now'), '13:35', 'Crédito Webpay'),
    (36, 'RS-88236', 1, 1, 'PENDIENTE', 'Centro', 'Av. Providencia 123, Of. 402', 'Edificio 136, Oficina 144', 8500, 1500, 10000, DATE('now'), '13:48', 'Transbank / Débito'),
    (37, 'RS-88237', 2, 1, 'PENDIENTE', 'Providencia', 'Calle Moneda 850, Piso 12', 'Edificio 137, Oficina 148', 10000, 1500, 11500, DATE('now'), '13:01', 'Sodexo / Junaeb'),
    (38, 'RS-88238', 3, 1, 'PENDIENTE', 'Las Condes', 'Av. Apoquindo 4200, Depto 91', 'Edificio 138, Oficina 152', 11500, 1500, 13000, DATE('now'), '13:14', 'Pagar con Efectivo'),
    (39, 'RS-88239', 4, 1, 'PENDIENTE', 'Ñuñoa', 'Plaza Ñuñoa 15', 'Edificio 139, Oficina 156', 8500, 1500, 10000, DATE('now'), '13:27', 'Crédito Webpay'),
    (40, 'RS-88240', 5, 1, 'PENDIENTE', 'Santiago Poniente', 'Bulnes 2840, Sector Poniente', 'Edificio 140, Oficina 160', 10000, 1500, 11500, DATE('now'), '13:40', 'Transbank / Débito'),
    (41, 'RS-88241', 6, 1, 'PENDIENTE', 'Vitacura', 'Av. Vitacura 2650, Of. 302', 'Edificio 141, Oficina 164', 11500, 1500, 13000, DATE('now'), '13:53', 'Sodexo / Junaeb'),
    (42, 'RS-88242', 7, 1, 'PENDIENTE', 'Centro', 'Calle Tech 404, Silicon Valley', 'Edificio 142, Oficina 168', 8500, 1500, 10000, DATE('now'), '14:06', 'Pagar con Efectivo'),
    (43, 'RS-2410', 2, 1, 'RECIBIDO', 'Centro', 'Av. Libertador Bernardo O''Higgins 450, Of. 805, Santiago Centro', 'Frente a Cerro Santa Lucía, junto a Starbucks', 11000, 1500, 12500, DATE('now'), '11:45', 'Crédito Webpay');

-- Detalle de productos por pedido (1 ítem ilustrativo por cada pedido simulado)
INSERT INTO detalle_pedidos (pedido_id, producto_id, cantidad, precio) VALUES
    (1, 1, 1, 8500),
    (2, 2, 1, 7200),
    (3, 3, 1, 6500),
    (4, 4, 1, 5800),
    (5, 5, 1, 5900),
    (6, 6, 1, 6800),
    (7, 7, 1, 3500),
    (8, 8, 1, 4900),
    (9, 9, 1, 2500),
    (10, 10, 1, 3200),
    (11, 11, 1, 1500),
    (12, 12, 1, 1800),
    (13, 1, 1, 8500),
    (14, 2, 1, 7200),
    (15, 3, 1, 6500),
    (16, 4, 1, 5800),
    (17, 5, 1, 5900),
    (18, 6, 1, 6800),
    (19, 7, 1, 3500),
    (20, 8, 1, 4900),
    (21, 9, 1, 2500),
    (22, 10, 1, 3200),
    (23, 11, 1, 1500),
    (24, 12, 1, 1800),
    (25, 1, 1, 8500),
    (26, 2, 1, 7200),
    (27, 3, 1, 6500),
    (28, 4, 1, 5800),
    (29, 5, 1, 5900),
    (30, 6, 1, 6800),
    (31, 7, 1, 3500),
    (32, 8, 1, 4900),
    (33, 9, 1, 2500),
    (34, 10, 1, 3200),
    (35, 11, 1, 1500),
    (36, 12, 1, 1800),
    (37, 1, 1, 8500),
    (38, 2, 1, 7200),
    (39, 3, 1, 6500),
    (40, 4, 1, 5800),
    (41, 5, 1, 5900),
    (42, 6, 1, 6800),
    (43, 1, 1, 8500),
    (43, 9, 1, 2500);

-- Notificaciones de ejemplo
INSERT INTO notificaciones (cliente_id, pedido_id, mensaje, leido, fecha) VALUES
    (2, 43, 'Tu pedido ha sido recibido.', 0, DATE('now')),
    (6, 29, 'Tu pedido está en camino.', 0, DATE('now')),
    (1, 1, 'Tu pedido fue entregado correctamente.', 1, DATE('now'));

-- Historial de seguimiento de ejemplo
INSERT INTO seguimiento (pedido_id, estado, fecha, ubicacion) VALUES
    (43, 'RECIBIDO', DATETIME('now'), 'Local RutaSmart - Centro'),
    (29, 'ASIGNADO', DATETIME('now', '-30 minutes'), 'Local RutaSmart - Centro'),
    (29, 'EN_CAMINO', DATETIME('now', '-10 minutes'), 'Providencia, camino al cliente');

-- =====================================================================
-- FIN DEL SCRIPT
-- =====================================================================
