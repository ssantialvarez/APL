# Ejercicio 5: Buscador de información de países

## Objetivos de aprendizaje

- Conexión con APIs y web services
- Manejo de archivos y objetos JSON
- Implementación de caché de información

## Descripción

Se necesita un script para consultar información de países utilizando una API pública. El script permitirá buscar países por nombre y, una vez obtenida la información, se debe guardar en un archivo de caché para evitar futuras consultas a la API. Los detalles relevantes de cada país deben mostrarse por pantalla con el formato mencionado más adelante.

Los resultados guardados en el archivo caché deberán tener un **TTL (time to live)** que indica durante cuánto tiempo es válido ese resultado. Pasado ese tiempo, se deberá consultar nuevamente a la API para actualizar los valores en caché de ese elemento.

## Documentación de la API

La API de REST Countries no requiere registro. La consulta se realiza por nombre de país.

- **URL de la API:**  
  `https://restcountries.com/v3.1/name/{nombre}`

- **Ejemplo de llamada cURL:**  
  ```bash
  curl "https://restcountries.com/v3.1/name/spain"
  ```

## Ejemplo de salida esperada

Por cada país encontrado:

```
País: Spain
Capital: Madrid
Región: Europe
Población: 47615034
Moneda: Euro (EUR)
```

## Consideraciones

1. Los nombres de los países pueden ser múltiples y deben ser de tipo array en PowerShell.
2. El archivo de caché debe persistir las consultas durante un tiempo determinado (TTL).

## Parámetros

| Parámetro bash | Parámetro PowerShell | Descripción                                      |
|:--------------:|:-------------------:|:-------------------------------------------------|
| -n / --nombre  | -nombre             | Nombre/s de los países a buscar.                 |
| -t / --ttl     | -ttl                | Tiempo en segundos que se guardarán los resultados en caché. |