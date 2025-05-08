#!/bin/bash

# -----------------------------------------------------------------------------
# Nombre: airflow_cheatsheet.sh
# Descripción: Menú interactivo con los comandos más comunes de Airflow
#              usando Docker Compose (soporta v1 y v2).
# Autor: Profesor de Airflow
# Uso: ./airflow_cheatsheet.sh
# -----------------------------------------------------------------------------

# Detectar si usar 'docker-compose' o 'docker compose'
if command -v docker-compose &> /dev/null; then
  COMPOSE="docker-compose"
elif docker compose version &> /dev/null; then
  COMPOSE="docker compose"
else
  echo "ERROR: Ni 'docker-compose' ni 'docker compose' están instalados."
  echo "Instala Docker Compose para continuar."
  exit 1
fi

show_menu() {
  echo ""
  echo "================ Apache Airflow Cheat Sheet ================"
  echo "1. Listar DAGs disponibles"
  echo "2. Ver errores de importación de DAGs"
  echo "3. Ver logs del worker"
  echo "4. Ver logs del scheduler"
  echo "5. Reiniciar el scheduler"
  echo "6. Reiniciar el apiserver"
  echo "7. Ejecutar un DAG manualmente"
  echo "8. Salir"
  echo "============================================================"
  echo ""
}

read_choice() {
  read -p "Seleccioná una opción [1-8]: " opcion
  case $opcion in
    1)
      echo "Listando DAGs..."
      $COMPOSE exec airflow-apiserver airflow dags list
      ;;
    2)
      echo "Mostrando errores de importación de DAGs..."
      $COMPOSE exec airflow-apiserver airflow dags list-import-errors
      ;;
    3)
      echo "Mostrando los últimos logs del worker..."
      $COMPOSE logs --tail=50 airflow-worker
      ;;
    4)
      echo "Mostrando los últimos logs del scheduler..."
      $COMPOSE logs --tail=50 airflow-scheduler
      ;;
    5)
      echo "Reiniciando el scheduler..."
      $COMPOSE restart airflow-scheduler
      ;;
    6)
      echo "Reiniciando el apiserver..."
      $COMPOSE restart airflow-apiserver
      ;;
    7)
      read -p "Ingresá el ID del DAG a ejecutar: " dag_id
      $COMPOSE exec airflow-apiserver airflow dags trigger "$dag_id"
      ;;
    8)
      echo "Saliendo del script."
      exit 0
      ;;
    *)
      echo "Opción inválida. Por favor, ingresá un número del 1 al 8."
      ;;
  esac
}

# Bucle principal
while true; do
  show_menu
  read_choice
done
