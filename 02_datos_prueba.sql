-- =====================================================================
-- APE 2 - Administración de Bases de Datos
-- Script 02: Datos de prueba (contexto Universidad Estatal de Bolívar)
-- Se usan las tablas del modelo físico SIN modificar su estructura.
-- Convención usada en profesores.cargo para las reglas de la UEB:
--   'Director', 'Director subrogante', 'Investigador'
-- =====================================================================
USE gestion_investigacion;

-- Líneas de investigación (dominio TIC y líneas con las que se colabora)
INSERT INTO linea_investigacion (nombre_linea, descriptores) VALUES
('Desarrollo de software', 'Ingeniería de software; Aplicaciones web; Aplicaciones móviles'),
('Inteligencia artificial y ciencia de datos', 'Aprendizaje automático; Visión por computador; Análisis de datos'),
('Redes y telecomunicaciones', 'Redes de datos; VoIP; Internet de las cosas'),
('Seguridad de la información', 'Ciberseguridad; Criptografía; Auditoría informática'),
('Sistemas de información y bases de datos', 'SGBD relacional; Bases de datos temporales; Inteligencia de negocios'),
('Producción agropecuaria sostenible', 'Agronomía; Clima; Agricultura de precisión'),
('Emprendimiento e innovación', 'Gestión empresarial; Modelos de negocio; Innovación tecnológica');

-- Profesores
INSERT INTO profesores (nombre, telefono, cargo, departamento_facultad) VALUES
('Carlos Andrés Villacrés Ramos',   '0991234501', 'Director',            'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('María Fernanda Gavilanes Silva',  '0991234502', 'Director',            'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Luis Alberto Chimbo Yánez',       '0991234503', 'Director',            'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
('Ana Lucía Arellano Torres',       '0991234504', 'Director subrogante', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Jorge Patricio Naranjo Coloma',   '0991234505', 'Director subrogante', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Diana Carolina Pazmiño Llerena',  '0991234506', 'Director subrogante', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
('Héctor Iván Sánchez Barragán',    '0991234507', 'Investigador',        'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Gabriela Estefanía Mora Lema',    '0991234508', 'Investigador',        'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Ramiro Javier Guamán Ortiz',      '0991234509', 'Investigador',        'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Paola Alexandra Salazar Vega',    '0991234510', 'Investigador',        'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
('Edison Fabricio Lombeida Pilco',  '0991234511', 'Investigador',        'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
('Verónica Isabel Coello Ruiz',     '0991234512', 'Investigador',        'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
('Fausto Rodrigo Escobar Núñez',    '0991234513', 'Investigador',        'Facultad de Ciencias de la Educación, Sociales, Filosóficas y Humanísticas');

-- Proyectos de investigación
INSERT INTO proyecto_investigacion (nombre_proyecto, acronimo, presupuesto, descripcion) VALUES
('Plataforma web para la gestión de la investigación universitaria', 'PLATINV', 18500.00, 'Desarrollar un sistema web para registrar proyectos, investigadores y productos de investigación de la UEB.'),
('Análisis de imágenes satelitales para el monitoreo del clima en Bolívar', 'SATCLIMA', 32000.00, 'Aplicar técnicas de inteligencia artificial sobre imágenes satelitales para analizar el clima de la provincia.'),
('Red IoT para el monitoreo de cultivos andinos', 'IOTAGRO', 24750.00, 'Implementar sensores conectados en red para medir humedad y temperatura en cultivos.'),
('Modelo de ciberseguridad para gobiernos autónomos descentralizados', 'CIBERGAD', 12000.00, 'Proponer un modelo de seguridad de la información para los GAD de la provincia Bolívar.'),
('Repositorio de datos abiertos de la provincia Bolívar', 'DATABOL', 9800.00, 'Construir un repositorio de datos abiertos con información socioeconómica de la provincia.');

-- Líneas que abarca cada proyecto (proyecto_linea)
INSERT INTO proyecto_linea (id_linea, id_proyecto) VALUES
(1,1),(5,1),
(2,2),(6,2),(3,2),
(3,3),(6,3),
(4,4),
(5,5),(2,5);

-- Participación de profesores (director + máximo 4 investigadores)
INSERT INTO proyecto_profesor (id_proyecto, id_profesor, inicio_pro, fin_pro) VALUES
-- Proyecto 1 PLATINV
(1, 1, '2025-03-01', NULL),
(1, 4, '2025-03-01', NULL),
(1, 7, '2025-03-01', NULL),
(1, 8, '2025-04-15', '2026-02-28'),
(1, 12,'2025-03-01', NULL),
-- Proyecto 2 SATCLIMA
(2, 2, '2024-09-01', NULL),
(2, 5, '2024-09-01', NULL),
(2, 10,'2024-09-01', NULL),
(2, 9, '2024-10-01', NULL),
(2, 11,'2025-01-10', NULL),
-- Proyecto 3 IOTAGRO
(3, 3, '2025-06-01', NULL),
(3, 6, '2025-06-01', NULL),
(3, 11,'2025-06-01', NULL),
(3, 9, '2025-06-01', '2026-12-15'),
-- Proyecto 4 CIBERGAD (proyecto ya finalizado)
(4, 1, '2023-02-01', '2024-01-31'),
(4, 5, '2023-02-01', '2024-01-31'),
(4, 8, '2023-02-01', '2024-01-31'),
-- Proyecto 5 DATABOL
(5, 2, '2026-01-05', NULL),
(5, 4, '2026-01-05', NULL),
(5, 7, '2026-01-05', '2026-11-30');
-- El profesor 13 (Fausto Escobar) no participa en ningún proyecto.

-- Productos (resultados) de los proyectos
INSERT INTO productos (id_proyecto, titulo, num_secuencia) VALUES
(1, 'Arquitectura de un sistema web para la gestión de proyectos de investigación', 1),
(1, 'Gestión de la investigación universitaria con software libre', 2),
(1, 'Evaluación de usabilidad de una plataforma de investigación universitaria', 3),
(2, 'Clasificación de cobertura vegetal con imágenes satelitales en Bolívar', 1),
(2, 'Modelo predictivo de precipitaciones con redes neuronales', 2),
(2, 'Método de procesamiento de imágenes satelitales para zonas andinas', 3),
(2, 'Inteligencia artificial aplicada al clima andino', 4),
(3, 'Sensores de bajo costo para la agricultura de precisión', 1),
(3, 'Dispositivo IoT para medir la humedad del suelo', 2),
(4, 'Diagnóstico de seguridad de la información en GAD cantonales', 1),
(4, 'Buenas prácticas de ciberseguridad para gobiernos locales', 2);
-- El proyecto 5 (DATABOL) todavía no tiene productos.

-- Subtipos de producto
INSERT INTO revista (id_producto, nombre_revista, editorial, volumen, pagina_inicio, pagina_fin, quartil, url, doi, issn, e_issn) VALUES
(1, 'Revista Ibérica de Sistemas e Tecnologias de Informação', 'AISTI', '45', 112, 125, 'Q3', 'https://www.risti.xyz', '10.17013/risti.45.112-125', '1646-9895', NULL),
(4, 'Remote Sensing', 'MDPI', '17', 1, 22, 'Q1', 'https://www.mdpi.com/journal/remotesensing', '10.3390/rs17010001', NULL, '2072-4292'),
(5, 'Revista Ciencia UNEMI', 'Universidad Estatal de Milagro', '18', 45, 58, NULL, 'https://ojs.unemi.edu.ec', '10.29076/issn.2528-7737vol18iss47.2025pp45-58p', '1390-4272', '2528-7737'),
(8, 'Computers and Electronics in Agriculture', 'Elsevier', '230', 101, 115, 'Q2', 'https://www.sciencedirect.com/journal/computers-and-electronics-in-agriculture', '10.1016/j.compag.2025.101', '0168-1699', NULL),
(10,'Revista Tecnológica ESPOL', 'ESPOL', '36', 70, 84, 'Q4', 'https://rte.espol.edu.ec', '10.37815/rte.v36n1.2024', '0257-1749', '1390-3659');

INSERT INTO congreso (id_producto, tipo_congreso, fecha_inicio, fecha_fin, lugar_evento, pais, editorial_actas, entidad_organizadora, tipo_participacion, ambito) VALUES
(3, 'Congreso científico', '2026-05-20', '2026-05-22', 'Guaranda', 'Ecuador', 'Editorial UEB', 'Universidad Estatal de Bolívar', 'Ponencia', 'Nacional'),
(11,'Conferencia', '2024-10-08', '2024-10-11', 'Lima', 'Perú', 'IEEE', 'IEEE Sección Perú', 'Artículo en actas', 'Internacional');

INSERT INTO libro (id_producto, isbn, editorial, lugar_publicacion, fecha_publicacion, total_paginas) VALUES
(2, '978-9942-0000-1-1', 'Editorial UEB', 'Guaranda', '2026-03-10', 186),
(7, '978-9942-0000-2-8', 'Editorial UEB', 'Guaranda', '2025-11-20', 240);

INSERT INTO patentes (num_registro, id_producto, estado, pais_registro, fecha_concesion, clasificacion_inter, num_solicitud, fecha_solicitud) VALUES
('SENADI-2025-0457', 6, 'Concedida', 'Ecuador', '2026-04-18', 'G06T 7/00', 'SOL-2025-0457', '2025-05-02'),
('SENADI-2026-0112', 9, 'Solicitada', 'Ecuador', NULL, 'A01G 25/16', 'SOL-2026-0112', '2026-02-14');

-- Incidencia #2 corregida: Tildes mal guardadas y mensajes de triggers con caracteres raros. Solución: importar los scripts con el juego de caracteres utf-8 (utf8mb4) y volver a crear la base.
