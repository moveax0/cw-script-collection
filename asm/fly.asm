[ENABLE]
alloc(newmem,2048)
label(returnhere)

newmem:
  mov eax,0x10
  jmp returnhere

"Cube.exe"+A8D49:
  jmp newmem
returnhere:

[DISABLE]

dealloc(newmem)

"Cube.exe"+A8D49:
  db A1 68 B1 9D 00
//mov eax,[Cube.exe+36B168]
