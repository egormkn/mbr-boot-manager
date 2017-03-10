# Some useful hints for beginners

## Arrays
###Declaring array 

:: for more informations see about directives __db__, __dw__, __dd__ ... ::

The format of array: [name]: [directive] \( [value] \)*

For example: `array: db 1, 2, 3, 4, 5` will create `array = [1, 2, 3, 4, 5]` with 1-byte pointer size

__The important note__: to navigate in array use only __\*b\*__ registers!

For example: to get the third value from `array` we need to write this:
```
mov bx, 2
mov ah, [array + bx * 1] ; In AH will be written 3
                         ; Multiple for 1 not necessary because size of pointers is 1 byte
                         ; But if we used not DB, so we would multiple for a size of poniter 
```
