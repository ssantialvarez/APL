BEGIN{
    resultado = "{"
    fecha = ""
    canales[0] = "Chat"
    canales[1] = "Email"
    canales[2] = "Telefono"
    FS = "|"
}

function calculaPromedio(){
    resultado = resultado "\""fecha"\"" ": {"
    for (x = 0; x < 3; x++) {
        contador = vector[canales[x], 2]
        
        if(contador > 0){
            t_prom = vector[canales[x], 0]/contador
            
            nota_prom = vector[canales[x], 1]/contador
    
            resultado = resultado "\""canales[x] "\": {\"tiempo_respuesta_promedio\": " sprintf("%.2f", t_prom) ", \"nota_satisfaccion_promedio\": " sprintf("%.2f", nota_prom) "}"
            printf("%s\t%s\t%.2f\t%.2f\n", fecha, canales[x], t_prom, nota_prom)
            if(x < 2)
                resultado = resultado ", "
            for (y = 0; y < 3; y++){
                vector[canales[x], y] = 0
            }
        }
    }
    
    resultado = resultado "}"
}

{
    # Separa el campo fecha-hora segun el espacio entre la fecha y la hora, colocando ambos datos en un array llamado a.
    split($2,a," ");
    
    if (fecha != a[1]){
        if(fecha != ""){
            calculaPromedio()
            resultado = resultado ", "
        }
        
        fecha = a[1]
    }

    # Almacena el 4to campo -> TIEMPO_RESPUESTA    
    vector[$3, 0] += $4
    # Almacena el 5to campo -> NOTA_SATISFACCION
    vector[$3, 1] += $5
    # Aumenta el contador del canal
    vector[$3, 2]++         
}



END{
    calculaPromedio()
    resultado = resultado "}"
    # print resultado
}