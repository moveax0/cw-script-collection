[ENABLE]
alloc(newmem,2048)
label(returnhere)

newmem:
  cmp dword ptr [ecx],00
  jmp returnhere

"Cube.exe"+2F140:
  jmp newmem
returnhere:

[DISABLE]

dealloc(newmem)

"Cube.exe"+2F140:
  db FF 09 83 39 00
//dec [ecx]
//cmp dword ptr [ecx],00
