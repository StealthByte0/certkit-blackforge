=====================================================================
                         CERTKIT-BLACKFORGE
=====================================================================
Certkit-Blackforge es una herramienta todo-en-uno para la gestión de
certificados SSL/TLS en entornos Linux.

Está diseñada para administradores de sistemas, DevOps, SRE y equipos
de seguridad que necesitan crear, firmar, convertir e instalar
certificados de forma simple, guiada y portable.


---------------------------------------------------------------------
CARACTERÍSTICAS PRINCIPALES
---------------------------------------------------------------------

- Interfaz interactiva por menú
- Soporte multilenguaje (Español / English)
- Compatible con múltiples distribuciones Linux
- Gestión completa de certificados SSL/TLS
- Let’s Encrypt (ACME)
- CA interna (Root / certificados firmados)
- Certificados cliente (mTLS)
- Certificados Wildcard (*.dominio.com)
- Self-signed certificates
- Soporte para Java Keystore (cacerts)
- Detección automática de dependencias
- Banner estilo hacker verde Matrix
- Código portable, sin dependencias innecesarias


---------------------------------------------------------------------
DISTRIBUCIONES SOPORTADAS
---------------------------------------------------------------------

- Debian / Ubuntu
- Red Hat Enterprise Linux
- Rocky Linux
- AlmaLinux
- Arch Linux
- SUSE / openSUSE

El script detecta automáticamente la distribución e instala las
dependencias necesarias.


---------------------------------------------------------------------
REQUISITOS
---------------------------------------------------------------------

- Bash 4 o superior
- Acceso root
- OpenSSL
- curl

Opcional:
- certbot (Let’s Encrypt)
- acme.sh (para DNS-01 / wildcards)

Las dependencias se instalan automáticamente si no están presentes.


---------------------------------------------------------------------
INSTALACIÓN
---------------------------------------------------------------------

1. Clonar el repositorio:

   git clone https://github.com/StealthByte0/certkit-blackforge.git

2. Entrar al directorio:

   cd certkit-blackforge

3. Dar permisos de ejecución:

   chmod +x Certkit-Blackforge.sh

4. Ejecutar como root:

   sudo ./Certkit-Blackforge.sh


---------------------------------------------------------------------
USO GENERAL
---------------------------------------------------------------------

Al iniciar la herramienta:

1. Selecciona el idioma
2. Navega por el menú interactivo
3. Elige el tipo de certificado
4. Introduce los datos cuando el script los solicite

No es necesario memorizar comandos ni editar archivos manualmente.


---------------------------------------------------------------------
TIPOS DE CERTIFICADOS SOPORTADOS
---------------------------------------------------------------------

- Certificados SSL con Let’s Encrypt
- Certificados Wildcard (*.dominio.com)
- Certificados Self-Signed
- Root CA local
- Certificados firmados por CA interna
- Certificados cliente (mTLS)
- Exportación a formatos PEM y PFX
- Importación de certificados en Java cacerts


---------------------------------------------------------------------
ESTRUCTURA DEL PROYECTO
---------------------------------------------------------------------

certkit-blackforge/
|
|-- Certkit-Blackforge.sh
|-- README.txt
|-- docs/


---------------------------------------------------------------------
NOTAS IMPORTANTES
---------------------------------------------------------------------

- Para Let’s Encrypt HTTP-01 el puerto 80 debe estar disponible
- Para certificados Wildcard se recomienda usar DNS-01
- Ejecutar siempre como root
- No utilizar en producción sin entender el impacto de los cambios
- Respaldar siempre las llaves privadas generadas


---------------------------------------------------------------------
BUENAS PRÁCTICAS
---------------------------------------------------------------------

- Usar certificados cliente (mTLS) para APIs internas
- Usar CA interna en entornos cerrados
- Automatizar renovaciones cuando sea posible
- No compartir llaves privadas
- Mantener backups de certificados y claves


---------------------------------------------------------------------
AUTOR
---------------------------------------------------------------------

Author: – ラストドラゴン
Alias: @Bl4ckD34thz
X (Twitter): https://x.com/bl4ckd34thz


---------------------------------------------------------------------
LICENCIA
---------------------------------------------------------------------

Este proyecto se distribuye bajo la licencia  GNU GENERAL PUBLIC LICENSE

Puedes:
- Usarlo
- Modificarlo
- Distribuirlo
- Integrarlo en otros proyectos

Bajo tu propia responsabilidad.


---------------------------------------------------------------------
CONTRIBUCIONES
---------------------------------------------------------------------

Las contribuciones son bienvenidas.

Si encuentras un problema:
1. Abre un issue
2. Describe el entorno
3. Incluye logs (sin información sensible)


---------------------------------------------------------------------
DISCLAIMER
---------------------------------------------------------------------

Este software se proporciona "tal cual", sin garantías de ningún tipo.
El autor no se hace responsable por daños directos o indirectos
derivados del uso de esta herramienta.


=====================================================================
