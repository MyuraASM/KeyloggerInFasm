format PE console
entry start

include 'win32a.inc'

section '.data' data readable writeable
    logger_path db 'logger.exe', 0
    sender_path db 'sender.exe', 0
    startupinfo db 68 dup(0)
    processinfo1 db 16 dup(0)
    processinfo2 db 16 dup(0)

section '.code' code readable executable
start:

    mov dword [startupinfo], 68
    mov dword [startupinfo+32], STARTF_USESTDHANDLES

    invoke CreateProcess, logger_path, 0, 0, 0, FALSE, 0, 0, 0, startupinfo, processinfo1
    test eax, eax
    jz error

    invoke CreateProcess, sender_path, 0, 0, 0, FALSE, 0, 0, 0, startupinfo, processinfo2
    test eax, eax
    jz error

    invoke ExitProcess, 0

error:

    invoke ExitProcess, 1

section '.idata' import data readable
    library kernel32, 'kernel32.dll'
    import kernel32,\
           CreateProcess, 'CreateProcessA',\
           ExitProcess, 'ExitProcess'
