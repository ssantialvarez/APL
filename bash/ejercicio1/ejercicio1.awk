BEGIN{
    #print "Empieza procesamiento del archivo"
    # https://stackoverflow.com/questions/72811162/how-can-i-send-the-output-of-an-awk-script-to-a-file
    # tee = "tee ./temp/out.txt" 
    resultado = "{"
    fecha = ""
    canales[0] = "Chat"
    canales[1] = "Email"
    canales[2] = "Telefono"
    FS = "|"
}

function calculaPromedio(){
    # print fecha
    resultado = resultado "\""fecha"\"" ": {"
    for (x = 0; x < 3; x++) {
        contador = vector[canales[x], 2]
        
        if(contador > 0){
            # printf("%s\n", canales[x])
            
            # printf("%f\n", vector[canales[x], 0]/contador)
            t_prom = vector[canales[x], 0]/contador
            
            # printf("%f\n", vector[canales[x], 1]/contador)
            nota_prom = vector[canales[x], 1]/contador

            resultado = resultado "\""canales[x] "\": {\"tiempo_respuesta_promedio\": " t_prom ", \"nota_satisfaccion_promedio\": " nota_prom "}"
            
            if(x < 2)
                resultado = resultado ", "
            for (y = 0; y < 3; y++){
                vector[canales[x], y] = 0
            }
        }
    }

    resultado = resultado "} "
}

{
    # https://stackoverflow.com/questions/8009664/how-to-split-a-delimited-string-into-an-array-in-awk
    # Separa el campo fecha-hora segun el espacio entre la fecha y la hora, colocando ambos datos en un array llamado a.
    split($2,a," ");
    if (fecha == "")
        fecha = a[1]
    # print a[1] | tee
}

fecha != a[1]{
    calculaPromedio()
    resultado = resultado ", "
    fecha = a[1]
}

{
    # Almacena el 4to campo -> TIEMPO_RESPUESTA    
    vector[$3, 0] = $4
    # Almacena el 5to campo -> NOTA_SATISFACCION
    vector[$3, 1] = $5
    # Aumenta el contador del canal
    vector[$3, 2]++ 
}


END{
    calculaPromedio()
    resultado = resultado "}"
    print resultado
    # for (clave in b) {
        # print clave, palabras[clave]
        # printf("%s => %f\n", clave, b[clave]);
    # }
    # close(tee)
    # print "Termina procesamiento del archivo."
}