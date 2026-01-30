#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# Runner (we require root, so no sudo is needed)
SUDO=""

# Colors
PURPLE=$(tput setaf 125) # Definir un color púrpura
RED=$(tput setaf 1) # Definir un color rojo
GREEN=$(tput setaf 2) # Definir un color verde
WHITE=$(tput setaf 7) # Definir un color blanco
CYAN=$(tput setaf 5) # Definir un color cian
YELLOW=$(tput setaf 3) # Definir un color amarillo
BLUE=$(tput setaf 4) # Definir un color azul
RESET=$(tput sgr0) # Restablecer todos los colores


# UI Language (default Spanish). Choose at startup.
LANG_UI="es"

function choose_language() {
  clear || true
  echo -e "${PURPLE}Certkit-Blackforge${RESET}"
  echo -e "${CYAN}Author: – ラストドラゴン  (@Bl4ckd34thz) | X: https://x.com/bl4ckd34thz${RESET}"
  echo ""
  echo -e "${YELLOW}[1]${RESET} Español"
  echo -e "${YELLOW}[2]${RESET} English"
  echo ""
  read -r -p "Selecciona idioma / Select language [1-2] (default=1): " _lang || true
  case "${_lang:-1}" in
    2|en|EN|english|English) LANG_UI="en" ;;
    *) LANG_UI="es" ;;
  esac
}

# Text helper (minimal i18n)
function ui() {
  # usage: ui "es text" "en text"
  if [[ "${LANG_UI}" == "en" ]]; then
    printf "%s" "$2"
  else
    printf "%s" "$1"
  fi
}


# Función para manejar la señal INT (Ctrl-C)
function ctrl_c() {
  printf "
${YELLOW}[*]${RESET} ${BLUE}$(ui 'Finalizando ejecución del programa...' 'Ending program execution...')${RESET}
"
  tput cnorm
  exit 0
}

trap ctrl_c INT

# Función para verificar y descargar dependencias
function detect_pkg_manager() {
  # Returns package manager command name via echo: apt-get, dnf, yum, pacman, zypper, apk, emerge, brew, unknown
  if command -v apt-get >/dev/null 2>&1; then echo "apt-get"; return; fi
  if command -v dnf >/dev/null 2>&1; then echo "dnf"; return; fi
  if command -v yum >/dev/null 2>&1; then echo "yum"; return; fi
  if command -v pacman >/dev/null 2>&1; then echo "pacman"; return; fi
  if command -v zypper >/dev/null 2>&1; then echo "zypper"; return; fi
  if command -v apk >/dev/null 2>&1; then echo "apk"; return; fi
  if command -v emerge >/dev/null 2>&1; then echo "emerge"; return; fi
  if command -v brew >/dev/null 2>&1; then echo "brew"; return; fi
  echo "unknown"
}

function install_packages() {
  local pm="$1"; shift
  local pkgs=("$@")

  case "$pm" in
    apt-get)
      ${SUDO}apt-get update -y >/dev/null 2>&1 || true
      ${SUDO}apt-get install -y "${pkgs[@]}"
      ;;
    dnf)
      ${SUDO}dnf install -y "${pkgs[@]}"
      ;;
    yum)
      ${SUDO}yum install -y "${pkgs[@]}"
      ;;
    pacman)
      ${SUDO}pacman -Sy --noconfirm "${pkgs[@]}"
      ;;
    zypper)
      ${SUDO}zypper -n install "${pkgs[@]}"
      ;;
    apk)
      ${SUDO}apk add --no-cache "${pkgs[@]}"
      ;;
    emerge)
      ${SUDO}emerge --quiet "${pkgs[@]}"
      ;;
    brew)
      brew install "${pkgs[@]}"
      ;;
    *)
      return 1
      ;;
  esac
}

# Función para verificar y (si es posible) instalar dependencias en múltiples distros
function dependencies() {
  tput civis # Ocultar el cursor
  clear

  local pm
  pm="$(detect_pkg_manager)"

  # Dependencias base para el script (keytool viene con java/jre)
  local deps_cmds=("openssl" "curl" "nc" "base64" "java")

  printf "${YELLOW}[*]${RESET} ${BLUE}Comprobando programas necesarios...${RESET}
"
  sleep 1

  for program in "${deps_cmds[@]}"; do
    printf "
${YELLOW}[*]${RESET}${BLUE} Tool${RESET}${PURPLE} %s${RESET}${BLUE}..." "$program"
    if command -v "$program" >/dev/null 2>&1; then
      printf " ${GREEN}(Instalado)${RESET}
"
      continue
    fi

    printf " ${RED}(No instalado)${RESET}
"

    # Mapeo simple de comando -> paquete (puede variar por distro, pero suele funcionar)
    local pkg="$program"
    case "$program" in
      nc) pkg="netcat" ;;
      java) pkg="default-jre" ;;
    esac

    printf "${YELLOW}[*]${RESET}${CYAN} Instalando ${RESET}${BLUE}%s${RESET}${YELLOW}...${RESET}
" "$pkg"

    if [[ "$pm" == "unknown" ]]; then
      printf "${RED}No pude detectar el gestor de paquetes. Instala manualmente: %s${RESET}
" "${deps_cmds[*]}"
      exit 1
    fi

    # Ajustes por distro
    if [[ "$pm" == "dnf" || "$pm" == "yum" ]]; then
      [[ "$program" == "java" ]] && pkg="java-11-openjdk-headless"
      [[ "$program" == "nc" ]] && pkg="nc"
    elif [[ "$pm" == "pacman" ]]; then
      [[ "$program" == "java" ]] && pkg="jre-openjdk-headless"
      [[ "$program" == "nc" ]] && pkg="openbsd-netcat"
    elif [[ "$pm" == "zypper" ]]; then
      [[ "$program" == "java" ]] && pkg="java-11-openjdk-headless"
      [[ "$program" == "nc" ]] && pkg="netcat-openbsd"
    elif [[ "$pm" == "apk" ]]; then
      [[ "$program" == "java" ]] && pkg="openjdk11-jre-headless"
      [[ "$program" == "nc" ]] && pkg="netcat-openbsd"
    elif [[ "$pm" == "apt-get" ]]; then
      [[ "$program" == "nc" ]] && pkg="netcat-openbsd"
      [[ "$program" == "java" ]] && pkg="default-jre-headless"
    fi

    if ! install_packages "$pm" "$pkg" >/dev/null 2>&1; then
      printf "${RED}No se pudo instalar '%s' usando %s. Instálalo manualmente y vuelve a ejecutar.${RESET}
" "$pkg" "$pm"
      exit 1
    fi

    printf " ${GREEN}(Instalado)${RESET}
"
    sleep 0.5
  done
}
##########################################################################################################################################################################################################
center_print() {
    local term_width
    term_width=$(tput cols 2>/dev/null || echo 80)

    while IFS= read -r line; do
        local clean_line
        clean_line=$(echo -e "$line" | sed 's/\x1B\[[0-9;]*[a-zA-Z]//g')

        local line_length=${#clean_line}
        if (( line_length < term_width )); then
            local padding=$(( (term_width - line_length) / 2 ))
            printf "%*s%s\n" "$padding" "" "$line"
        else
            echo -e "$line"
        fi
    done
}

function ascii_start() {
    clear

    local RESET="\033[0m"
    local GREEN_HACKER="\033[38;5;46m"
    local CYAN="\033[36m"
    local PURPLE="\033[35m"

    echo -e "${GREEN_HACKER}"

    center_print << 'EOF'
 ______________________________________________
 < Tool: Certkit-Blackforge >
 < Script Author: – ラストドラゴン @Bl4ckD34thz >
 < Version: 4.0 >
 ______________________________________________

⠀⠀⠀⠀⠀⠀⠀⣀⣤⣴⣶⣶⣶⣿⣿⣿⣷⣶⣶⣶⣤⣄⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣤⡀⠀⠀⠀⠀
⠀⠀⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣄⠀⠀⠀
⠀⣠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀⠀
⢰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⡀
⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣇
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡏⠉⠙⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠋⠉⠉⣿⣿
⢻⣿⡇⠀⠀⠀⠈⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠋⠀⠀⠀⠀⢀⣿⡇
⠘⣿⣷⡀⠀⠀⠀⠀⠀⠀⠉⠛⠿⢿⣿⣿⣿⠿⠛⠋⠀⠀⠀⠀⠀⠀⢀⣼⣿⠃
⠀⠹⣿⣿⣶⣦⣤⣀⣀⣀⣀⣀⣤⣶⠟⡿⣷⣦⣄⣀⣀⣀⣠⣤⣤⣶⣿⣿⡟⠀
⠀⠀⣨⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠏⠀⡇⠸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀
⠀⢈⣿⣿⣿⣿⣿⡿⠿⠿⣿⣿⣷⠀⣼⣷⠀⣸⣿⣿⣿⡿⠿⠿⠿⣿⣿⣿⡇⠀
⠀⠘⣿⣿⣿⡟⠋⠀⠀⠰⣿⣿⣿⣷⣿⣿⣷⣿⣿⣿⣿⡇⠀⠀⠀⣿⣿⠟⠁⠀
⠀⠀⠈⠉⠀⠈⠁⠀⠀⠘⣿⣿⢿⣿⣿⢻⣿⡏⣻⣿⣿⠃⠀⠀⠀⠈⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⡇⣿⣿⢸⣿⡇⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⡇⣿⣿⢸⣿⡇⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⡇⣿⣿⢸⣿⡇⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⡇⣿⣿⢸⣿⠃⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⡇⣿⣿⢸⣿⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠿⠇⢿⡿⢸⡿⠀⠿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀

Certkit-Blackforge
Author: – ラストドラゴン (@Bl4ckd34thz) | X: https://x.com/bl4ckd34thz
EOF

    echo -e "${RESET}"
    MenuCert
}
##########################################################################################################################################################################################################

function MenuCert() {
  local options_es=(
    "Crear Certificado Keytool"
    "Crear Request para Certificados (.key y .csr)"
    "Crear Request para Certificados SAN (.key y .csr)"
    "Crear Certificado Self-Signed (Servidor)"
    "Crear CA Local (Root)"
    "Crear Certificado Cliente (mTLS)"
    "Crear Certificado P12 (.p12)"
    "Crear certificado PFX (.pfx)"
    "Crear Certificado PEM (.pem)"
    "Firmar Certificado con Let's Encrypt"
    "Wildcard Let's Encrypt (DNS-01)"
    "Salir"
  )

  local options_en=(
    "Create Keytool Certificate"
    "Create CSR Request (.key and .csr)"
    "Create CSR Request with SAN (.key and .csr)"
    "Create Self-Signed Server Certificate"
    "Create Local Root CA"
    "Create Client Certificate (mTLS)"
    "Create P12 (.p12)"
    "Create PFX (.pfx)"
    "Create PEM (.pem)"
    "Sign CSR with Let's Encrypt"
    "Let's Encrypt Wildcard (DNS-01)"
    "Exit"
  )

  local options=()
  if [[ "${LANG_UI}" == "en" ]]; then
    options=("${options_en[@]}")
    PS3="Select an option: "
  else
    options=("${options_es[@]}")
    PS3="Selecciona una opción: "
  fi

  echo -e "${YELLOW}"
  echo -e "  ************************************************************************************************************"
  if [[ "${LANG_UI}" == "en" ]]; then
    echo -e "                                   Hello! Welcome to Certkit-Blackforge."
    echo -e "                                     Select an option to continue..."
  else
    echo -e "                                   ¡Hola! Te damos la bienvenida a Certkit-Blackforge."
    echo -e "                                     Selecciona una opción para continuar..."
  fi
  echo -e "  ************************************************************************************************************"
  echo -e "${RESET}"

  select opt in "${options[@]}"; do
    case "${REPLY}" in
      1) clear; MenuCertKeytool ;;
      2) create_certificate_request ;;
      3) create_request_sam ;;
      4) create_self_signed_server ;;
      5) create_local_ca_root ;;
      6) create_client_cert_mtls ;;
      7) CreateFileP12 ;;
      8) create_cert_pfx ;;
      9) CreatePemFile ;;
      10) sign_certificate_request ;;
      11) le_wildcard_dns01 ;;
      12) exit 0 ;;
      *)
        if [[ "${LANG_UI}" == "en" ]]; then
          echo "Error: \"${REPLY}\" is not a valid option."
        else
          echo "Error: \"${REPLY}\" no es una opción válida."
        fi
        ;;
    esac
  done
}
##########################################################################################################################################################################################################



function MenuCertKeytool() {
clear
PS3="Selecciona una operación: "

echo -e "${PURPLE}************************************************************************************************************
                                   ¡Hola! En este apartado podras crear certificados (.jks/.keystore).
                                   Para crear el certificado debes ir por pasos del 1,2,3,4,5
                                     Selecciona una opción para continuar...
Descripcion de funciones...

(1) Generar .jks|.keystore las dos extensiones son iguales, considera renombrar al final
(2) Generar csr del .jks
(3) Conocer la ruta completa de java cacerts
(4) Ingresar certificado a cacerts
(5) Sobreescribir certificado

************************************************************************************************************${RESET}"
    
    select opt in "Crear" "Csr" "Ruta" "Cacert" "Sobreescribir" "Menú principal" "Salir";
    do
        case $opt in
            "Crear")
                CrearKeytool
                ;;

            "Csr")
                GenerarSolicitud
                ;;

            "Ruta")
                RutaCacerts
                ;;

            "Cacert")
                InsertarCertificados
                ;;

            "Sobreescribir")
                SobreescribirCertificado
                ;;

            "Menú principal")
                ascii_start
                ;;

            "Salir")
                exit 0
                ;;

            *)
                echo "$REPLY no es una operación válida"
                ;;
        esac
    done
}


##########################################################################################################################################################################################################
function CrearKeytool() {
  read -p "Ingresa el nombre común (Common Name) Ej: www.ejemplo.com: " cn

  # Verificar si ya existe un archivo de almacén de claves con el mismo nombre
  if [[ -f "${cn}.jks" ]]; then
    read -p "El archivo ${cn}.jks ya existe. ¿Quieres sobrescribirlo? [s/n]: " confirm
    if [[ "${confirm}" != "s" ]]; then
      echo "No se creó el archivo de almacén de claves."
      return 1
    fi
  fi

  # Crear el archivo de almacén de claves
  keytool -genkey -alias "${cn}" -keyalg RSA -keystore "${cn}.jks" -keysize 2048 -deststoretype jks
  

  echo -e "\033[32mEl archivo de almacén de claves se ha creado correctamente: ${cn}.jks\033[0m\n"
  /usr/bin/ls -la ${cn}.jks
}
##########################################################################################################################################################################################################
function GenerarSolicitud() {
  read -p "Ingresa el nombre común (Common Name) para generar la solicitud de certificado: " cn
  read -p "Ingresa la contraseña que ingresaste cuando generaste el archivo .JKS: " password

  # Verificar si ya existe un archivo de solicitud de certificado con el mismo nombre
  if [[ -f "${cn}.csr" ]]; then
    read -p "El archivo ${cn}.csr ya existe. ¿Quieres sobrescribirlo? [s/n]: " confirm
    if [[ "${confirm}" != "s" ]]; then
      echo "No se generó la solicitud de certificado."
      return 1
    fi
  fi

  # Generar la solicitud de certificado
  keytool -certreq -alias "${cn}" -keystore "${cn}.jks" -file "${cn}.csr" --storepass "${password}"

  # Mostrar un mensaje de confirmación
  echo -e "\033[32mLa solicitud de certificado se ha generado correctamente: ${cn}.csr\033[0m\n"
  cat ${cn}.csr

}
##########################################################################################################################################################################################################
function RutaCacerts() {
  echo "$(ui 'Buscando el archivo cacerts predeterminado de Java...' 'Searching for Java default cacerts file...')"
  sleep 1

  local found=0
  local -a candidates=()

  # Try JAVA_HOME first
  if [[ -n "${JAVA_HOME:-}" ]]; then
    candidates+=("${JAVA_HOME}/lib/security/cacerts")
    candidates+=("${JAVA_HOME}/jre/lib/security/cacerts")
  fi

  # Infer from java binary location
  local java_bin=""
  java_bin="$(command -v java 2>/dev/null || true)"
  if [[ -n "$java_bin" ]]; then
    local real_java=""
    real_java="$(readlink -f "$java_bin" 2>/dev/null || echo "$java_bin")"
    local jhome=""
    jhome="$(dirname "$(dirname "$real_java")")"
    candidates+=("${jhome}/lib/security/cacerts")
    candidates+=("${jhome}/jre/lib/security/cacerts")
  fi

  # Common distro locations
  candidates+=("/etc/ssl/certs/java/cacerts")
  candidates+=("/etc/pki/java/cacerts")

  # Glob common JVM trees (fast)
  for p in /usr/lib/jvm/*/lib/security/cacerts /usr/lib/jvm/*/jre/lib/security/cacerts            /usr/java/*/lib/security/cacerts /usr/local/java/*/lib/security/cacerts            /opt/java/*/lib/security/cacerts /opt/jdk*/lib/security/cacerts; do
    [[ -e "$p" ]] && candidates+=("$p")
  done

  # De-duplicate while preserving order
  local -a uniq=()
  local seen="|"
  for p in "${candidates[@]}"; do
    [[ -z "$p" ]] && continue
    # normalize consecutive spaces/newlines
    if [[ "$seen" != *"|$p|"* ]]; then
      uniq+=("$p")
      seen+="$p|"
    fi
  done

  echo ""
  echo "$(ui 'Rutas detectadas:' 'Detected paths:')"

  for p in "${uniq[@]}"; do
    if [[ -f "$p" ]]; then
      printf "  - %s
" "$p"
      found=1
    fi
  done

  # If nothing found, do a constrained find (avoid scanning entire / and avoid pipefail exits)
  if [[ $found -eq 0 ]]; then
    echo ""
    echo "$(ui 'No encontré cacerts en ubicaciones comunes. Probando búsqueda rápida en /usr/lib/jvm, /etc, /opt...' 'Not found in common locations. Trying a quick search under /usr/lib/jvm, /etc, /opt...')"

    # Constrain search roots to reduce time; never fail the script
    local results=""
    results="$(find /usr/lib/jvm /etc /opt /usr/java /usr/local/java -type f -name cacerts 2>/dev/null || true)"

    if [[ -n "$results" ]]; then
      echo "$(ui 'Encontrado:' 'Found:')"
      # Print line by line safely
      while IFS= read -r line; do
        [[ -n "$line" ]] && printf "  - %s
" "$line"
      done <<< "$results"
      found=1
    fi
  fi

  if [[ $found -eq 0 ]]; then
    echo ""
    echo "$(ui 'No se pudo encontrar el archivo cacerts. Si tienes JAVA_HOME, ejecútalo así: JAVA_HOME=/ruta/jvm ./Certkit-Blackforge.sh' 'Could not find cacerts. If you have JAVA_HOME, run: JAVA_HOME=/path/to/jvm ./Certkit-Blackforge.sh')"
  fi


  echo ""
  read -r -p "$(ui 'Presiona Enter para volver al menú...' 'Press Enter to return to the menu...')" _ || true
}


##########################################################################################################################################################################################################

function InsertarCertificados() {
    # Solicitar la ruta completa del archivo cacerts de Java por defecto
    read -rp "Ingresa la ruta completa del archivo cacerts de Java por defecto: " cacerts_path

    # Solicitar los nombres de los certificados y el Common Name
    read -rp "Ingresa el nombre sin extensión del certificado Root: " root_cert_name
    read -rp "Ingresa el nombre sin extensión del certificado CA: " ca_cert_name
    read -rp "Ingresa el nombre sin extensión del certificado firmado por la Entidad Certificadora: " signed_cert_name
    read -rp "Ingresa el Common Name del certificado: " cert_common_name

    # Importar los certificados al archivo cacerts usando el comando keytool
    for cert_name in "$root_cert_name" "$ca_cert_name" "$signed_cert_name"; do
        cert_file="${cert_name}.cer"
        if [ ! -f "$cert_file" ]; then
            echo "Error: El archivo $cert_file no existe."
            return 1
        fi

        keytool -importcert \
            -keystore "$cacerts_path" \
            -alias "$cert_name" \
            -file "$cert_file" \
            -storepass changeit || {
                echo "Error: No se pudo importar el certificado $cert_file."
                return 1
            }
    done
}
##########################################################################################################################################################################################################
function SobreescribirCertificado() {
    # Solicitar al usuario el Common Name del certificado
    read -rp "Ingresa el Common Name del certificado: " common_name
     read -rp "Ingresa el password del jks: " pass_jks

    # Verificar si el archivo .cer existe
    if [ ! -f "$common_name.cer" ]; then
        echo "Error: el archivo $common_name.cer no existe."
        MenuCertKeytool
        return
    fi

    # Verificar si el archivo .jks existe
    if [ ! -f "$common_name.jks" ]; then
        echo "Error: el archivo $common_name.jks no existe."
        #MenuCertKeytool
        return
    fi

    # Importar el certificado y sobrescribir el existente si ya existe
    keytool -import \
        -trustcacerts \
        -alias "$common_name" \
        -file "$common_name.cer" \
        -keystore "$common_name.jks" \
        -storepass "$pass_jks" \
        -noprompt

    # Verificar si la generación del certificado fue exitosa y mostrar el menú principal
    if [ $? -eq 0 ]; then
        echo "La generación del certificado fue exitosa."
    else
        echo "Error: no se pudo generar el certificado."
    fi


}

##########################################################################################################################################################################################################
# Función para validar si una cadena es un nombre de dominio válido
function is_valid_domain() {
  local domain="$1"
  local regex="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$"
  [[ $domain =~ $regex ]]
}

# Helpers para pedir datos (sin valores predefinidos/quemados)
function prompt_default() {
  local prompt="$1"
  local default="$2"
  local var
  read -r -p "$prompt [$default]: " var
  echo "${var:-$default}"
}

function prompt_required() {
  local prompt="$1"
  local var=""
  while [[ -z "$var" ]]; do
    read -r -p "$prompt: " var
  done
  echo "$var"
}

function collect_dn() {
  DN_C="$(prompt_default "C (Country)" "MX")"
  DN_ST="$(prompt_required "ST (State/Province)")"
  DN_L="$(prompt_required "L (Locality/City)")"
  DN_O="$(prompt_required "O (Organization)")"
  DN_OU="$(prompt_required "OU (Org Unit)")"
  DN_EMAIL="$(prompt_required "emailAddress")"
}

# Función para validar si una cadena es un número entero positivo
function is_positive_integer() {
  local number="$1"
  local regex="^[1-9][0-9]*$"
  [[ $number =~ $regex ]]
}

# Función principal para crear un certificado SSL auto-firmado
function create_request_sam() {
  # Solicita la SAN principal y valida el nombre de dominio ingresado
  while true; do
    read -p "Ingresa el valor de la SAN principal: " san_principal
    if is_valid_domain "$san_principal"; then
      break
    else
      echo "Por favor, ingresa un nombre de dominio válido."
    fi
  done

  # Solicita el número de DNS y valida que sea un número entero positivo
  while true; do
    read -p "Ingresa el numero de dns: " dns_count
    if is_positive_integer "$dns_count"; then
      break
    else
      echo "Por favor, ingresa un número entero positivo."
    fi
  done

  # Construye la lista de Subject Alternative Names (SAN)
  alt_names="DNS.1=$san_principal"$'\n'
  for ((counter = 2; counter <= dns_count; counter++)); do
    while true; do
      read -p "Ingresa el valor del $counter dns: " dns_value
      if is_valid_domain "$dns_value"; then
        break
      else
        echo "Por favor, ingresa un nombre de dominio válido."
      fi
    done
    alt_names+="DNS.$counter=$dns_value"$'\n'
  done

  # Pedir Subject (DN) sin valores predefinidos
  collect_dn

  # Crea la configuración para OpenSSL
  openssl_config=$(cat <<-EOF
  [req]
  default_bits = 2048
  prompt = no
  default_md = sha256
  req_extensions = req_ext
  distinguished_name = dn
  [ dn ]
  C=$DN_C
  ST=$DN_ST
  L=$DN_L
  O=$DN_O
  OU=$DN_OU
  emailAddress=$DN_EMAIL
  CN = $san_principal
  [req_ext]
  subjectAltName = @alt_names
  [ alt_names ]
  $alt_names
EOF
  )

  # Crea el certificado SSL auto-firmado utilizando OpenSSL
  openssl req -new -sha256 -nodes -out "$san_principal.csr" -newkey rsa:2048 -keyout "$san_principal.key" -config <(echo "$openssl_config")

  echo -e "${RED}********************************************************************************************************${RESET} \n"
  cat $san_principal.csr
  echo -e "${RED}********************************************************************************************************${RESET} \n"
  /usr/bin/ls -la $san_principal.csr
  /usr/bin/ls -la $san_principal.key
  echo -e "${RED}********************************************************************************************************${RESET} \n"
}
##########################################################################################################################################################################################################
function create_certificate_request() {
 # Solicita al usuario información necesaria para generar un certificado
  read -p "Ingrese el nombre común (ej. www.ejemplo.com): " COMMON_NAME
  BITS_DEFAULT=2048
  read -p "Ingrese el número de bits [por defecto $BITS_DEFAULT]: " BITS
  BITS=${BITS:-$BITS_DEFAULT}
  ALGORITHM_DEFAULT=sha256
  read -p "Ingrese el algoritmo de cifrado [por defecto $ALGORITHM_DEFAULT]: " ALGORITHM
  ALGORITHM=${ALGORITHM:-$ALGORITHM_DEFAULT}

  # Pedir Subject (DN) sin valores predefinidos
  collect_dn

  # Valida que el nombre común sea un nombre de dominio válido
  DOMAIN_REGEX="^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$"
  if [[ -z "$COMMON_NAME" ]]; then
    echo -e "\033[31mError: se requiere el nombre común.\033[0m"
    return 1
  elif [[ ! "$COMMON_NAME" =~ $DOMAIN_REGEX ]]; then
    echo -e "\033[31mError: el nombre común no es un nombre de dominio válido.\033[0m"
    return 1
  fi

  # Verifica que los bits sean válidos
  if [[ ! "$BITS" =~ ^[0-9]+$ ]]; then
    echo -e "\033[31mError: el número de bits debe ser un entero positivo.\033[0m"
    return 1
  fi

  # Verifica que el algoritmo sea válido
  if [[ ! "$ALGORITHM" =~ ^(sha256|sha512)$ ]]; then
    echo -e "\033[31mError: el algoritmo de cifrado debe ser sha256 o sha512.\033[0m"
    return 1
  fi

  # Genera el certificado usando openssl
  openssl req \
    -new \
    "-$ALGORITHM" \
    -nodes \
    -out "$COMMON_NAME.csr" \
    -newkey "rsa:$BITS" \
    -keyout "$COMMON_NAME.key" \
    -config <(printf "
[req]
default_bits = $BITS
prompt = no
default_md = $ALGORITHM
req_extensions = req_ext
distinguished_name = dn

[dn]
C=$DN_C
ST=$DN_ST
L=$DN_L
O=$DN_O
OU=$DN_OU
emailAddress=$DN_EMAIL
CN = $COMMON_NAME

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = $COMMON_NAME")

  # Verifica si se generó el certificado
  if [[ $? -ne 0 ]]; then
    echo -e "\033[31mError: no se pudo generar el certificado.\033[0m"
    return 1
  fi

echo -e "\033[32mCertificado generado exitosamente para $COMMON_NAME\033[0m"

echo -e "${RED}********************************************************************************************************${RESET} \n"
cat $COMMON_NAME.csr
echo -e "${RED}********************************************************************************************************${RESET} \n"
/usr/bin/ls -la $COMMON_NAME.csr
/usr/bin/ls -la $COMMON_NAME.key
echo -e "${RED}********************************************************************************************************${RESET} \n"
 
}
##########################################################################################################################################################################################################
function validate_input() {
    local prompt="$1"
    local extension="$2"

    while true; do
        read -p "$prompt" file_name
        if [[ -n "$file_name" && "$file_name" == *"$extension" ]]; then
            echo "$file_name"
            break
        else
            echo -e "${RED}El nombre del archivo debe tener la extensión $extension y no estar vacío. Por favor, intenta de nuevo.${RESET}"
        fi
    done
}

function create_cert_pfx() {
    echo -e "${RED}Advertencia:${RESET} Para crear un archivo .PFX, necesitas tener los siguientes archivos: primary.cer, key.key, root.cer y ca.cer. ¿Los tienes? Si es así, continúa...\n"

    pfx_name=$(validate_input "Introduce el nombre del archivo PFX (sin extensión): " "")
    private_key_file=$(validate_input "Introduce el nombre del archivo de la clave privada (con extensión .key): " ".key")
    cert_file=$(validate_input "Introduce el nombre del certificado firmado por la entidad certificadora (con extensión .cer): " ".cer")
    root_cert_file=$(validate_input "Introduce el nombre del archivo del certificado ROOT (con extensión .cer): " ".cer")
    ca_cert_file=$(validate_input "Introduce el nombre del archivo del certificado CA (con extensión .cer): " ".cer")

    if [[ -f "$private_key_file" && -f "$cert_file" && -f "$root_cert_file" && -f "$ca_cert_file" ]]; then
        openssl pkcs12 -export -out "${pfx_name}.pfx" -inkey "$private_key_file" -in "$cert_file" -certfile "$root_cert_file" -certfile "$ca_cert_file"

        echo -e "${GREEN}El archivo ${pfx_name}.pfx ha sido creado exitosamente.${RESET}"
    else
        echo -e "${RED}Error:${RESET} No se pudo encontrar uno o más de los archivos requeridos. Por favor, verifica los nombres de los archivos e intenta de nuevo."
    fi
}
##########################################################################################################################################################################################################
function CreateFileP12() {
    echo -e "${RED}Warning:${RESET} Para crear un archivo .P12 necesitas tener los siguientes archivos (primario.cer llave.key root.cer ca.cer). ¿Ya los tienes? Si es así, continúa... :\n"

    read -p "Ingresa el solo nombre del certificado ROOT: " x1
    read -p "Ingresa el solo nombre del certificado CA: " x2
    read -p "Ingresa el Nombre de la llave privada .KEY: " x3
    read -p "Ingresa el Nombre del certificado firmado por la CA: " x4

    # Validaciones
    for file in "$x1.cer" "$x2.cer" "$x3.key" "$x4.cer"; do
        if [ ! -f "$file" ]; then
            echo -e "${RED}Error:${RESET} No se encontró el archivo $file. Por favor verifica que exista y vuelva a intentarlo."
            return 1
        fi
    done

    cat "$x1.cer" "$x2.cer" > ca-root.cer
    openssl pkcs12 -export -inkey "$x3.key" -in "$x4.cer" -certfile ca-root.cer -out "$x2.p12"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Éxito:${RESET} El archivo .P12 ha sido creado correctamente."
    else
        echo -e "${RED}Error:${RESET} Ocurrió un error al crear el archivo .P12. Por favor, verifica los archivos y vuelve a intentarlo."
        return 1
    fi

    clear
    ascii_start
}

##########################################################################################################################################################################################################

function check_file_exists() {
    local file="$1"
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error:${RESET} No se encontró el archivo $file. Por favor verifica que exista y vuelva a intentarlo."
        return 1
    fi
    return 0
}

function create_pem_file() {
    local privateKey="$1"
    local primaryCert="$2"
    local intermediateCert="$3"
    local rootCert="$4"
    local outputFile="$5"

    check_file_exists "$privateKey" || return 1
    check_file_exists "$primaryCert" || return 1
    check_file_exists "$intermediateCert" || return 1
    check_file_exists "$rootCert" || return 1

    cat "$privateKey" "$primaryCert" "$intermediateCert" "$rootCert" > "$outputFile"
}

function CreatePemFile() {
    echo -e "${RED}Warning:${RESET} Para crear un archivo .Pem necesitas tener los siguientes archivos (${YELLOW}primario.cer llave.key root.cer ca.cer${RESET}) (${GREEN}¿Ya los tienes?${RESET}, si es así, continúa... \n"
    echo -e "${RED}Todos los nombres que ingreses deben ser con el nombre y la extensión de los certificados${RESET}\n"

    read -p "Ingresa el Nombre de la llave privada: " privateKey
    read -p "Ingresa el Nombre del certificado primario: " primaryCert
    read -p "Ingresa el Nombre del certificado intermedio CA: " intermediateCert
    read -p "Ingresa el Nombre del certificado raíz Root: " rootCert

    create_pem_file "$privateKey" "$primaryCert" "$intermediateCert" "$rootCert" "certificado.pem"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Éxito:${RESET} El archivo .Pem ha sido creado correctamente."
    else
        echo -e "${RED}Error:${RESET} Ocurrió un error al crear el archivo .Pem. Por favor, verifica los archivos y vuelve a intentarlo."
        return 1
    fi

}
##########################################################################################################################################################################################################
function check_port_open() {
    local host="$1"
    local port="$2"

    if nc -z -w 5 "$host" "$port" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

function ensure_acme_client() {
  # Prefer certbot; fallback to acme.sh
  if command -v certbot >/dev/null 2>&1; then
    echo "certbot"
    return 0
  fi

  local pm
  pm="$(detect_pkg_manager)"
  if [[ "$pm" != "unknown" ]]; then
    # Intentar instalar certbot por gestor de paquetes
    case "$pm" in
      apt-get) install_packages "$pm" "certbot" >/dev/null 2>&1 || true ;;
      dnf|yum) install_packages "$pm" "certbot" >/dev/null 2>&1 || true ;;
      pacman)  install_packages "$pm" "certbot" >/dev/null 2>&1 || true ;;
      zypper)  install_packages "$pm" "certbot" >/dev/null 2>&1 || true ;;
      apk)     install_packages "$pm" "certbot" >/dev/null 2>&1 || true ;;
    esac
  fi

  if command -v certbot >/dev/null 2>&1; then
    echo "certbot"
    return 0
  fi

  # Fallback: acme.sh (muy portable)
  if [[ -x "$HOME/.acme.sh/acme.sh" ]]; then
    echo "acme.sh"
    return 0
  fi

  if command -v curl >/dev/null 2>&1; then
    printf "${YELLOW}[*]${RESET} Instalando acme.sh en %s/.acme.sh ...
" "$HOME"
    curl -fsSL https://get.acme.sh | sh >/dev/null 2>&1 || return 1
    echo "acme.sh"
    return 0
  fi

  return 1
}

function sign_certificate_request() {
  # Reemplazo: firmar CSR con Let's Encrypt (ACME)
  echo -n "Ingresa la ruta al archivo .csr (PEM o DER): "
  read -r csr_file

  if [ ! -f "$csr_file" ]; then
    echo -e "${RED}Error:${RESET} No se encontró el archivo $csr_file."
    return 1
  fi

  local acme
  acme="$(ensure_acme_client)" || {
    echo -e "${RED}Error:${RESET} No pude preparar un cliente ACME (certbot/acme.sh)."
    return 1
  }

  echo -e "${YELLOW}[*]${RESET} Cliente ACME seleccionado: ${BLUE}${acme}${RESET}"
  echo -e "${PURPLE}Nota:${RESET} Let's Encrypt validará el/los dominios del CSR (CN/SAN). Necesitas que el servidor sea accesible para el challenge HTTP-01 o usar webroot."
  echo

  local mode
  read -r -p "Modo de validación (1=standalone (abre puerto 80), 2=webroot): " mode
  mode="${mode:-1}"

  local out_dir
  out_dir="$(pwd)/letsencrypt_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$out_dir"

  local cert_path="$out_dir/cert.pem"
  local chain_path="$out_dir/chain.pem"
  local fullchain_path="$out_dir/fullchain.pem"

  if [[ "$acme" == "certbot" ]]; then
    local email
    email="$(prompt_required "Email para registro/avisos Let's Encrypt")"

    if [[ "$mode" == "2" ]]; then
      local webroot
      webroot="$(prompt_required "Ruta webroot (donde vive .well-known), ej. /var/www/html")"

      certbot certonly --non-interactive --agree-tos --email "$email" \
        --csr "$csr_file" --webroot -w "$webroot" \
        --cert-path "$cert_path" --chain-path "$chain_path" --fullchain-path "$fullchain_path"
    else
      # standalone
      certbot certonly --non-interactive --agree-tos --email "$email" \
        --csr "$csr_file" --standalone \
        --cert-path "$cert_path" --chain-path "$chain_path" --fullchain-path "$fullchain_path"
    fi
  else
    local acme_sh="$HOME/.acme.sh/acme.sh"
    chmod +x "$acme_sh" >/dev/null 2>&1 || true

    if [[ "$mode" == "2" ]]; then
      local webroot
      webroot="$(prompt_required "Ruta webroot (donde vive .well-known), ej. /var/www/html")"
      "$acme_sh" --signcsr --csr "$csr_file" -w "$webroot" --home "$HOME/.acme.sh" --cert-file "$cert_path" --ca-file "$chain_path" --fullchain-file "$fullchain_path"
    else
      "$acme_sh" --signcsr --csr "$csr_file" --standalone --home "$HOME/.acme.sh" --cert-file "$cert_path" --ca-file "$chain_path" --fullchain-file "$fullchain_path"
    fi
  fi

  if [[ -s "$fullchain_path" && -s "$cert_path" ]]; then
    echo -e "${GREEN}Éxito:${RESET} Certificados generados en: ${BLUE}$out_dir${RESET}"
    echo -e "  - Cert:       $cert_path"
    echo -e "  - Chain:      $chain_path"
    echo -e "  - Fullchain:  $fullchain_path"
  else
    echo -e "${RED}Error:${RESET} No se generaron los archivos esperados. Revisa la salida del cliente ACME."
    return 1
  fi
}

##########################################################################################################################################################################################################
# Nuevas funciones: tipos de certificados adicionales

function create_self_signed_server() {
  echo -e "${CYAN}=== Certificado Self-Signed (Servidor) ===${RESET}"
  local cn days key_size out_dir
  cn="$(prompt_required 'Common Name (CN) ej: www.ejemplo.com')"
  days="$(prompt_default 'Días de validez' '365')"
  key_size="$(prompt_default 'Tamaño de llave RSA' '2048')"
  out_dir="$(prompt_default 'Directorio de salida' "$(pwd)/selfsigned_${cn}")"
  mkdir -p "$out_dir"

  local key="$out_dir/${cn}.key"
  local crt="$out_dir/${cn}.crt"

  openssl genrsa -out "$key" "$key_size"

  # Construir subject interactivo
  local C ST L O OU EMAIL
  C="$(prompt_default 'C (Country)' '')"
  ST="$(prompt_default 'ST (State/Province)' '')"
  L="$(prompt_default 'L (Locality/City)' '')"
  O="$(prompt_default 'O (Organization)' '')"
  OU="$(prompt_default 'OU (Org Unit)' '')"
  EMAIL="$(prompt_default 'emailAddress' '')"

  local subj="/CN=${cn}"
  [[ -n "$C" ]] && subj="/C=${C}${subj}"
  [[ -n "$ST" ]] && subj="/ST=${ST}${subj}"
  [[ -n "$L" ]] && subj="/L=${L}${subj}"
  [[ -n "$O" ]] && subj="/O=${O}${subj}"
  [[ -n "$OU" ]] && subj="/OU=${OU}${subj}"
  [[ -n "$EMAIL" ]] && subj="/emailAddress=${EMAIL}${subj}"

  openssl req -new -x509 -key "$key" -out "$crt" -days "$days" -sha256 -subj "$subj"

  echo -e "${GREEN}Listo:${RESET}"
  echo -e "  - Key:  ${BLUE}$key${RESET}"
  echo -e "  - Cert: ${BLUE}$crt${RESET}"
}

function create_local_ca_root() {
  echo -e "${CYAN}=== Crear CA Local (Root) ===${RESET}"
  local name days key_size out_dir
  name="$(prompt_required 'Nombre de la CA (ej: Blackforge Root CA)')"
  days="$(prompt_default 'Días de validez' '3650')"
  key_size="$(prompt_default 'Tamaño de llave RSA' '4096')"
  out_dir="$(prompt_default 'Directorio de salida' "$(pwd)/ca_root")"
  mkdir -p "$out_dir"

  local key="$out_dir/ca_root.key"
  local crt="$out_dir/ca_root.crt"

  openssl genrsa -out "$key" "$key_size"

  local C ST L O OU EMAIL
  C="$(prompt_default 'C (Country)' '')"
  ST="$(prompt_default 'ST (State/Province)' '')"
  L="$(prompt_default 'L (Locality/City)' '')"
  O="$(prompt_default 'O (Organization)' "$name")"
  OU="$(prompt_default 'OU (Org Unit)' 'PKI')"
  EMAIL="$(prompt_default 'emailAddress' '')"

  local subj="/CN=${name}"
  [[ -n "$C" ]] && subj="/C=${C}${subj}"
  [[ -n "$ST" ]] && subj="/ST=${ST}${subj}"
  [[ -n "$L" ]] && subj="/L=${L}${subj}"
  [[ -n "$O" ]] && subj="/O=${O}${subj}"
  [[ -n "$OU" ]] && subj="/OU=${OU}${subj}"
  [[ -n "$EMAIL" ]] && subj="/emailAddress=${EMAIL}${subj}"

  # Cert CA con basicConstraints CA:TRUE
  openssl req -x509 -new -nodes -key "$key" -sha256 -days "$days" -out "$crt" \
    -subj "$subj" \
    -addext "basicConstraints=critical,CA:TRUE" \
    -addext "keyUsage=critical,keyCertSign,cRLSign" \
    -addext "subjectKeyIdentifier=hash"

  echo -e "${GREEN}Listo:${RESET} CA Root creada:"
  echo -e "  - Key:  ${BLUE}$key${RESET}"
  echo -e "  - Cert: ${BLUE}$crt${RESET}"
}

function create_client_cert_mtls() {
  echo -e "${CYAN}=== Certificado Cliente (mTLS) firmado por CA local ===${RESET}"
  local ca_crt ca_key cn days out_dir key_size
  ca_crt="$(prompt_required 'Ruta CA Root cert (ca_root.crt)')"
  ca_key="$(prompt_required 'Ruta CA Root key  (ca_root.key)')"
  cn="$(prompt_required 'CN del cliente (ej: usuario01)')"
  days="$(prompt_default 'Días de validez' '825')"
  key_size="$(prompt_default 'Tamaño de llave RSA' '2048')"
  out_dir="$(prompt_default 'Directorio de salida' "$(pwd)/client_${cn}")"
  mkdir -p "$out_dir"

  local key="$out_dir/${cn}.key"
  local csr="$out_dir/${cn}.csr"
  local crt="$out_dir/${cn}.crt"

  openssl genrsa -out "$key" "$key_size"

  local C ST L O OU EMAIL
  C="$(prompt_default 'C (Country)' '')"
  ST="$(prompt_default 'ST (State/Province)' '')"
  L="$(prompt_default 'L (Locality/City)' '')"
  O="$(prompt_default 'O (Organization)' '')"
  OU="$(prompt_default 'OU (Org Unit)' 'Clients')"
  EMAIL="$(prompt_default 'emailAddress' '')"

  local subj="/CN=${cn}"
  [[ -n "$C" ]] && subj="/C=${C}${subj}"
  [[ -n "$ST" ]] && subj="/ST=${ST}${subj}"
  [[ -n "$L" ]] && subj="/L=${L}${subj}"
  [[ -n "$O" ]] && subj="/O=${O}${subj}"
  [[ -n "$OU" ]] && subj="/OU=${OU}${subj}"
  [[ -n "$EMAIL" ]] && subj="/emailAddress=${EMAIL}${subj}"

  openssl req -new -key "$key" -out "$csr" -subj "$subj"

  # Firmar con EKU clientAuth
  openssl x509 -req -in "$csr" -CA "$ca_crt" -CAkey "$ca_key" -CAcreateserial \
    -out "$crt" -days "$days" -sha256 \
    -extfile <(printf "basicConstraints=CA:FALSE\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=clientAuth\nsubjectKeyIdentifier=hash")

  echo -e "${GREEN}Listo:${RESET}"
  echo -e "  - Key:  ${BLUE}$key${RESET}"
  echo -e "  - CSR:  ${BLUE}$csr${RESET}"
  echo -e "  - Cert: ${BLUE}$crt${RESET}"
}

function le_wildcard_dns01() {
  echo -e "${CYAN}=== Wildcard Let's Encrypt (DNS-01) ===${RESET}"
  echo -e "${YELLOW}Nota:${RESET} Para wildcard (*.dominio.com) se requiere DNS-01. Aquí usamos ${GREEN}acme.sh${RESET}."

  ensure_command curl curl
  if ! command -v socat >/dev/null 2>&1; then
    ensure_command socat socat
  fi

  # Instalar acme.sh si no existe
  if [[ ! -x "$HOME/.acme.sh/acme.sh" ]]; then
    curl -sS https://get.acme.sh | sh
  fi

  local domain out_dir
  domain="$(prompt_required 'Dominio wildcard (ej: *.ejemplo.com)')"
  out_dir="$(prompt_default 'Directorio de salida' "$(pwd)/letsencrypt_wildcard")"
  mkdir -p "$out_dir"

  echo -e "${YELLOW}Te voy a mostrar el comando, y acme.sh te pedirá crear un TXT en tu DNS.${RESET}"
  echo -e "${BLUE}Sigue las instrucciones, crea el TXT y luego presiona Enter para continuar.${RESET}"

  "$HOME/.acme.sh/acme.sh" --issue --dns -d "$domain" --yes-I-know-dns-manual-mode-enough-go-ahead-please

  local base_domain=domain
  # Instalar cert a salida
  "$HOME/.acme.sh/acme.sh" --install-cert -d "$domain" \
    --key-file "$out_dir/privkey.pem" \
    --fullchain-file "$out_dir/fullchain.pem" \
    --cert-file "$out_dir/cert.pem" \
    --ca-file "$out_dir/chain.pem"

  echo -e "${GREEN}Éxito:${RESET} Certificados en: ${BLUE}$out_dir${RESET}"
}

##########################################################################################################################################################################################################
# Función Principal
main() {
  # Language selection
  choose_language

  # Verifica si el usuario es root
  if [ "$(id -u)" != "0" ]; then
    echo -e "${YELLOW}[*]${RESET} ${RED}$(ui 'Permiso denegado.' 'Permission denied.')${RESET} $(ui 'Debes ejecutar' 'You must run') ${PURPLE}Certkit-Blackforge${RESET} $(ui 'como root.' 'as root.')
"
    echo -e "    $(ui 'Ejemplo' 'Example'): ${CYAN}sudo ./Certkit-Blackforge.sh${RESET}
"
    exit 1
  fi

  # Limpia la pantalla
  clear

  # Instala las dependencias necesarias
  dependencies

  # Restaura la configuración del cursor
  tput cnorm

  # Ejecuta la función ascii_start
  ascii_start
}

# Llamada a la función principal
main

