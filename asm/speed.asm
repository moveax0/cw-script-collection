[ENABLE]

alloc(newmemAdd, 2048)
alloc(newmemSub, 2048)

// ================================================
// Hook 1: Speed "Pull" - gravity
// ================================================

label(returnhereAdd)
label(originalAdd)
label(mulAdd)

newmemAdd:
  push edi
  push ebx

// resolve pointer to local player base address
  mov edi, ["Cube.exe"+36B1C8]
  test edi, edi
  je originalAdd
  mov edi, [edi+39C]
  test edi, edi
  je originalAdd

// apply x-coord offset to local player base address
  mov ebx, edi
  add ebx, 10
  cmp ecx, ebx
  je mulAdd

// apply y-coord offset to local player base address
  mov ebx, edi
  add ebx, 18
  cmp ecx, ebx
  je mulAdd

// apply z-coord offset to local player base address
  mov ebx, edi
  add ebx, 20
  cmp ecx, ebx
  je mulAdd

originalAdd:
  pop ebx
  pop edi
  add [ecx], eax
  mov eax, [edx+04]
  jmp returnhereAdd

mulAdd:
  imul eax, eax, 4 // multiply speed by x (imul eax, eax, x)
  jmp originalAdd

// install first hook
"Cube.exe"+2C9B8:
  jmp newmemAdd
returnhereAdd:

// ================================================
// Hook 2: Speed "Push" - normal force
// ================================================

label(returnhereSub)
label(originalSub)
label(mulSub)

newmemSub:
  push edi
  push ebx

// resolve pointer to local player base address
  mov edi, ["Cube.exe"+36B1C8]
  test edi, edi
  je originalSub
  mov edi, [edi+39C]
  test edi, edi
  je originalSub

// apply x-coord offset to local player base address
  mov ebx, edi
  add ebx, 10
  cmp ecx, ebx
  je mulSub

// apply y-coord offset to local player base address
  mov ebx, edi
  add ebx, 18
  cmp ecx, ebx
  je mulSub

// apply z-coord offset to local player base address
  mov ebx, edi
  add ebx, 20
  cmp ecx, ebx
  je mulSub

originalSub:
  pop ebx
  pop edi
  sub [ecx], eax
  mov eax, [edx+04]
  jmp returnhereSub

mulSub:
  imul eax, eax, 4 // multiply speed by x (imul eax, eax, x)
  jmp originalSub

// install second hook
"Cube.exe"+2CA08:
  jmp newmemSub
returnhereSub:
 
[DISABLE]

// clean up hooks
dealloc(newmemAdd)
dealloc(newmemSub)

// restore original code for first hook
"Cube.exe"+2C9B8:
  db 01 01 8B 42 04
//add [ecx],eax
//mov eax,[edx+04]

// restore original code for second hook
"Cube.exe"+2CA08:
  db 29 01 8B 42 04
//sub [ecx],eax
//mov eax,[edx+04]
