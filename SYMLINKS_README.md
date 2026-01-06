# 🔗 Configuración de Symlinks para Prefect Workflows

Este documento explica cómo usar el script `setup_symlinks.py` para configurar automáticamente symlinks en Windows que mapeen los directorios de salida del proyecto a las rutas reales de OneDrive.

## 🎯 Problema que Resuelve

Cuando los workflows de Prefect se ejecutan en Windows, los archivos de salida se guardan en rutas relativas como `../outputs/cultivos/`, pero necesitamos que se guarden directamente en las rutas de OneDrive (por ejemplo: `C:/Users/Espartina/OneDrive - ESPARTINA S.A/DocumentacionEspartina/...`).

La solución es usar **symbolic links (symlinks)** que redirijan automáticamente de las rutas del proyecto a las rutas de OneDrive.

## 📋 Requisitos

- Python 3.7+
- Permisos de Administrador en Windows (para crear symlinks)

## 🚀 Uso del Script

### Paso 1: Ejecutar el Configurador

En tu máquina de desarrollo (Mac/Linux), ejecuta:

```bash
cd /ruta/al/proyecto/prefect-workflows
python setup_symlinks.py
```

### Paso 2: Configurar los Mappings

El script te pedirá que ingreses el path real de OneDrive para cada directorio de salida detectado en los workflows:

```
📍 Path del proyecto: ../outputs/cultivos
   Ingresa el path real de OneDrive donde debe mapear este directorio:
   Ejemplo: C:/Users/Espartina/OneDrive - ESPARTINA S.A/DocumentacionEspartina/...

   →
```

**Ingresa el path completo**, por ejemplo:
```
C:/Users/Espartina/OneDrive - ESPARTINA S.A/DocumentacionEspartina/PRODUCCION/Agricultura/GIS/Archivos de Consulta/cultivos
```

### Paso 3: Confirmar Path del Proyecto en Windows

Al final, el script te pedirá el path completo donde está el proyecto en la máquina Windows:

```
📍 ¿Cuál es el path completo del proyecto en la máquina Windows?
   Ejemplo: C:/Users/Espartina/Documents/prefect-workflows

   →
```

### Paso 4: Archivos Generados

El script genera dos archivos:

1. **`symlink_config.json`**: Configuración guardada con todos los mappings
   ```json
   {
     "../outputs/cultivos": "C:/Users/Espartina/OneDrive - ESPARTINA S.A/.../cultivos",
     "../outputs/muestreos": "C:/Users/Espartina/OneDrive - ESPARTINA S.A/.../muestreos"
   }
   ```

2. **`create_symlinks.ps1`**: Script de PowerShell listo para ejecutar en Windows

## 💻 Ejecutar en Windows

### 1. Copiar el Script a Windows

Copia el archivo `create_symlinks.ps1` a la máquina Windows en la carpeta del proyecto.

### 2. Abrir PowerShell como Administrador

- Busca "PowerShell" en el menú de inicio
- Haz clic derecho y selecciona "Ejecutar como administrador"

### 3. Navegar al Directorio del Proyecto

```powershell
cd C:\Users\Espartina\Documents\prefect-workflows
```

### 4. Ejecutar el Script

```powershell
.\create_symlinks.ps1
```

El script:
- ✅ Verificará que tienes permisos de Administrador
- ✅ Creará los directorios de destino en OneDrive si no existen
- ✅ Eliminará los directorios locales del proyecto (si existen)
- ✅ Creará symlinks desde el proyecto hacia OneDrive

## 🔄 Actualizar Configuración

Si agregas nuevos workflows con paths de salida adicionales:

1. Vuelve a ejecutar `python setup_symlinks.py`
2. El script detectará los nuevos paths automáticamente
3. Te preguntará solo por los paths nuevos (mantiene los anteriores)
4. Genera un nuevo `create_symlinks.ps1` actualizado
5. Ejecuta el script actualizado en Windows

## 📂 Directorios Detectados Automáticamente

El script detecta automáticamente estos directorios comunes:

- `../outputs/Backup_Databaler`
- `../outputs/cultivos`
- `../outputs/muestreos`
- `../outputs/sustentabilidad`
- `../outputs/KMZ POR CAMPO`
- `../outputs/KMZ POR CULTIVO CAMPO`
- `../outputs/KMZ POR CULTIVO LOTE`
- `../outputs/KMZ POR LOTE`

Y también escanea todos los archivos `.py` en `scripts/` para detectar paths adicionales.

## 🧪 Testing vs Producción

### Directorio `test_outputs/`

**IMPORTANTE:** El directorio `test_outputs/` **NO tiene symlinks** y es para desarrollo/testing local.

### Diferencia entre Modos

Los workflows de Prefect usan el parámetro `test` para determinar dónde guardar los archivos:

| Modo | Parámetro | Directorio | Symlinks | Ubicación Real |
|------|-----------|------------|----------|----------------|
| **Test** | `test=True` | `../test_outputs/` | ❌ No | Local (carpeta del proyecto) |
| **Production** | `test=False` | `../outputs/` | ✅ Sí | OneDrive (via symlinks) |

### Ejemplos

```python
# Modo TEST - guarda en carpeta local test_outputs/
backup_databaler_flow(campania="25/26", test=True)
# Resultado: archivos en prefect-workflows/test_outputs/

# Modo PRODUCTION - guarda en outputs/ que está linkeado a OneDrive
backup_databaler_flow(campania="25/26", test=False)
# Resultado: archivos en outputs/ → OneDrive (via symlink)
```

### ¿Por qué test_outputs/?

Antes de crear los symlinks, ambos modos usaban `../outputs`. Ahora:
- `outputs/` está linkeado a OneDrive (producción)
- `test_outputs/` permanece local (testing/desarrollo)

Esto evita que las pruebas locales sobrescriban datos de producción en OneDrive.

## ⚠️ Notas Importantes

### Permisos de Administrador

Los symlinks en Windows requieren permisos de Administrador. Si no ejecutas PowerShell como Administrador, el script fallará.

### Rutas de Windows

- Usa `/` o `\\` en los paths (el script normaliza automáticamente)
- Los paths deben ser absolutos (empezar con `C:/` o similar)
- Ejemplo válido: `C:/Users/Espartina/OneDrive - ESPARTINA S.A/...`

### Backup de Datos

Antes de ejecutar el script por primera vez, asegúrate de que:
- No hay datos importantes en los directorios locales `outputs/`
- Los directorios de OneDrive existen o pueden crearse
- Tienes espacio suficiente en OneDrive

### Testing vs Producción

Los workflows usan el parámetro `test` para cambiar entre paths relativos y absolutos:
- `test=True`: Usa `../outputs/` (para desarrollo local)
- `test=False`: Usa los symlinks que apuntan a OneDrive

En producción, siempre ejecuta con `test=False`.

## 🐛 Solución de Problemas

### Error: "No se puede crear el symlink"

- Verifica que PowerShell se esté ejecutando como Administrador
- Verifica que el directorio de destino exista
- Verifica que no haya un archivo/directorio con el mismo nombre

### Error: "Path no encontrado"

- Verifica que los paths ingresados sean correctos
- Verifica que las carpetas de OneDrive estén sincronizadas
- Usa paths absolutos completos

### Los archivos no se guardan en OneDrive

- Verifica que los symlinks existan: `dir` en PowerShell mostrará `<SYMLINK>` si funcionan
- Verifica que el workflow se ejecute con `test=False`
- Revisa los logs de Prefect para errores de permisos

## 📝 Ejemplo Completo

```bash
# En Mac/Linux
cd ~/prefect-workflows
python setup_symlinks.py

# Ingresar mappings cuando se soliciten:
# ../outputs/cultivos -> C:/Users/Espartina/OneDrive - ESPARTINA S.A/.../cultivos
# ../outputs/muestreos -> C:/Users/Espartina/OneDrive - ESPARTINA S.A/.../muestreos
# etc.

# Copiar create_symlinks.ps1 a Windows

# En Windows (PowerShell como Administrador)
cd C:\Users\Espartina\Documents\prefect-workflows
.\create_symlinks.ps1

# Verificar
dir outputs
# Debería mostrar <SYMLINK> para cada directorio
```

## 📧 Soporte

Si tienes problemas con el script:
1. Revisa los mensajes de error cuidadosamente
2. Verifica que todos los requisitos estén cumplidos
3. Consulta la sección de Solución de Problemas
