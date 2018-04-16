function(addPrefixes listVar prefix out)
  set(ret)
  foreach(i ${listVar})
    list(APPEND ret ${prefix}${i})
  endforeach()
  set(${out} ${ret} PARENT_SCOPE)
endfunction()

function(get_libraries out target)
  get_target_property(libs ${TARGET} LINK_LIBRARIES)
  #DBG(libs)
  set(ret)
  foreach(lib ${libs})
    if(TARGET ${lib})
      get_target_property(path ${lib} LOCATION)
      #message("${lib}: ${path}")
      list(APPEND ret " ${path}")
    else()
      list(APPEND ret " -l${lib}")
    endif()
  endforeach()
  set(${out} ${ret} PARENT_SCOPE)
endfunction()

function(addSuffixes listVar suffix out)
  set(ret)
  foreach(i ${listVar})
    list(APPEND ret ${i}${suffix})
  endforeach()
  set(${out} ${ret} PARENT_SCOPE)
endfunction()

function(toFastbuildArray listVar out)
  list(GET listVar 0 elem)
  set(ret "{\"${elem}\"")
  list(LENGTH listVar size)
  DBG(size)
  math(EXPR size "${size}-1")
  if(${size} GREATER 0)
    foreach(i RANGE 1 ${size})
      LIST(GET listVar ${i} elem)
      message(${elem})
      set(ret "${ret}, \"${elem}\"")
    endforeach()
  endif()
  set(ret "${ret}}")
  set(${out} ${ret} PARENT_SCOPE)
endfunction()

function(DBG VAR)
  message("${VAR}: ${${VAR}}")
endfunction()

function(find_lib out name direcories)
  foreach(i ${direcories})
    FILE(GLOB ret "${i}/${name}*.lib")
    #DBG(ret)
    if(ret)
      break()
    endif()
    FILE(GLOB ret "${i}/lib${name}*.a")
    #DBG(ret)
    if(ret)
      break()
    endif()
  endforeach()
  set(${out} ${ret} PARENT_SCOPE)
endfunction()

function(get_dlls target)
  get_target_property(libs ${TARGET} LINK_LIBRARIES)
  foreach(lib ${libs})
   if(TARGET ${lib})
     # If this is a library, get its transitive dependencies
     get_target_property(trans ${lib} INTERFACE_LINK_LIBRARIES)
     foreach(tran ${trans})
       if(TARGET ${tran})
         get_target_property(path ${tran} LOCATION)
         file(APPEND "$libs.txt" "${path}\n")
       endif()
     endforeach()
     get_target_property(path ${lib} LOCATION)
     file(APPEND "libs.txt" "${path}\n")
    else()
     file(APPEND "libs.txt" "${lib}\n")
    endif()
  endforeach()
endfunction()

function(add_fastbuild_target TARGET)
  get_target_property(TYPE ${TARGET} TYPE)
  DBG(TYPE)
  get_target_property(COMPILE_OPTIONS ${TARGET} COMPILE_OPTIONS)
  DBG(COMPILE_OPTIONS)
  get_target_property(INCLUDE_DIRECTORIES  ${TARGET} INCLUDE_DIRECTORIES)
  #DBG(INCLUDE_DIRECTORIES)
  get_target_property(LINK_FLAGS  ${TARGET} LINK_FLAGS)
  DBG(LINK_FLAGS)
  get_target_property(OUTPUT_NAME   ${TARGET} OUTPUT_NAME )
  DBG(OUTPUT_NAME)
  get_target_property(LIBRARY_OUTPUT_DIRECTORY ${TARGET} LIBRARY_OUTPUT_DIRECTORY )
  DBG(LIBRARY_OUTPUT_DIRECTORY)
  get_target_property(NAME ${TARGET} NAME )
  DBG(NAME)
  DBG(CMAKE_LINKER)
  
  #set(IncludeDirs ${OpenCV_INCLUDE_DIRS})
  #list(APPEND IncludeDirs "./include/")
  addPrefixes("${INCLUDE_DIRECTORIES}" " -I" INCLUDE_DIRECTORIES)
  string(REPLACE ";" " " INCLUDE_DIRECTORIES "${INCLUDE_DIRECTORIES}")
  get_libraries(IncludeLibs target)
  #DBG(IncludeLibs)
  #DBG(IncludeLibs)
  #addPrefixes("${IncludeLibs}" " " IncludeLibs)
  #addSuffixes("${IncludeLibs}" "341" IncludeLibs)
  string(REPLACE ";" " " IncludeLibs "${IncludeLibs}")
  #set(libsPath " -L${OpenCV_INSTALL_PATH}/lib")
  toFastbuildArray("${SRC}" fba)
  


  file(APPEND fbuild.bff
"
ObjectList( '${NAME}-Lib' ) {
  .CompilerInputFiles = ${fba}
  .CompilerOutputPath = '/out/' 
  .CompilerOptions = '%1' 
  + ' -c' 
  + ' -o \"%2\" '
  + '${INCLUDE_DIRECTORIES}'
} 
Executable( '${NAME}' ) { 
  .Libraries = { '${NAME}-Lib' } 
  .LinkerOutput = '/out/${NAME}.exe'
  .LinkerOptions = '%1' 
  + ' -o \"%2\"' 
  + '${INCLUDE_DIRECTORIES}'
  + '${IncludeLibs}'
}
"
)

endfunction()

function(init_fastbuild)
  file(WRITE fbuild.bff
".Compiler = '${CMAKE_CXX_COMPILER}'
.Linker = '${CMAKE_CXX_COMPILER}'
"
  )
endfunction()

function(alias_all_fastbuild TARGETS)
  DBG(TARGETS)
  set(ret)
  foreach(i ${TARGETS})
    get_target_property(NAME ${i} NAME )
    list(APPEND ret ${NAME})
  endforeach()
  DBG(ret)
  toFastbuildArray("${ret}" ret)
  file(APPEND fbuild.bff
"Alias( 'all' ) { 
  .Targets = ${ret}
}
"
  )
endfunction()

function(generate_fastbuild TARGETS)
  init_fastbuild()
  foreach(i ${TARGETS})
    add_fastbuild_target(${i})
  endforeach()
  alias_all_fastbuild("${TARGETS}")
endfunction()