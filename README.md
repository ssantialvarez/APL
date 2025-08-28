# Actividad Práctica de Laboratorio: Bash y Powershell 

## Condiciones de entrega
+ Se debe entregar por plataforma MIEL un archivo con formato ZIP o TAR (no se aceptan RAR u otros formatos de compresión empaquetamiento de archivos), conteniendo la carátula que se publica en MIEL junto con los archivos de la resolución del trabajo. 
+ Se debe entregar el código fuente de cada uno de los ejercicios resueltos tanto en Bash como en Powershell. Si un ejercicio se resuelve en un único lenguaje se lo considerará incompleto y, por lo tanto, desaprobado. 
+ Se deben entregar lotes de prueba válidos para los ejercicios que reciban archivos o directorios como parámetro. 
+ Los archivos de código deben tener un encabezado en el que se listen los integrantes del grupo.

## Criterios de corrección y evaluación generales para todos los ejercicios 
+ Los scripts de bash muestran una ayuda con los parámetros “-h” y “--help”.  Deben permitir el ingreso de parámetros en cualquier orden, y no por un orden fijo.  
+ Los scripts de Powershell deben mostrar una ayuda con el comando Get-Help. Ej: “Get-Help ./ejercicio1.ps1”. Deben realizar la validación de parámetros en la sección params utilizando la funcionalidad nativa de Powershell. 
+ Cuando haya parámetros que reciban rutas de directorios o archivos se deben aceptar tanto rutas relativas como absolutas o que contengan espacios. 
+ No se debe permitir la ejecución del script si al menos un parámetro obligatorio no está presente. 
+ Si algún comando utilizado en el script da error, este se debe manejar correctamente: detener la ejecución del script (o salvar el error en caso de ser posible) y mostrar un mensaje informando el problema de una manera amigable con el usuario, pensando que el usuario no tiene conocimientos informáticos. 
+ Si se generan archivos temporales de trabajo se deben crear en el directorio temporal /tmp; y se deben eliminar al finalizar el script, tanto en forma exitosa como por error, para no dejar archivos basura. (Ver trap en bash / try-catch-finally en powershell) 
+ Deseable: 
    - Utilización de funciones en el código para resolver los ejercicios. 
