setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR/../bash/ejercicio1:$PATH"
}

@test "no se ingresa ningun parametro" {
    # notice the missing ./
    # As we added src/ to $PATH, we can omit the relative path to `src/project.sh`.
    run ejercicio1.sh # notice `run`!
    assert_output "$DIR/../bash/ejercicio1/ejercicio1.sh: no se ingresó la ruta del directorio."
}

@test "se escribe bandera sin parametro" {
    run ejercicio1.sh -d 
    assert_output "$DIR/../bash/ejercicio1/ejercicio1.sh: no se ingresó la ruta del directorio o no se especificó archivo de salida ni pantalla."

    run ejercicio1.sh -a 
    assert_output "$DIR/../bash/ejercicio1/ejercicio1.sh: no se ingresó la ruta del directorio o no se especificó archivo de salida ni pantalla."
}

@test "no se ingresa pantalla ni archivo" {
    run ejercicio1.sh -d "$DIR/../bash/ejercicio1/encuestas"
    assert_output "$DIR/../bash/ejercicio1/ejercicio1.sh: no se especificó archivo de salida ni pantalla."
}

@test "se ingresan pantalla y archivo" {
    run ejercicio1.sh -d "$DIR/../bash/ejercicio1/encuestas" -p -a /tmp/resultado.json
    assert_output "$DIR/../bash/ejercicio1/ejercicio1.sh: argumentos conflictivos."
}

@test "el directorio esta vacio" {
    run ejercicio1.sh -d "$DIR" -p 
    assert_output "Directorio vacio. $DIR"
}

@test "Ejercicio1 genera el JSON esperado" {
  run ejercicio1.sh -d "$DIR/../bash/ejercicio1/encuestas" -p
  [ "$status" -eq 0 ]

  # Validar que el JSON tenga la clave esperada con jq
  echo "$output" | jq -e '.["2025-06-30"].Telefono.tiempo_respuesta_promedio == 7.925' > /dev/null
  [ "$?" -eq 0 ]

  echo "$output" | jq -e '.["2025-07-03"].Email.nota_satisfaccion_promedio == 4.5' > /dev/null
  [ "$?" -eq 0 ]
}

