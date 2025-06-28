[ENABLE]
//code from here to '[DISABLE]' will be used to enable the cheat
alloc(newmem,2048)
label(returnhere)
label(originalcode)
label(exit)

newmem: //this is allocated memory, you have read,write,execute access
//place your code here

originalcode:
mov eax,1

exit:
jmp returnhere

"Cube.exe"+A8D49:
jmp newmem
returnhere:


 
 
[DISABLE]
//code from here till the end of the code will be used to disable the cheat
dealloc(newmem)
"Cube.exe"+A8D49:
db A1 68 B1 9D 00
//mov eax,[Cube.exe+36B168]
