#!/bin/bash

PROCESS_RECORD() {
    start_time=$(date +%s%3N)
    insertado=false
    motivo=""

    if [[ -z "$codcliente" ]]; then
        motivo="Codigo de cliente vacio"
    elif [[ -z "$nombre" ]]; then
        motivo="Nombre vacio"
    elif [[ -z "$fecha" ]] || ! date -d "$fecha" +%Y-%m-%d >/dev/null 2>&1; then
        motivo="Fecha invalida"
    elif [[ -z "$codproducto" ]]; then
        motivo="Codigo de producto vacio"
    else
        EXISTS=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "SELECT COUNT(*) FROM catalogo_de_productos WHERE codproducto='$codproducto';" 2>/dev/null)

        if [[ "$EXISTS" -eq 0 ]]; then
            motivo="Producto no existe"
        else
            CLIENT_EXISTS=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "SELECT COUNT(*) FROM cabecera_de_clientes WHERE codcliente='$codcliente';" 2>/dev/null)

            if [[ "$CLIENT_EXISTS" -eq 1 ]]; then
                motivo="Cliente repetido"
            else
                DETALLE_PROD_EXISTS=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "SELECT COUNT(*) FROM detalle_de_producto WHERE codproducto_de_cliente='$codproducto_de_cliente';" 2>/dev/null)

                if [[ "$DETALLE_PROD_EXISTS" -eq 1 ]]; then
                    motivo="Detalle producto repetido"
                else
                    DETALLE_CLI_EXISTS=$(mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "SELECT COUNT(*) FROM detalle_de_cliente WHERE codcliente='$codcliente' AND codproducto_de_cliente='$codproducto_de_cliente';" 2>/dev/null)

                    if [[ "$DETALLE_CLI_EXISTS" -eq 1 ]]; then
                        motivo="Detalle cliente repetido"
                    else
                        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "INSERT INTO cabecera_de_clientes (codcliente, nombre_cliente, apellidos_cliente, tipo_cliente, fecha) VALUES ('$codcliente', '$nombre', '$apellidos', '$tipo', '$fecha');" 2>/dev/null

                        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "INSERT INTO detalle_de_cliente (codcliente, codproducto_de_cliente, descripcion_atributo, fecha) VALUES ('$codcliente', '$codproducto_de_cliente', '$descripcion_atributo', '$fecha');" 2>/dev/null

                        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "INSERT INTO detalle_de_producto (codproducto_de_cliente, codcliente, codproducto, descripcion_atributo, fecha) VALUES ('$codproducto_de_cliente', '$codcliente', '$codproducto', '$descripcion_atributo', '$fecha');" 2>/dev/null

                        insertado=true
                    fi
                fi
            fi
        fi
    fi

    end_time=$(date +%s%N)
    execution_time_ms=$(( (end_time - start_time) / 1000000 ))

    if [[ "$insertado" == true ]]; then
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "INSERT INTO registros (fecha, registro, observaciones, tiempo) VALUES (NOW(), 'script', 'Insertado correctamente - Cliente $codcliente', '${execution_time_ms}ms');" 2>/dev/null
    else
        mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -e "INSERT INTO registros (fecha, registro, observaciones, tiempo) VALUES (NOW(), 'script', 'Insertado incorrectamente - Cliente $codcliente - $motivo', '${execution_time_ms}ms');" 2>/dev/null
    fi
}

if [[ -z "$1" ]]; then
    echo "Usage: $0 <archivo.csv>"
    exit 1
fi

DATA_FILE="$1"

if [[ ! -f "$DATA_FILE" ]]; then
    echo "Error: Archivo '$DATA_FILE' no encontrado."
    exit 1
fi

DB_HOST="172.26.203.60"
DB_USER="root"
DB_PASS="Crylam2526+"
DB_NAME="crylam_db"

echo "Ejecutando script..."

EXT="${DATA_FILE##*.}"

case "$EXT" in
    csv)
        while IFS=',' read -r codcliente nombre apellidos tipo fecha codproducto codproducto_de_cliente descripcion_atributo; do
            [[ "$codcliente" == "codcliente" ]] && continue
            PROCESS_RECORD
        done < "$DATA_FILE"
        ;;
    json)
        jq -r '.[] | [.codcliente, .nombre, .apellidos, .tipo_cliente, .fecha, .codproducto, .codproducto_de_cliente, .descripcion_atributo] | join(",")' "$DATA_FILE" | while IFS=',' read -r codcliente nombre apellidos tipo fecha codproducto codproducto_de_cliente descripcion_atributo; do
            PROCESS_RECORD
        done
        ;;
    txt)
        while IFS=',' read -r codcliente nombre apellidos tipo fecha codproducto codproducto_de_cliente descripcion_atributo; do
            PROCESS_RECORD
        done < "$DATA_FILE"
        ;;
    *)
        echo "Error: Formato no soportado."
        exit 1
        ;;
esac

echo "Proceso completado."