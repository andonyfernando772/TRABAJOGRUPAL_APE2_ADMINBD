-- =====================================================================
-- 02. Inserción de datos de prueba
-- =====================================================================
USE gestion_investigacion;

INSERT INTO linea_investigacion (id_linea, nombre_linea, descriptores) VALUES
(1, 'Desarrollo de software', 'Ingeniería de software; Aplicaciones web; Aplicaciones móviles'),
(2, 'Inteligencia artificial y ciencia de datos', 'Aprendizaje automático; Visión por computador; Análisis de datos'),
(3, 'Redes y telecomunicaciones', 'Redes de datos; VoIP; Internet de las cosas'),
(4, 'Seguridad de la información', 'Ciberseguridad; Criptografía; Auditoría informática'),
(5, 'Sistemas de información y bases de datos', 'SGBD relacional; Bases de datos temporales; Inteligencia de negocios'),
(6, 'Producción agropecuaria sostenible', 'Agronomía; Clima; Agricultura de precisión'),
(7, 'Emprendimiento e innovación', 'Gestión empresarial; Modelos de negocio; Innovación tecnológica');

INSERT INTO profesores (id_profesor, nombre, telefono, departamento_facultad) VALUES
(1,  'Carlos Andrés Villacrés Ramos',  '0991234501', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(2,  'María Fernanda Gavilanes Silva', '0991234502', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(3,  'Luis Alberto Chimbo Yánez',      '0991234503', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
(4,  'Ana Lucía Arellano Torres',      '0991234504', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(5,  'Jorge Patricio Naranjo Coloma',  '0991234505', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(6,  'Diana Carolina Pazmiño Llerena', '0991234506', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
(7,  'Héctor Iván Sánchez Barragán',   '0991234507', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(8,  'Gabriela Estefanía Mora Lema',   '0991234508', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(9,  'Ramiro Javier Guamán Ortiz',     '0991234509', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(10, 'Paola Alexandra Salazar Vega',   '0991234510', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
(11, 'Edison Fabricio Lombeida Pilco', '0991234511', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
(12, 'Verónica Isabel Coello Ruiz',    '0991234512', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(13, 'Fausto Rodrigo Escobar Núñez',   '0991234513', 'Facultad de Ciencias de la Educación, Sociales, Filosóficas y Humanísticas');

INSERT INTO proyecto_investigacion (id_proyecto, nombre_proyecto, acronimo, presupuesto, programa, descripcion,
       inicio_pro, fin_pro, resolucion_consejo_uni_aprobado, resolucion_consejo_uni_cierre, prorroga) VALUES
(1, 'Plataforma web para la gestión de la investigación universitaria', 'PLATINV', 18500.00,
    'Programa de Desarrollo Tecnológico', 'Desarrollar un sistema web para registrar proyectos, investigadores y productos de investigación de la UEB.',
    '2025-03-01', '2026-12-31', 'RCU-UEB-2025-045', NULL, NULL),
(2, 'Análisis de imágenes satelitales para el monitoreo del clima en Bolívar', 'SATCLIMA', 32000.00,
    'Programa de Ambiente y Clima', 'Aplicar técnicas de inteligencia artificial sobre imágenes satelitales para analizar el clima de la provincia.',
    '2024-09-01', '2026-08-31', 'RCU-UEB-2024-118', NULL, '2027-02-28'),
(3, 'Red IoT para el monitoreo de cultivos andinos', 'IOTAGRO', 24750.00,
    'Programa Agropecuario Sostenible', 'Implementar sensores conectados en red para medir humedad y temperatura en cultivos.',
    '2025-06-01', '2027-06-30', 'RCU-UEB-2025-089', NULL, NULL),
(4, 'Modelo de ciberseguridad para gobiernos autónomos descentralizados', 'CIBERGAD', 12000.00,
    'Programa de Gestión Pública', 'Proponer un modelo de seguridad de la información para los GAD de la provincia Bolívar.',
    '2023-02-01', '2024-01-31', 'RCU-UEB-2023-007', 'RCU-UEB-2024-012', NULL),
(5, 'Repositorio de datos abiertos de la provincia Bolívar', 'DATABOL', 11500.00,
    'Programa de Desarrollo Tecnológico', 'Construir un repositorio de datos abiertos con información socioeconómica de la provincia.',
    '2026-01-05', '2026-11-30', 'RCU-UEB-2025-201', NULL, NULL);

INSERT INTO proyecto_linea (id_linea, id_proyecto) VALUES
(1,1),(5,1),(2,2),(3,2),(6,2),(3,3),(6,3),(4,4),(2,5),(5,5);

INSERT INTO linea_profesor (id_linea, id_profesor) VALUES
(1,1),(1,7),(1,12),(5,4),(5,8),(2,2),(2,5),(2,9),(3,9),(3,11),
(6,3),(6,6),(6,10),(6,11),(4,1),(4,8),(7,13);

INSERT INTO proyecto_profesor (id_proyecto, id_profesor, num_profesores, cargo,
       resolucion_ingreso, resolucion_salida, motivo_salida) VALUES
(1, 1,  1, 'Director',            NULL,               NULL, NULL),
(1, 4,  2, 'Director subrogante', NULL,               NULL, NULL),
(1, 7,  3, 'Investigador',        NULL,               NULL, NULL),
(1, 8,  5, 'Investigador',        NULL,               'RCU-UEB-2026-030', 'Cambio de dedicación a docencia'),
(1, 12, 4, 'Investigador',        NULL,               NULL, NULL),
(2, 2,  1, 'Director',            NULL,               NULL, NULL),
(2, 5,  2, 'Director subrogante', NULL,               NULL, NULL),
(2, 9,  3, 'Investigador',        'RCU-UEB-2024-131', NULL, NULL),
(2, 10, 4, 'Investigador',        NULL,               NULL, NULL),
(2, 11, 5, 'Investigador',        'RCU-UEB-2025-004', NULL, NULL),
(3, 3,  1, 'Director',            NULL,               NULL, NULL),
(3, 6,  2, 'Director subrogante', NULL,               NULL, NULL),
(3, 9,  3, 'Investigador',        NULL,               NULL, NULL),
(3, 11, 4, 'Investigador',        NULL,               NULL, NULL),
(3, 8,  5, 'Investigador',        'RCU-UEB-2026-150', NULL, NULL),
(4, 1,  1, 'Director',            NULL,               'RCU-UEB-2024-012', 'Cierre del proyecto'),
(4, 5,  2, 'Director subrogante', NULL,               'RCU-UEB-2024-012', 'Cierre del proyecto'),
(4, 8,  3, 'Investigador',        NULL,               'RCU-UEB-2024-012', 'Cierre del proyecto'),
(5, 2,  1, 'Director',            NULL,               NULL, NULL),
(5, 4,  2, 'Director subrogante', NULL,               NULL, NULL),
(5, 7,  3, 'Investigador',        NULL,               NULL, NULL);

INSERT INTO estudiante (id_estudiante, id_proyecto, nombres_est, telefono_est, departamento_facultad) VALUES
(1, 1, 'Kevin Alexander Chela Guamán',   '0987654301', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(2, 1, 'Mishel Carolina Yánez Pazmiño',  '0987654302', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(3, 2, 'Bryan Santiago Ruiz Vargas',     '0987654303', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(4, 2, 'Lizbeth Johanna Tixi Coles',     '0987654304', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
(5, 2, 'Jonathan David Sisa Llumitasig', '0987654305', 'Facultad de Ciencias Administrativas, Gestión Empresarial e Informática'),
(6, 3, 'Erika Fernanda Gaibor Arias',    '0987654306', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente'),
(7, 3, 'Marco Vinicio Paredes Cruz',     '0987654307', 'Facultad de Ciencias Agropecuarias, Recursos Naturales y del Ambiente');

INSERT INTO tipo_pro (id_tipo, descripcion_tipo) VALUES
(1, 'Revista'), (2, 'Congreso'), (3, 'Libro'), (4, 'Patente');

INSERT INTO productos (id_producto, id_proyecto, id_tipo, titulo_publicacion, num_secuencia) VALUES
(1,  1, 1, 'Arquitectura de un sistema web para la gestión de proyectos de investigación', 1),
(2,  1, 3, 'Gestión de la investigación universitaria con software libre', 2),
(3,  1, 2, 'Evaluación de usabilidad de una plataforma de investigación universitaria', 3),
(4,  2, 1, 'Clasificación de cobertura vegetal con imágenes satelitales en Bolívar', 1),
(5,  2, 1, 'Modelo predictivo de precipitaciones con redes neuronales', 2),
(6,  2, 4, 'Método de procesamiento de imágenes satelitales para zonas andinas', 3),
(7,  2, 3, 'Inteligencia artificial aplicada al clima andino', 4),
(8,  3, 1, 'Sensores de bajo costo para la agricultura de precisión', 1),
(9,  3, 4, 'Dispositivo IoT para medir la humedad del suelo', 2),
(10, 4, 1, 'Diagnóstico de seguridad de la información en GAD cantonales', 1),
(11, 4, 2, 'Buenas prácticas de ciberseguridad para gobiernos locales', 2),
(12, 5, 2, 'Portal de datos abiertos de la provincia Bolívar', 1);

INSERT INTO publicacion_revista (id_revista, id_producto, nombre_revista, editorial, volumen, pagina_inicio, pagina_fin,
       quartil, url, doi, issn, e_issn) VALUES
(1, 1,  'Revista Ibérica de Sistemas e Tecnologias de Informação', 'AISTI', '45', 112, 125, 'Q3', 'https://www.risti.xyz', '10.17013/risti.45.112-125', '1646-9895', NULL),
(2, 4,  'Remote Sensing', 'MDPI', '17', 1, 22, 'Q1', 'https://www.mdpi.com/journal/remotesensing', '10.3390/rs17010001', NULL, '2072-4292'),
(3, 5,  'Revista Ciencia UNEMI', 'Universidad Estatal de Milagro', '18', 45, 58, NULL, 'https://ojs.unemi.edu.ec', '10.29076/issn.2528-7737vol18iss47.2025pp45-58p', '1390-4272', '2528-7737'),
(4, 8,  'Computers and Electronics in Agriculture', 'Elsevier', '230', 101, 115, 'Q2', 'https://www.sciencedirect.com/journal/computers-and-electronics-in-agriculture', '10.1016/j.compag.2025.101', '0168-1699', NULL),
(5, 10, 'Revista Tecnológica ESPOL', 'ESPOL', '36', 70, 84, 'Q4', 'https://rte.espol.edu.ec', '10.37815/rte.v36n1.2024', '0257-1749', '1390-3659');

INSERT INTO publicacion_congreso (id_congreso, id_producto, nombre_congreso, tipo_congreso, fecha_inicio, fecha_fin,
       lugar_celebracion, pais, editorial_actas, entidad_organizadora, tipo_participacion, ambito) VALUES
(1, 3,  'Congreso Internacional de Ciencia y Tecnología UEB 2026', 'Congreso científico', '2026-05-20', '2026-05-22', 'Guaranda', 'Ecuador', 'Editorial UEB', 'Universidad Estatal de Bolívar', 'Ponencia', 'Nacional'),
(2, 11, 'IEEE ANDESCON 2024', 'Conferencia', '2024-10-08', '2024-10-11', 'Lima', 'Perú', 'IEEE', 'IEEE Sección Perú', 'Artículo en actas', 'Internacional'),
(3, 12, 'Jornadas de Investigación UEB 2026', 'Jornada científica', '2026-10-14', '2026-10-15', 'Guaranda', 'Ecuador', NULL, 'Universidad Estatal de Bolívar', 'Ponencia', 'Local');

INSERT INTO libro (id_libro, id_producto, isbn, titulo_libro, editorial, lugar_publicacion, fecha_publicacion, total_paginas) VALUES
(1, 2, '978-9942-0000-1-1', 'Gestión de la investigación universitaria con software libre', 'Editorial UEB', 'Guaranda', '2026-03-10', 186),
(2, 7, '978-9942-0000-2-8', 'Inteligencia artificial aplicada al clima andino', 'Editorial UEB', 'Guaranda', '2025-11-20', 240);

INSERT INTO patentes (num_registro, id_producto, nombre_patente, estado, pais_registro, fecha_concesion,
       num_solicitud, fecha_solicitud, clasificacion_inter) VALUES
('SENADI-2025-0457', 6, 'Método de procesamiento de imágenes satelitales para zonas andinas', 'Concedida', 'Ecuador', '2026-04-18', 'SOL-2025-0457', '2025-05-02', 'G06T 7/00'),
('SENADI-2026-0112', 9, 'Dispositivo IoT para medir la humedad del suelo', 'Solicitada', 'Ecuador', NULL, 'SOL-2026-0112', '2026-02-14', 'A01G 25/16');

-- Carga inicial de la tabla resumen (los triggers la mantienen desde aquí)
INSERT INTO resumen_proyecto (id_proyecto, total_productos)
SELECT p.id_proyecto, COUNT(pr.id_producto)
  FROM proyecto_investigacion p
  LEFT JOIN productos pr ON pr.id_proyecto = p.id_proyecto
 GROUP BY p.id_proyecto;
