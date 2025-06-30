[ENABLE]
//code from here to '[DISABLE]' will be used to enable the cheat
alloc(newmem,2048)
label(returnhere)
label(originalcode)
label(exit)

newmem: //this is allocated memory, you have read,write,execute access
//place your code here

originalcode:
nop // dec [ecx]
cmp dword ptr [ecx],00

exit:
jmp returnhere

"Cube.exe"+2F140:
jmp newmem
returnhere:


 
 
[DISABLE]
//code from here till the end of the code will be used to disable the cheat
dealloc(newmem)
"Cube.exe"+2F140:
db FF 09 83 39 00
//dec [ecx]
//cmp dword ptr [ecx],00
