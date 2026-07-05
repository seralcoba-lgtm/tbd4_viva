# GUI Laravel / Filament - Proyecto Viva

## 1. Descripción general

Este repositorio contiene el código fuente de la GUI desarrollada para el proyecto **Viva**, una interfaz web construida con **Laravel** y **Filament** para administrar y consultar módulos relacionados con clientes, ventas, finanzas y seguridad de una base de datos PostgreSQL.

La GUI fue implementada como una capa visual sobre la base de datos, permitiendo gestionar información del negocio mediante pantallas tipo CRUD, respetando la estructura lógica del sistema y los controles de acceso definidos en PostgreSQL.

> **Nota de seguridad:** Este repositorio no incluye credenciales, contraseñas, backups ni datos sensibles. El archivo `.env` no debe subirse al repositorio.

---

## 2. Objetivo de la GUI

El objetivo principal de la GUI es facilitar la administración de información del sistema Viva mediante una interfaz web amigable, evitando que el usuario tenga que ejecutar consultas SQL manualmente para operaciones comunes.

La interfaz permite visualizar, registrar, editar y consultar información del negocio de forma ordenada, usando recursos de Filament conectados a modelos Laravel.

---

## 3. Tecnologías utilizadas

Las principales tecnologías utilizadas en el proyecto son:

- **Laravel 11** como framework backend.
- **Filament** como panel administrativo para la creación de recursos CRUD.
- **PHP 8.3** como lenguaje principal del proyecto.
- **PostgreSQL 17** como sistema gestor de base de datos.
- **Docker** para contenerizar la base de datos PostgreSQL.
- **Nginx** como servidor web en la VM.
- **Ubuntu Server 24.04** como sistema operativo de la VM.
- **Composer** para la gestión de dependencias PHP.
- **GitHub** para el versionamiento del código.

---

## 4. Arquitectura general

La solución está organizada en tres capas principales:

### 4.1. Capa de presentación

Corresponde a la interfaz web generada con **Filament**.  
Desde esta capa el usuario puede acceder a los módulos disponibles, visualizar registros, aplicar búsquedas, crear nuevos datos y editar información permitida.

### 4.2. Capa de aplicación

Corresponde al proyecto **Laravel**, donde se encuentran:

- Modelos Eloquent.
- Recursos de Filament.
- Formularios.
- Tablas.
- Validaciones.
- Configuración del panel.
- Control de navegación según el tipo de usuario.

### 4.3. Capa de datos

Corresponde a la base de datos **PostgreSQL**, organizada por esquemas como:

- `clientes`
- `ventas`
- `finanzas`
- `rrhh`
- `seguridad`
- `app`

La base de datos cuenta con roles, privilegios, vistas, políticas RLS y auditoría, mientras que la GUI se conecta como una aplicación web para consultar y operar sobre la información permitida.

---

## 5. Estructura principal del proyecto

Las carpetas más importantes del repositorio son:

```text
app/
├── Filament/
│   └── Resources/
├── Models/
├── Providers/

config/
database/
public/
resources/
routes/
storage/
tests/
```

### Descripción de carpetas importantes

| Carpeta / archivo | Descripción |
|---|---|
| `app/Models` | Contiene los modelos Eloquent que representan las tablas de la base de datos. |
| `app/Filament/Resources` | Contiene los recursos CRUD creados con Filament. |
| `app/Providers` | Configuración de proveedores, incluyendo el panel administrativo. |
| `config` | Archivos de configuración del proyecto Laravel. |
| `database/migrations` | Migraciones utilizadas por Laravel para las tablas del esquema de aplicación. |
| `routes` | Archivos de rutas de la aplicación. |
| `resources` | Vistas y recursos frontend del proyecto. |
| `public` | Punto de entrada público de Laravel. |
| `.env.example` | Plantilla de variables de entorno sin credenciales reales. |
| `.gitignore` | Archivo para excluir carpetas sensibles o pesadas del repositorio. |

---

## 6. Módulos CRUD implementados

Durante la defensa del proyecto se destacaron los módulos CRUD relacionados con el negocio. Entre los recursos implementados en la GUI se encuentran:

### 6.1. Módulo de ventas

- Planes.
- Paquetes.
- Línea Plan.
- Promociones.
- Promoción Aplicada.
- Bono Promocional.
- Plan Corporativo.

Estos módulos permiten administrar información comercial relacionada con planes, paquetes, promociones y beneficios aplicados a líneas telefónicas.

### 6.2. Módulo de finanzas

- Budget.
- Recargas.
- Facturas.
- Préstamos.
- Pagos de préstamos.

Estos recursos permiten visualizar y gestionar información financiera asociada a líneas, presupuestos, pagos, recargas y facturación.

### 6.3. Módulo de clientes

- Clientes.
- Clientes corporativos.
- Líneas telefónicas.
- Dispositivos.
- Consumos.

Estos recursos permiten consultar información relacionada con los usuarios del servicio, sus líneas, dispositivos y consumo.

### 6.4. Módulo de seguridad y usuarios

- Usuarios de la GUI.
- Tipos de usuario.
- Relación entre usuarios y líneas asignadas.

Este módulo permite controlar qué usuarios pueden ingresar a la GUI y qué información pueden visualizar según su perfil.

---

## 7. Control de acceso en la GUI

La GUI fue diseñada considerando diferentes tipos de usuario, por ejemplo:

- **Gerente:** acceso amplio a la información de gestión.
- **Analista:** acceso orientado a consulta y análisis.
- **Empleado:** acceso limitado según las líneas o registros asignados.

Desde Laravel y Filament se aplican restricciones para mostrar u ocultar recursos del menú según el tipo de usuario autenticado.  
Además, la base de datos PostgreSQL mantiene controles adicionales mediante roles, privilegios y políticas de seguridad.

---

## 8. Relación con la base de datos PostgreSQL

La aplicación se conecta a PostgreSQL mediante las variables de entorno configuradas localmente en el archivo `.env`.

Ejemplo de variables requeridas:

```env
DB_CONNECTION=pgsql
DB_HOST=127.0.0.1
DB_PORT=5433
DB_DATABASE=Viva
DB_USERNAME=usuario_gui
DB_PASSWORD=contraseña_local
```

> El archivo `.env` no debe subirse a GitHub.  
> Solo debe mantenerse el archivo `.env.example` como plantilla.

---

## 9. Archivos que no deben subirse al repositorio

Por seguridad y buenas prácticas, este repositorio no debe incluir:

```text
.env
vendor/
node_modules/
storage/logs/
*.sql
*.backup
*.tar.gz
*.zip
```

Estos archivos pueden contener credenciales, datos sensibles, dependencias pesadas o respaldos de base de datos.

---

## 10. Instalación del proyecto en otro entorno

Para ejecutar el proyecto en otro equipo, se deben seguir estos pasos generales:

### 10.1. Clonar el repositorio

```bash
git clone URL_DEL_REPOSITORIO
cd viva-gui
```

### 10.2. Instalar dependencias PHP

```bash
composer install
```

### 10.3. Crear archivo de entorno

```bash
cp .env.example .env
```

En Windows PowerShell:

```powershell
copy .env.example .env
```

### 10.4. Configurar la conexión a PostgreSQL

Editar el archivo `.env` y colocar los datos reales de conexión a la base de datos.

### 10.5. Generar la llave de Laravel

```bash
php artisan key:generate
```

### 10.6. Ejecutar migraciones, si corresponde

```bash
php artisan migrate
```

### 10.7. Levantar el servidor local

```bash
php artisan serve
```

Luego ingresar desde el navegador a:

```text
http://127.0.0.1:8000
```

---

## 11. Aspectos defendidos en la exposición

En la defensa del proyecto se explicó:

- La arquitectura general de la GUI.
- La conexión entre Laravel, Filament y PostgreSQL.
- La organización del código por modelos y recursos.
- Los módulos CRUD implementados.
- La separación entre lógica de aplicación y seguridad de base de datos.
- La importancia de no exponer credenciales en GitHub.
- El uso de GitHub como repositorio de versionamiento del código.

---

## 12. Conclusión

La GUI desarrollada permite administrar módulos importantes del sistema Viva mediante una interfaz web clara y funcional.  
Laravel aporta la estructura del proyecto, Filament facilita la creación de pantallas CRUD y PostgreSQL mantiene la seguridad, organización y persistencia de los datos.

Este repositorio representa el código fuente de la interfaz defendida en el proyecto, dejando evidencia del trabajo realizado y permitiendo su revisión, mantenimiento y mejora futura.
